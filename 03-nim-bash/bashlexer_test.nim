import unittest
import bashlexer
import macros

suite "token type":
  test "equality operator success case":
    var t1: ShellToken = newShellToken(stkOperatorLessLess)
    var t2: ShellToken = newShellToken(stkOperatorLessLess)
    check(t1 == t2)
  test "equality operator failure case":
    var t1: ShellToken = newShellToken(stkOperatorLessLess)
    var t2: ShellToken = newShellToken(stkEndOfFile)
    check(t1 != t2)
  test "equality success for words":
    check(newShellWord("bacon") == newShellWord("bacon"))
  test "equality failure for words":
    check(newShellWord("bacon") != newShellWord("green eggs"))
    

macro lex(input: static[string]): expr =
  return newNimNode(nnkVarSection).
    add(newIdentDefs(
      name = ident("lexer"),
      kind = ident("ShellLexer"),
      default = newCall(
        ident("newShellLexer"),
        newLit(input),
        newLit("[test]"),
      ),
    ))

macro assertEqual(left, right: typed): expr =
  return newNimNode(nnkIfStmt).add(
    newNimNode(nnkElifBranch).add(
      newNimNode(nnkInfix).add(ident("!="), left, right),
      newNimNode(nnkStmtList).add(
        newNimNode(nnkCommand).add(
          ident("echo"),
          newLit("got: "),
          newNimNode(nnkDotExpr).add(left, ident("repr")),
          newLit("; want: "),
          newNimNode(nnkDotExpr).add(right, ident("repr")),
        ),
        newCall(ident("fail")),
      ),
    ),
  )

suite "tokenizer":
  test "just words":
    lex("echo three word string")
    assertEqual(lexer.tokSeq(), @[
      newShellWord("echo"),
      newShellWord("three"),
      newShellWord("word"),
      newShellWord("string"),
    ])

  test "two commands":
    lex("echo a;echo b")
    assertEqual(lexer.tokSeq(), @[
      newShellWord("echo"),
      newShellWord("a"),
      newShellToken(stkEndOfStatement),
      newShellWord("echo"),
      newShellWord("b"),
    ])

  test "if statement":
    lex("if a;then echo b;fi")
    assertEqual(lexer.tokSeq(), @[
      newShellToken(stkReservedIf),
      newShellWord("a"),
      newShellToken(stkEndOfStatement),
      newShellToken(stkReservedThen),
      newShellWord("echo"),
      newShellWord("b"),
      newShellToken(stkEndOfStatement),
      newShellToken(stkReservedFi),
    ])
