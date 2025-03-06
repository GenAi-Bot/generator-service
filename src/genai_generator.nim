import asynchttpserver, asyncdispatch, strutils, tables, json, os
import redis
import keepers, middlewares, helpers, generator

proc main {.async.} =
  var
    server = newAsyncHttpServer()
    redisClient: AsyncRedis
    port = parseInt(getEnv("PORT", "3000"))
  echo "Listening for port ", port
  server.listen(Port(port))

  let
    maxLines = parseInt(getEnv("MAX_LINES", "-1"))
    keeper = if existsEnv("KEEPER_URL"): Keeper(kind: kkRemote, url: getEnv(
        "KEEPER_URL"), maxLines: maxLines)
      else: Keeper(kind: kkLocal, messagesPath: getEnv("KEEPER_PATH",
          "/data/messages"), maxLines: maxLines)
    middlewareSeq = @[
      acceptRootGet,
      checkChannelIDQuery,
      ratelimit
    ]
    maxAttempts = parseInt(getEnv("MAX_ATTEMPTS", "5"))

  if existsEnv("REDIS_HOST"):
    echo "Found REDIS_HOST, connecting to redis.."
    redisClient = await redis.openAsync(
      getEnv("REDIS_HOST", "localhost"),
      Port(parseInt(getEnv("REDIS_PORT", "6379")))
    )

  proc cb(req: Request) {.async gcsafe.} =
    # middlewares
    var process = true
    let mwEntity = MiddlewareEntity(req: req, redis: redisClient)

    for mw in middlewareSeq:
      try:
        await mw(mwEntity)
      except MiddlewareExitError as e:
        process = false
        await req.respond(e.code, e.msg.split('\n')[0]) # in debug mode `msg` includes async traceback, which is not really needed in response
        break
      except Exception as e:
        process = false
        await req.respond(Http500, "Internal server error")
        echo e.trace
        break

    if not process: return

    # actual request, generating string
    let
      query = req.url.query.queryParamsToTable
      channelId = query["channel_id"]
      maxSymbols = parseInt(str = query.getOrDefault("max_symbols"),
        default = 1500, min = 1, max = 2000)
      filterLinks = if query.hasKey("filter_links"): query["filter_links"] ==
          "true" else: false
      count = parseInt(str = query.getOrDefault("count"), default = 1, min = 1, max = 5)
      begin = query.getOrDefault("begin")

    var lines = await keeper.getMessages(channelId, filterLinks)
    if lines.len == 0:
      await req.respond(Http404, "No messages found")
      return

    try:
      await req.respond(
        Http200,
        $(
          %(
            lines.generate(maxLength = maxSymbols, attempts = maxAttempts, begin = begin, count = count)
          )
        ),
        newHttpHeaders({ "Content-type": "application/json; charset=utf-8" })
      )
    except CatchableError as e:
      if e.msg.startsWith("Key not found in model:"):
        await req.respond(Http500, "Not enough samples to use provided \"begin\"")
      else: await req.respond(Http500, "Failed to generate")
    finally:
      lines.setLen(0)

  while true:
    if server.shouldAcceptRequest():
      await server.acceptRequest(cb)
    else:
      await sleepAsync(500)

waitFor main()
