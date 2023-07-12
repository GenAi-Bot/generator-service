import asyncdispatch, asynchttpserver, uri, tables, strutils, times
import helpers
import redis

type
  MiddlewareEntity* = object
    req*: Request
    redis*: AsyncRedis
  MiddlewareExitError* = object of CatchableError

const
  mwMaxRequests = 5
  mwMaxTime = 15

proc acceptRootGet*(e: MiddlewareEntity): Future[Request] {.async.} =
  if e.req.url.path != "/" and e.req.reqMethod != HttpGet:
    raise newException(MiddlewareExitError, "404:Not found")
  return e.req

proc checkChannelIDQuery*(e: MiddlewareEntity): Future[Request] {.async.} =
  let reqQuery = e.req.url.query.queryParamsToTable
  if "channel_id" notin reqQuery:
    raise newException(MiddlewareExitError, "401:Missing channel_id")
  return e.req

proc ratelimit*(e: MiddlewareEntity): Future[Request] {.async.} =
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
      raise newException(MiddlewareExitError, "429:Too many requests")
    elif epochTime().int - time >= mwMaxTime:
      await e.redis.setk(key, "1:" & $epochTime().int)
    else:
      await e.redis.setk(key, $(count + 1) & ":" & $epochTime().int)
  else:
    await e.redis.setk(key, "1:" & $epochTime().int)

  return e.req
