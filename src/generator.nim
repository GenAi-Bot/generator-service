import random, sequtils, strutils, tables
from unicode import runes, toLower, toUTF8

randomize()

const
  mrkvStart = "__start"
  mrkvEnd = "__end"

proc unicodeStringToLower*(str: string): string =
  result = ""
  for s in runes(str):
    result.add(s.toLower.toUTF8)

proc generate*(rawSamples: seq[string]; keySize: Positive, maxLength = 500, attempts = 500, begin = "", count = 1): seq[string] =
  let
    samples = rawSamples.mapIt((mrkvStart & " " & it & " " & mrkvEnd).unicodeStringToLower())
    words = samples.join(" ").split(" ")

  var dict: Table[string, seq[string]]

  for i in 0..(words.len - keySize):
    let prefix = words[i..<(i+keySize)].join(" ")
    let suffix = if i + keySize < words.len: words[i + keySize] else: ""
    dict.mgetOrPut(prefix, @[]).add suffix

  proc generateLocal(): string =
    var
      output: seq[string]
      prefix = if begin.len > 0: begin else: toSeq(dict.keys).sample()

    if not dict.hasKey(prefix):
      raise newException(CatchableError, "Prefix not found: " & prefix)

    output.add prefix.split(' ')

    for n in 1..words.len:
      let nextWord = dict[prefix].sample()
      if nextWord.len == 0 or nextWord == mrkvEnd: break
      output.add nextWord
      prefix = output[n..<(n + keySize)].join(" ")

    return output.join(" ")

  proc generateAttempts(): string =
    for i in 0..<attempts:
      let res = generateLocal()
      if res.len > maxLength: continue
      return res
    raise newException(CatchableError, "Failed to generate text")

  for i in 0..<count:
    result.add generateAttempts()