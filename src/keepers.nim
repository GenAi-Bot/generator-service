import asyncfile, os, asyncdispatch, system/io, strutils, re, httpclient, jsony

type
  KeeperKind* = enum
    kkLocal,
    kkRemote
  Keeper* = ref object of RootObj
    maxLines*: int
    case kind*: KeeperKind
    of kkLocal: messagesPath*: string
    of kkRemote: url*: string

iterator lines(str: string): string =
  var i = str.len - 1
  while i >= 0:
    var j = i
    while j >= 0 and str[j] != '\n':
      dec(j)
    yield str[j + 1 ..< i + 1]
    i = j - 1

proc removeURIs(str: string): string = str.replace(re"""(https?:\/\/[^\s/$.?#].[^\s]*)""")

proc getChannelPath(keeper: Keeper, channel: string): string =
  if keeper.kind == kkLocal:
    result = keeper.messagesPath / channel & ".txt"
  else: raise newException(Defect, "getChannelPath can be used only with local keeper")

proc channelExists(keeper: Keeper, channel: string): bool =
  if keeper.kind == kkLocal:
    result = fileExists(keeper.getChannelPath(channel))
  else: raise newException(Defect, "channelExists can be used only with local keeper")

proc getMessages*(keeper: Keeper, channel: string, cleanURIs = false): Future[
    seq[string]] {.async.} =
  case keeper.kind:
  of kkLocal:
    if not keeper.channelExists(channel):
      return @[]

    let path = keeper.getChannelPath(channel)
    var file = openAsync(path, fmRead)
    defer: file.close()
    let content = await file.readAll()
    for line in lines(content):
      if cleanURIs:
        let str = removeURIs(line).strip
        if str.len > 0:
          result.add(str)
      else:
        result.add(line)

      if result.len == keeper.maxLines: break
  of kkRemote:
    var client = newAsyncHttpClient()
    result = (
      await client.getContent(
        keeper.url
          .replace("{channel_id}", channel)
          .replace("{max_lines}", $keeper.maxLines)
          .replace("{clean_uri}", $cleanURIs)
      )
    ).fromJson(seq[string])
