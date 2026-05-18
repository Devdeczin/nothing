# nothing/_src/commands/blade/sharpdotapi.nim
# Sharp.API: a api love-like para os blades
import std/[os, strutils, times]

# ====================
# inital stuff
# ====================
const SharpVersion* = "v0.000..."

type
    SharpMetadata = object
        name    : string
        version : string
        author  : string

    SharpState = object
        metadata  : SharpMetadata
        cachedir  : string
        bladedir  : string
        initiated : bool

var sharp* = SharpState()

# ====================
# metadata
# ====================
proc details*(m: var SharpMetadata, name, version, author: string) =
    m.name    = name
    m.version = version
    m.author  = author

proc get*(m: SharpMetadata): string =
    m.name & " v" & m.version & " by " & m.author

# ====================
# ciclo
# ====================
proc init*(s: var SharpState) =
    let dotNone   = getHomeDir() / ".none"
    s.cachedir    = dotNone / "blades" / "cache"
    s.bladedir    = getCurrentDir()
    s.initiated   = true
    createDir(s.cachedir)

proc exit*(s: SharpState, code: int = 0) =
    quit(code)

proc version*(s: SharpState): string =
    SharpVersion

# ====================
# i/o
# ====================
proc print*(s: SharpState, text: string) =
    let prefix = if s.metadata.name.len > 0: "[" & s.metadata.name & "] " else: ""
    echo prefix & text

proc error*(s: SharpState, text: string) =
    let prefix = if s.metadata.name.len > 0: "[" & s.metadata.name & "] " else: ""
    stderr.writeLine("not fine. " & prefix & text)

proc input*(s: SharpState, prompt: string = ""): string =
    if prompt.len > 0:
        stdout.write(prompt)
        stdout.flushFile()
    return stdin.readLine()

proc args*(s: SharpState): seq[string] =
    result = @[]
    for i in 1..paramCount():
        result.add(paramStr(i))

# ====================
# cache
# ====================
proc cachepath*(s: SharpState): string =
    s.cachedir

proc hasdata*(s: SharpState): bool =
    fileExists(s.cachedir / "data")

proc savedata*(s: SharpState, data: string) =
    writeFile(s.cachedir / "data", data)

proc loaddata*(s: SharpState): string =
    if not s.hasdata():
        return ""
    readFile(s.cachedir / "data")

proc cleardata*(s: SharpState) =
    if s.hasdata():
        removeFile(s.cachedir / "data")

# ====================
# env
# ====================
proc env*(s: SharpState, key: string): string =
    getEnv(key)

proc env*(s: SharpState, key, default: string): string =
    getEnv(key, default)

proc homepath*(s: SharpState): string =
    getHomeDir() / ".none"

proc bladepath*(s: SharpState): string =
    s.bladedir

# ====================
# comunicação (NONE)
# ====================
proc call*(s: SharpState, cmd: string) =
    echo "__NONE__:" & cmd

proc log*(s: SharpState, msg: string) =
    stderr.writeLine("[sharp:log] " & msg)