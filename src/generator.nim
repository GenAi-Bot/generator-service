import random, sequtils, strutils, tables, sets
from unicode import runes, toLower, toUTF8

randomize()

type
  MarkovModel = Table[seq[string], HashSet[string]]

const
  mrkvStartToken = "__start"
  mrkvEndToken = "__end"

proc processSamples(samples: seq[string]): seq[string] =
  for sample in samples:
    let words = sample.splitWhitespace()
    var subResult = newSeq[string]()

    for word in words:
      if word.len == 0 or word == mrkvStartToken or word == mrkvEndToken: continue

      if word.startsWith("http"): # nested if statement just to not check for http: AND https: EVERY word, sorry for nested if !!
        subResult.add(if word.startsWith("http:") or word.startsWith("https:"): word
          else: word.toLower())
      else:
        subResult.add(word.toLower())

    if subResult.len != 0: result.add(subResult.join(" "))

proc buildModel(samples: seq[string], keySize: int): MarkovModel =
  var processedSamples = samples.processSamples()

  for sample in processedSamples:
    var words = @[ mrkvStartToken ] & sample.splitWhitespace() & @[ mrkvEndToken ]
    for i in 0 ..< words.len - keySize:
      result.mgetOrPut(words[i ..< i + keySize])
        .incl(words[i + keySize])
    words.setLen(0)
  
  processedSamples.setLen(0)

proc generateText(model: MarkovModel, keySize: int, maxLength: int, begin = ""): string =
  var
    currentKey: seq[string]
    currentLength = 0

  if begin.len > 0:
    let startWords = begin.splitWhitespace()
    if startWords.len < keySize:
      currentKey = @[ mrkvStartToken ].cycle(keySize - startWords.len) & startWords
    else:
      currentKey = startWords[startWords.len - keySize ..< startWords.len]
    result = begin
    currentLength = begin.len
  else:
    var startKeys = model.keys.toSeq().filterIt(it[0] == mrkvStartToken)
    if startKeys.len == 0:
      raise newException(ValueError, "Model is empty")
    currentKey = startKeys.sample()
    startKeys.setLen(0)
    result = currentKey[1 ..< keySize].join(" ")
    currentLength = result.len

  while currentLength < maxLength:
    if currentKey notin model: raise newException(CatchableError, "Key not found in model: " & $currentKey)

    let nextWord = model[currentKey].items.toSeq().sample()
    if nextWord == mrkvEndToken: break

    let newLength = currentLength + nextWord.len + (if result.len > 0: 1 else: 0)
    if newLength > maxLength: break

    if result.len > 0: result.add(" ")
    result.add(nextWord)

    currentKey = currentKey[1 ..< keySize] & @[ nextWord ]
    currentLength = newLength

proc generate*(rawSamples: seq[string]; keySize: Positive; maxLength = 500;
    attempts = 500; begin = ""; count = 1): seq[string] =
  
  var model = buildModel(rawSamples, keySize)
  defer: model.clear()

  proc generateAttempts(): string =
    for i in 0 ..< attempts:
      let res = model.generateText(keySize = keySize, maxLength = maxLength, begin = begin)
      if res.len == 0: continue
      return res
    raise newException(CatchableError, "Out of attempts")

  try:
    for i in 0..<count:
      result.add generateAttempts()
  except CatchableError as e:
    result.setLen(0)
    raise e
