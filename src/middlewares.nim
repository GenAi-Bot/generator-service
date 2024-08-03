import asyncdispatch, asynchttpserver, uri, tables, strutils, times
import helpers
import redis

type
  MiddlewareEntity* = ref object
    req*: Request
    redis*: AsyncRedis
  MiddlewareExitError* = ref object of CatchableError
    code*: HttpCode

proc newMiddlewareExitError(code: HttpCode, msg: string): MiddlewareExitError =
  new(result)
  result.code = code
  result.msg = msg

const
  mwMaxRequests = 5
  mwMaxTime = 15

proc acceptRootGet*(e: MiddlewareEntity) {.async.} =
  if e.req.url.path != "/" and e.req.reqMethod != HttpGet:
    raise newMiddlewareExitError(Http404, "Not found")

proc checkChannelIDQuery*(e: MiddlewareEntity) {.async.} =
  let reqQuery = e.req.url.query.queryParamsToTable
  if "channel_id" notin reqQuery:
    raise newMiddlewareExitError(Http400, "Missing channel_id")

proc ratelimit*(e: MiddlewareEntity) {.async.} =
  if e.redis == nil: return

  let
    reqQuery = e.req.url.query.queryParamsToTable
    key = "rate-limit:" & reqQuery["channel_id"]
    lastReq = await e.redis.get(key)

  if lastReq != redisNil:
    let
      val = lastReq.split(":")
      count = parseInt(val[0])
      time = parseInt(val[1])

    if count >= mwMaxRequests and epochTime().int - time < mwMaxTime:
      raise newMiddlewareExitError(Http429, "Too many requests")
    elif epochTime().int - time >= mwMaxTime:
      await e.redis.setk(key, "1:" & $epochTime().int)
    else:
      await e.redis.setk(key, $(count + 1) & ":" & $epochTime().int)
  else:
    await e.redis.setk(key, "1:" & $epochTime().int)
