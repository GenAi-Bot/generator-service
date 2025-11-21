import random, sequtils, strutils, tables
from unicode import runes, toLower, toUTF8

randomize()

type
  MarkovModel = Table[seq[string], seq[string]]
  InvalidStartError* = object of CatchableError
  OutOfAttemptsError* = object of CatchableError

const
  mrkvStartToken = "__start"
  mrkvEndToken = "__end"
  keepCasePrefixes = ["http:", "https:", "<a:", "<:"]

proc wordProcess(word: string): string =
  if keepCasePrefixes.anyIt(word.startsWith(it)):
    return word
  
  return word.toLower()

iterator processSamples(samples: seq[string]): seq[string] =
  for sample in samples:
    var subResult = newSeq[string]()

    for word in sample.splitWhitespace:
      if word.len == 0: continue
      subResult.add(wordProcess(word))

    if subResult.len != 0: yield subResult

proc buildModel(samples: sink seq[string], keySize: int): MarkovModel =  
  for sampleSeq in samples.processSamples():
    let
      startContext = newSeqWith(keySize, mrkvStartToken)
      stream = startContext & sampleSeq & @[mrkvEndToken]

    for i in 0 ..< stream.high - keySize + 1:
      result.mgetOrPut(stream[i ..< i + keySize], @[]).add(stream[i + keySize])

proc generateText(model: MarkovModel, maxLength: int, keySize: int, begin = ""): string =
  var currentKey: seq[string]

  if begin.len > 0:
    let startWords = begin.splitWhitespace()
    result = begin

    if startWords.len >= keySize:
      let rawKey = startWords[^keySize .. ^1]
      currentKey = rawKey.mapIt(wordProcess(it))
    else:
      let
        missing = keySize - startWords.len
        rawKey = newSeqWith(missing, mrkvStartToken) & startWords
      currentKey = rawKey.mapIt(wordProcess(it))

    if not model.hasKey(currentKey):
      raise newException(InvalidStartError, "Invalid key for begin: " & $currentKey)
  else:
    currentKey = newSeqWith(keySize, mrkvStartToken)

  while true:
    if currentKey notin model: break

    let possibilities = model[currentKey]
    if possibilities.len == 0: break
    
    let nextWord = possibilities.sample()
    if nextWord == mrkvEndToken: break

    let extraLen = (if result.len == 0: nextWord.len else: nextWord.len + 1)
    if result.len + extraLen > maxLength: break

    if result.len == 0:
      result = nextWord
    else:
      result.add(" " & nextWord)

    currentKey.delete(0)
    currentKey.add(nextWord)

proc generate*(rawSamples: sink seq[string]; maxLength = 500; 
    keySize: Positive = 1; attempts = 500; begin = ""; count = 1): seq[string] =
  let model = buildModel(rawSamples.move, keySize)

  proc generateAttempt(): string =
    for i in 0 ..< attempts:
      let res = model.generateText(maxLength, keySize, begin)
      if res.len > begin.len: 
        return res
    raise newException(OutOfAttemptsError, "Out of attempts")

  for i in 0 ..< count:
    let gen = generateAttempt()
    if gen.len > 0: result.add gen
