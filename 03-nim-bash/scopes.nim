import tables
import os
import strutils

## Shell scopes contain the environment.
type
  ShellScope* = ref ShellScopeObj
  ShellScopeObj* = object
    environment: Table[string, string]

proc newScope*(): ShellScope =
  result = ShellScope(
    environment: initTable[string, string](),
  )
  for k, v in envPairs():
    result.environment[k] = v

proc getEnv*(scope: ShellScope, name: string): string =
  if not scope.environment.hasKey name:
    return ""
  result = scope.environment[name]

proc findBin*(scope: ShellScope, name: string): string =
  if name.contains("/"):
    if not name.existsFile():
      raise newException(ValueError, "binary '" & name & "' not found")
    return name
  var paths: string = scope.getEnv("PATH")
  for path in paths.split(":"):
    if path == "":
      continue
    var filepath: string = joinPath(path, name)
    if filepath.existsFile():
      return filepath
  raise newException(ValueError, "binary '" & name & "' not found in PATH")
