# nothing/_src/none.nim
# copyright 2026 devdeczin (github)
import os
import std/[strutils, strformat]
import nihil_installer
import commands/meow
import commands/blade/blades

const Version* = "NONE V0.000..."

var
    showHelp    = false
    showVersion = false
    showBanner  = false
    meowStarted = false
    filename    = ""

proc getHelp(): string =
    &"""{Version}
    NONE: a (suspiciously) versatile pocket knife (for terminals)
    > none [arg] [file]

    args:
        -h          show this message
        -h:[cmd]    help for specific command
        -v          print version
        -b          show banner
        meow!       start MEOW repl
        blade       run a blade plugin

    none [file]     read a file (the whole reason this exists)
    """

proc getCommandHelp(cmd: string): string =
    case cmd
    of "blade":
        return """
    BLADE: add more blades (plugins) for your pocket knife
    - how use this command: none blade [my_blade.nim]
                            none blade install [my_blade.nim] (install in /runtime)
    - how to create a blade:
        > create a .nim file
        > use the Sharp.api (read docs_and_stuff/sharpDOTapi.md)
        > use command: none blade [your_blade.nim] for debug
        > done!
        """

    of "meow":
        return """
    MEOW: your util REPL for simple things (because you are lazy)
    - how use this command: none OR none meow! (both work)
    - available commands:
        > echo <text>            print text
        > let <name> <value>     set variable
        > mathematics <expr>     evaluate expression (+, -, *, /)
        > rand                   random number 0-100
        > help                   show this message
        > exit                   quit
        """
    else:
        return "not fine. unknown command: " & cmd

proc flags(flag: string) =
    if flag.startsWith("-h:"):
        let cmd = flag[3..^1]
        echo getCommandHelp(cmd)
        return
    case flag
    of "-h":
        showHelp = true
    of "-v":
        showVersion = true
    of "-b":
        showBanner = true
    else:
        echo "not fine. unknown flag: ", flag
        quit(1)

proc parse() =
    if paramCount() == 0:
        echo "not fine. starting meow repl [...]"
        initMeowRepl()
        return

    for i in 1..paramCount():
        let arg = paramStr(i)

        if arg == "meow!":
            initMeowRepl()
            meowStarted = true
            continue

        if arg == "blade":
            if i + 1 <= paramCount():
                let sub = paramStr(i + 1)
                if sub == "install":
                    if i + 2 <= paramCount():
                        installBlade(paramStr(i + 2))
                    else:
                        echo "not fine. usage: none blade install <file.nim>"
                else:
                    let (bin, _) = runBlade(sub)
                    killBlade(bin)
            else:
                # eu não sei como resolver esse erro
                # toda vez que inicio o none, ele dá esse erro
                echo "not fine. usage: none blade <name|file.nim>"
            return

        if arg.startsWith("-"):
            flags(arg)
        else:
            if filename == "":
                filename = arg
            else:
                echo "not fine. multiple files not supported"
                quit(1)

when isMainModule:
    checkInstall()
    parse()

    if showBanner:
        echo "==================="
        echo "$   hello world.  @"
        echo "===================\n"

    if showHelp:
        echo getHelp()
        quit(0)

    if showVersion:
        echo Version
        quit(0)

    if filename != "":
        try:
            let content = readFile(filename)
            echo content
        
        except IOError:
            echo "not fine. could not read: " & filename
            quit(1)
    
    elif not meowStarted:
        echo "not fine. no file provided."