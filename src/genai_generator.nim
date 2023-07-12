import asynchttpserver, asyncdispatch, strutils, tables, json, os
import redis
import keepers, middlewares, helpers, generator

proc main {.async.} =
  var server = newAsyncHttpServer()
  server.listen(Port(3000))

  let
    maxLines = parseInt(getEnv("MAX_LINES", "-1"))
    keeper = if existsEnv("KEEPER_URL"): Keeper(kind: kkRemote, url: getEnv(
        "KEEPER_URL"), maxLines: maxLines)
      else: Keeper(kind: kkLocal, messagesPath: getEnv("KEEPER_PATH",
          "/data/messages"), maxLines: maxLines)
    redisClient = await redis.openAsync(
      getEnv("REDIS_HOST", "localhost"),
      Port(parseInt(getEnv("REDIS_PORT", "6379")))
    )
    middlewareSeq = [
      acceptRootGet,
      checkChannelIDQuery,
      ratelimit
    ]

  proc cb(req: Request) {.async gcsafe.} =
    # middlewares
    var process = true
    let mwEntity = MiddlewareEntity(req: req, redis: redisClient)
    for mw in middlewareSeq:
      try:
        discard await mw(mwEntity)
      except MiddlewareExitError as e:
        process = false
        let
          msg = e.msg.split("\n")[0].split(":")
          code = parseInt(msg[0])
          message = msg[1]
        await req.respond(HttpCode(code), message)
        break

    if not process: return

    # actual request, generating string
    let
      query = req.url.query.queryParamsToTable
      channelId = query["channel_id"]
      maxSymbols = if query.hasKey("max_symbols"): parseInt(query[
          "max_symbols"], 1500, 1, 2000) else: 1500
      filterLinks = if query.hasKey("filter_links"): query["filter_links"] ==
          "true" else: false
      count = if query.hasKey("count"): parseInt(query["count"], 1, 1, 5) else: 1
      begin = if query.hasKey("begin"): query["begin"] else: ""
    var lines = await keeper.getMessages(channelId, filterLinks)
    if lines.len == 0:
      await req.respond(Http404, "No messages found")
    else:
      try:
        await req.respond(
          Http200,
          $(%(generate(lines, 1, maxSymbols, 5, begin, count))),
          newHttpHeaders({"Content-type": "application/json; charset=utf-8"})
        )
      except CatchableError:
        await req.respond(Http500, "Failed to generate string(s)")
      lines.setLen(0)

  while true:
    if server.shouldAcceptRequest():
      await server.acceptRequest(cb)
    else:
      await sleepAsync(500)

waitFor main()
