import tables, uri, strutils

proc queryParamsToTable*(query: string): Table[string, string] =
  result = initTable[string, string]()
  for key, value in decodeQuery(query):
    result[key] = value

proc parseInt*(str: string, default: int = 0, min: int, max: int): int =
  try:
    let i = parseInt(str)
    if i < min: return default
    return i
  except CatchableError:
    return default
