import macros
import bashlexer
import builtins
import scopes

type
  ShellNodeKind* = enum
    snkEmptyNode,
    snkStrLit,
    snkStmtList,
    snkCmdStmt,
    snkCondStmt,
    snkElifNode,
    snkElseNode,

  ShellNode* = ref ShellNodeObj
  ShellNodeObj* = object
    case kind: ShellNodeKind
    of snkEmptyNode:
      discard
    of snkStrLit:
      strVal: string
    else:
      children: seq[ShellNode]

proc `$`*(k: ShellNodeKind): string {.inline.} = 
  case k
  of snkStmtList: return "StmtList"
  of snkCmdStmt: return "CmdStmt"
  of snkCondStmt: return "CondStmt"
  of snkStrLit: return "StrLit"
  of snkElifNode: return "ElifNode"
  of snkElseNode: return "ElseNode"
  of snkEmptyNode: return "EmptyNode"
  else: raise newException(ValueError, "unknown shell node kind")

proc kind*(n: ShellNode): ShellNodeKind {.inline.} =
  result = n.kind

proc `$`*(n: ShellNode): string =
  case n.kind:
  of snkStrLit: result = n.strVal
  else: assert(false)

proc repr*(n: ShellNode): string = 
  case n.kind
  of snkEmptyNode: return ""
  of snkStmtList:
    result = ""
    for child in n.children:
      if result != "":
        result = result & "\n"
      result = result & child.repr
  of snkStrLit: result = n.strVal
  of snkCmdStmt:
    result = ""
    for child in n.children:
      if result != "":
        result = result & " "
      result = result & $child
  else: result = "Unhandled node of kind " & $n.kind

proc toNim*(n: ShellNode): NimNode {.compileTime.} =
  case n.kind
  of snkStmtList:
    result = newNimNode(nnkStmtList)
    for child in n.children:
      result.add(child.toNim())
  of snkStrLit:
    result = newLit(n.strVal)
  of snkCmdStmt:
    assert(n.children.len > 0)
    # TODO: Bad to assume tokens are all string literals.
    # (Remember that `echo "thing $(hostname)"` is totally OK.)
    var tokens: seq[string] = newSeq[string]()
    for child in n.children:
      tokens.add($child)
    var firstChild: ShellNode = n.children[0]
    case firstChild.kind
      of snkStrLit:
        result = execShellCommand(firstChild.strVal, tokens)
      else:
        raise newException(ValueError,
          "non-literal command token of kind: " & $(firstChild.kind)
        )
  else: raise newException(ValueError, "unknown node kind: " & $(n.kind))

proc toNimMain*(n: ShellNode): NimNode {.compileTime.} =
  var subTree: NimNode = n.toNim()
  result = newNimNode(nnkStmtList).
    add(newNimNode(nnkVarSection).
      add(newIdentDefs(
        name = ident("scope"),
        kind = bindSym("ShellScope"),
        default = newCall(bindSym("newScope")),
      ))
    ).
    add(subTree)

proc add*(parent: ShellNode, child: ShellNode): ShellNode =
  result = parent
  result.children.add(child)

proc add*(parent: var ShellNode, child: ShellNode) =
  parent.children.add(child)

proc newShellNode*(kind: ShellNodeKind): ShellNode =
  result = ShellNode(kind: kind)
  case kind
  of snkEmptyNode, snkStrLit: discard
  else: result.children = newSeq[ShellNode]()

proc newShellLit*(val: string): ShellNode =
  result = ShellNode(kind: snkStrLit, strVal: val)
 
proc genShellAST*(code, fileName: string): ShellNode =
  var lexer: ShellLexer = newShellLexer(code, filename)
  #var parser: ShellParser = newShellParser(lexer, fileName)
  var stmtList: ShellNode = newShellNode(snkStmtList)
  var currentStmt: ShellNode = newShellNode(snkCmdStmt)
  while true:
    var tok: ShellToken = lexer.rawGetTok()
    case tok.kind
    of stkEndOfFile:
      break
    of stkEndOfStatement:
      if len(currentStmt.children) == 0:
        continue
      stmtList.add(currentStmt)
      currentStmt = newShellNode(snkCmdStmt)
    of stkComment:
      continue
    of stkWord:
      currentStmt.add(newShellLit(tok.body))
    else:
      raise newException(ValueError, "unknown token type encountered")
  return stmtList

