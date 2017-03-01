import scopes
import builtins
import bashlexer
import bashparser
import os
import osproc
import tables
import strutils
import sequtils
import macros

# TODO: report bug
# static[T] is stripped from seq[static[T]] (or static[seq[T]]?)
when false:
  macro wat(s: static[string]): expr =
    echo $s
    return newNimNode(nnkEmpty)
  static:
    wat("b")
    for f in ["a"]:
      wat(f)

macro execScriptFromString*(script: static[string]): expr =
  result = genShellAST(script, "[string]").toNimMain()

macro execScriptFromFile*(fileName: static[string]): expr =
  result = genShellAST(staticRead(fileName), fileName).toNimMain()
