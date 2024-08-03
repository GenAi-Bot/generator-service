import tables, sequtils, uri, strutils

proc queryParamsToTable*(query: string): Table[string, string] = toTable(toSeq(
    decodeQuery(query)))

proc parseInt*(str: string, default: int = 0, min: int, max: int): int =
  try:
    let i = parseInt(str)
    if i < min: return default
    return i
  except CatchableError:
    return default
