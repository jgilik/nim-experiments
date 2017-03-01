import scopes
import macros
import osproc
import strutils
import tables

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

var builtinNames {.compileTime.} = newSeq[string]()
var builtinSyms {.compileTime.} = newTable[string, NimSym]()

macro builtin(name: static[string], body: expr): expr =
  body.expectKind(nnkStmtList)
  result = newNimNode(nnkStmtList)

  # Make sure to allow compile-time calculations based on if a given command
  # name corresponds to a builtin...
  builtinNames.add($name)

  # Construct a new function body!
  var newBody: NimNode = newStmtList()

  # Convert varargs representation to seq representation
  #newBody.add(newNimNode(nnkVarSection).add(newIdentDefs(
  #  name = ident("argv"),
  #  kind = newNimNode(nnkBracketExpr).add(
  #    ident("seq"), ident("string")),
  #  default = prefix(ident("argvInternal"), "@"),
  #)))

  # Start main function body
  newBody.add(body)

  # Tag the function body with a proc definition...
  var p: NimNode = newProc(
    name = newNimNode(nnkPostfix).add(ident("*"), ident($name & "Builtin")),
    body = newBody,
    params = @[
      # Return type is first by convention.
      ident("int"),

      # All shell builtins accept arbitrary number of tokens (strings):
      #   argvInternal: varargs[string]
      #newIdentDefs(
      #  name = ident("argvInternal"),
      #  kind = newNimNode(nnkBracketExpr).add(
      #    ident("varargs"), ident("string")),
      #),
      newIdentDefs(
        name = ident("argv"),
        kind = newNimNode(nnkBracketExpr).add(
          ident("seq"), ident("string"),
        ),
      ),
      newIdentDefs(
        name = ident("scope"),
        kind = ident("ShellScope"),
      ),
    ],
  )
  builtinSyms.add($name, symbol(p))
  result.add(p)

template isBuiltin*(name: static[string]): expr =
  var result: bool
  result = false
  when builtinNames.contains(name):
    result = true
  result

proc execShellCommand*(name: string, argv: seq[string]): NimNode {.compileTime.} =
  var paramBracket: NimNode = newNimNode(nnkBracket)
  for arg in argv:
    paramBracket.add(newLit(arg))
  result = newNimNode(nnkWhenStmt)
  result.add(
    newNimNode(nnkElifBranch).add(
      newCall(bindSym("isBuiltin"), newLit(name)),
      newStmtList(
        newNimNode(nnkDiscardStmt).add(newCall(
          ident($name & "Builtin"),
          newNimNode(nnkExprEqExpr).add(
            ident("argv"),
            paramBracket.prefix("@"),
          ),
          newNimNode(nnkExprEqExpr).add(
            ident("scope"),
            ident("scope"),
          ),
        ))
      )
    )
  )
  result.add(
    newNimNode(nnkElse).add(
      newStmtList(
        newNimNode(nnkDiscardStmt).add(newCall(
          ident("_execBuiltin"),
          newNimNode(nnkExprEqExpr).add(
            ident("argv"),
            paramBracket.prefix("@"),
          ),
          newNimNode(nnkExprEqExpr).add(
            ident("scope"),
            ident("scope"),
          ),
        ))
      )
    )
  )

# Magic builtin: executed if no builtin is found.
builtin "_exec":
  var subpr: Process
  subpr = startProcess(
    command = scope.findBin(argv[0]),
    args = argv[1 .. ^1],
    options = {poParentStreams},
  )
  result = subpr.waitForExit()

builtin "echo":
  echo join(argv[1 .. ^1], " ")
  result = 0
