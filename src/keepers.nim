import asyncfile, os, asyncdispatch, strutils, re, httpclient, jsony

type
  KeeperKind* = enum
    kkLocal,
    kkRemote
  Keeper* = ref object of RootObj
    maxLines*: int
    case kind*: KeeperKind
    of kkLocal: messagesPath*: string
    of kkRemote: url*: string

iterator ascendingLines(str: string): string =
  var i = str.len - 1
  while i >= 0:
    var j = i
    while j >= 0 and str[j] != '\n':
      dec(j)
    yield str[j + 1 ..< i + 1]
    i = j - 1

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
    # not used in actual GenAi project, read disclaimer here below (placed before lines iterator)
    if not keeper.channelExists(channel):
      return @[]

    let path = keeper.getChannelPath(channel)
    var file = openAsync(path, fmRead)
    defer: file.close()
    
    let
      fileSize = file.getFileSize()
      maxRead: int64 = if keeper.maxLines == -1: fileSize else: keeper.maxLines * 4_000
      startPos: int64 = if maxRead >= fileSize: 0 else: fileSize - maxRead
      uriRe = re"""(https?:\/\/[^\s/$.?#].[^\s]*)"""

    if maxRead == 0: return @[]

    file.setFilePos(startPos)

    # this is an abstract way to read messages from local files, if using in own project
    # make sure to store encrypted messages and implement your decryption here
    let content = await file.read(maxRead.int)
    for line in ascendingLines(content):
      if cleanURIs:
        let str = line.replace(uriRe)
        if str.len > 0:
          result.add(str.strip())
      else:
        result.add(line)

      if result.len == keeper.maxLines: break
  of kkRemote:
    let client = newAsyncHttpClient()
    defer: client.close()
    result = (
      await client.getContent(
        keeper.url
          .replace("{channel_id}", channel)
          .replace("{max_lines}", $keeper.maxLines)
          .replace("{clean_uri}", $cleanURIs)
      )
    ).fromJson(seq[string])
