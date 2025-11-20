import random, sequtils, strutils, tables, sets
from unicode import runes, toLower, toUTF8

randomize()

type
  MarkovModel = Table[string, HashSet[string]]
  InvalidStartError* = object of CatchableError
  OutOfAttemptsError* = object of CatchableError

const
  mrkvStartToken = "__start"
  mrkvEndToken = "__end"

proc wordProcess(word: string): string =
  if word.startsWith("http"): # nested if statement just to not check for http: AND https: EVERY word, sorry for nested if !!
    result = if word.startsWith("http:") or word.startsWith("https:"): word
      else: word.toLower()
  elif word.startsWith("<a:") or word.startsWith("<:"):
    result = word
  else:
    result = word.toLower()

iterator processSamples(samples: seq[string]): string =
  for sample in samples:
    let words = sample.splitWhitespace()
    var subResult = newSeq[string]()

    for word in words:
      if word.len == 0 or word == mrkvStartToken or word == mrkvEndToken: continue
      subResult.add(wordProcess(word))

    if subResult.len != 0: yield subResult.join(" ")

proc buildModel(samples: seq[string]): MarkovModel =
  for sample in samples.processSamples():
    var words = @[ mrkvStartToken ] & sample.splitWhitespace() & @[ mrkvEndToken ]
    for i in 0 ..< words.high:
      result.mgetOrPut(words[i])
        .incl(words[i + 1])
    words.setLen(0)

proc generateText(model: MarkovModel, maxLength: int, begin = ""): string =
  var
    currentKey = mrkvStartToken

  if begin.len > 0:
    let startWords = begin.splitWhitespace()
    currentKey = startWords[^1]
    result = begin
  else:
    if not model.hasKey(mrkvStartToken): raise newException(ValueError, "Model is empty")

  while result.len < maxLength:
    if currentKey notin model: raise newException(InvalidStartError, "Key not found in model: " & $currentKey)

    let nextWord = model[currentKey].toSeq().sample()
    if nextWord == mrkvEndToken: break

    let newLength = result.len + nextWord.len + (if result.len > 0: 1 else: 0)
    if newLength > maxLength: break

    if result.len > 0: result.add(" ")
    result.add(nextWord)

    currentKey = nextWord

proc generate*(rawSamples: seq[string]; maxLength = 500;  
    attempts = 500; begin = ""; count = 1): seq[string] =

  var model = buildModel(rawSamples)
  defer: model.clear()

  proc generateAttempts(): string =
    for i in 0 ..< attempts:
      let res = model.generateText(maxLength = maxLength, begin = begin)
      if res.len == 0: continue
      return res
    raise newException(OutOfAttemptsError, "Out of attempts")

  try:
    for i in 0 ..< count:
      result.add generateAttempts()
  except CatchableError as e:
    raise e
