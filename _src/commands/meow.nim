# nothing/_src/commands/meow.nim
import std/[strutils, tables, random]

type
    MeowState = object
        running : bool
        vars    : Table[string, string]

proc initState(): MeowState =
    MeowState(
        running : true,
        vars    : initTable[string, string]()
    )

proc tokenize(expr: string): seq[string] =
    result = @[]
    var current = ""
    for c in expr:
        if c.isDigit or (c == '-' and current.len == 0):
            current.add(c)
        else:
            if current.len > 0:
                result.add(current)
                current = ""
            if c in ['+', '-', '*', '/']:
                result.add($c)
    if current.len > 0:
        result.add(current)

proc safeParseInt(s: string): tuple[ok: bool, val: int] =
    try:
        result = (true, parseInt(s))
    except:
        result = (false, 0)

proc calc(exprr: string): string =
    var tokens = tokenize(exprr)

    if tokens.len == 0:
        return "error: empty expression"

    # multiplicação e divisão
    var i = 1
    while i < tokens.len:
        if tokens[i] in ["*", "/"]:
            if i + 1 >= tokens.len:
                return "error: incomplete expression"
            let (aOk, a) = safeParseInt(tokens[i - 1])
            if not aOk: return "error: not a number: " & tokens[i - 1]
            let (bOk, b) = safeParseInt(tokens[i + 1])
            if not bOk: return "error: not a number: " & tokens[i + 1]
            if tokens[i] == "/" and b == 0:
                return "error: division by zero"
            tokens[i - 1] = $(if tokens[i] == "*": a * b else: a div b)
            tokens.delete(i + 1)
            tokens.delete(i)
        else:
            inc i

    # soma e subtração
    let (r0Ok, r0) = safeParseInt(tokens[0])
    if not r0Ok: return "error: not a number: " & tokens[0]
    var resultValue = r0

    i = 1
    while i < tokens.len:
        if i + 1 >= tokens.len:
            return "error: incomplete expression"
        let op = tokens[i]
        let (numOk, num) = safeParseInt(tokens[i + 1])
        if not numOk: return "error: not a number: " & tokens[i + 1]
        if op == "+":
            resultValue += num
        elif op == "-":
            resultValue -= num
        else:
            return "error: invalid operator: " & op
        i += 2

    return $resultValue

proc eval(input: string, state: var MeowState): string =
    let parts = input.splitWhitespace()
    if parts.len == 0:
        return ""

    let cmd  = parts[0]
    let args = parts[1..^1]

    case cmd
    of "exit":
        state.running = false
        echo "bye."
        return ""
    
    of "echo":
        return args.join(" ")
    
    of "rand":
        randomize()
        return $rand(100)
    
    of "let":
        if args.len >= 2:
            let name  = args[0]
            let value = args[1..^1].join(" ")
            state.vars[name] = value
            return "fine."
        else:
            return "not fine. usage: let name value"
    
    of "mathematics":
        let exprStart = input.find(cmd) + cmd.len
        let expr = input[exprStart..^1].strip()
        if expr.len == 0:
            return "not fine. usage: mathematics <expression>"
        return calc(expr)
    
    of "help":
        return """commands:
    echo <text>            print text
    let <name> <value>     set variable
    mathematics <expr>     evaluate expression (+, -, *, /)
    rand                   random number 0-100
    help                   show this message
    exit                   quit"""
    else:
        if state.vars.hasKey(cmd):
            return state.vars[cmd]
        return "not fine. unknown command: " & cmd

proc initMeowRepl*() =
    var state = initState()
    while state.running:
        stdout.write("meow ~> ")
        stdout.flushFile()

        if stdin.endOfFile:
            break

        let line = stdin.readLine().strip()
        if line.len == 0:
            continue

        let output = eval(line, state)
        if output.len > 0:
            echo output

when isMainModule:
    initMeowRepl()