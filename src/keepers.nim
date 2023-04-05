import asyncfile, os, asyncdispatch, system/io, strutils, re

type
  BaseKeeper = ref object of RootObj
  LocalKeeper = ref object of BaseKeeper
    messagesPath: string

iterator lines(str: string): string =
  var i = 0
  while i < str.len:
    var j = i
    while j < str.len and str[j] != '\n':
      inc(j)
    yield str[i ..< j]
    i = j + 1

proc removeURIs(str: string): string = str.replace(re"""(https?:\/\/[^\s/$.?#].[^\s]*)""")

proc newLocalKeeper*(messagesPath: string): LocalKeeper =
  result = LocalKeeper(messagesPath: messagesPath)

proc getChannelPath(keeper: LocalKeeper, channel: string): string =
  result = keeper.messagesPath / channel & ".txt"

proc channelExists(keeper: LocalKeeper, channel: string): bool =
  result = fileExists(keeper.getChannelPath(channel))

proc getMessages*(keeper: LocalKeeper, channel: string, cleanURIs = false): Future[seq[string]] {.async.} =
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
