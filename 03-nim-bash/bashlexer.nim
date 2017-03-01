type
  ShellTokenKind* = enum
    stkEmptyNode,
    stkWord,

    stkConditionalStart,
    stkConditionalEnd,

    stkReservedIf,
    stkReservedThen,
    stkReservedElse,
    stkReservedElif,
    stkReservedFi,
    stkReservedCase,
    stkReservedEsac,
    stkReservedFor,
    stkReservedSelect,
    stkReservedWhile,
    stkReservedUntil,
    stkReservedDo,
    stkReservedDone,
    stkReservedFunction,
    stkReservedIn,

    stkOperatorAndAnd,
    stkOperatorOrOr,
    stkOperatorGreaterGreater,
    stkOperatorGreaterAnd,
    stkOperatorGreaterBar,
    stkOperatorAndGreater,
    stkOperatorLessLess,
    stkOperatorLessAnd,
    stkOperatorLessLessLess,
    stkOperatorLessLessMinus,
    stkOperatorLessGreater,

    stkComment,
    stkEndOfStatement,
    stkEndOfFile,
    
  ShellToken* = ref ShellTokenObj

  ShellTokenObj* = object
    case kind*: ShellTokenKind
    of stkWord, stkComment:
      body*: string
    else:
      discard

  ShellLexer* = object
    fileName: string
    code: string
    charNum: int
    line: string
    lineNum: int
    columnNum: int

proc newShellLexer*(code: string, fileName: string): ShellLexer =
  result = ShellLexer(
    fileName: fileName,
    code: code,
    charNum: 0,
    line: "",
    lineNum: 0,
    columnNum: 0,
  )

proc newShellToken*(kind: ShellTokenKind): ShellToken =
  result = ShellToken(kind: kind)
  case kind
  of stkWord, stkComment:
    result.body = ""
  else:
    discard

proc newShellWord*(body: string): ShellToken =
  result = newShellToken(stkWord)
  result.body = body

proc `==`*(left, right: ShellToken): bool =
  if left.kind != right.kind:
    return false
  case left.kind
  of stkWord, stkComment:
    if left.body != right.body:
      return false
  else:
    discard
  return true


proc atEndOfFile(p: ShellLexer): bool {.inline.} =
  result = p.charNum >= len(p.code)

proc currentChar(p: ShellLexer): char {.inline.} =
  result = p.code[p.charNum]

proc incChar(p: var ShellLexer) {.inline.} =
  inc(p.charNum)
  inc(p.columnNum)
  if not p.atEndOfFile() and p.currentChar() == '\r':
    if p.charNum + 1 < len(p.code) and p.code[p.charNum + 1] == '\l':
      inc(p.charNum)
    p.columnNum = -1
    inc(p.lineNum)

proc skip(p: var ShellLexer) =
  while true:
    if p.atEndOfFile():
      break
    case p.currentChar()
    of ' ', '\t':
      p.incChar()
    else:
      break

proc getComment(p: var ShellLexer): ShellToken =
  if p.atEndOfFile():
    raise newException(ValueError, "looking for comment at EOF not valid")
  if p.currentChar() != '#':
    raise newException(ValueError,
      "comment begins with '" & p.currentChar() & "', not '#'"
    )
  p.incChar()
  result = newShellToken(stkComment)
  while true:
    if p.atEndOfFile() or {'\c', '\l'}.contains(p.currentChar()):
      break
    result.body.add(p.currentChar())
    p.incChar()

proc getWord(p: var ShellLexer): ShellToken =
  result = newShellToken(stkWord)
  while true:
    # Conditions that flag end of a bare token: EOF
    if p.atEndOfFile():
      break
    # whitespace
    if {' ', '\c', '\l', '\t', '\0'}.contains(p.currentChar()):
      break
    # operators
    if {'$', '"', ';'}.contains(p.currentChar()):
      break
    result.body.add(p.currentChar())
    p.incChar()
  case result.body
  of "if": return newShellToken(stkReservedIf)
  of "then": return newShellToken(stkReservedThen)
  of "fi": return newShellToken(stkReservedFi)
  else: discard

proc rawGetTok*(p: var ShellLexer): ShellToken =
  p.skip()
  if p.atEndOfFile():
    return newShellToken(stkEndOfFile)
  case p.currentChar()
  of '#':
    result = p.getComment()
  of '\c', '\l', ';':
    result = newShellToken(stkEndOfStatement)
    p.incChar()
  else:
    result = p.getWord()

proc tokSeq*(p: var ShellLexer): seq[ShellToken] =
  result = newSeq[ShellToken]()
  while not p.atEndOfFile():
    result.add(p.rawGetTok())
