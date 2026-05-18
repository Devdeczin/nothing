# nothing/_src/nihil_installer.nim
import std/[os, times, strutils]
import osproc

const
    MeowSrc*        = staticRead("commands/meow.nim")

    BladesSrc*      = staticRead("commands/blade/blades.nim")
    ShardotapiSrc*  = staticRead("commands/blade/sharpdotapi.nim")

    DotNone* = getHomeDir() / ".none"
    NoneDir* = DotNone / "runtime"

proc isInstalled(): bool = fileExists(NoneDir / "meow.nim")

proc initNihilInstaller() =
    echo "none <nihil_installer>: installing runtime"
    
    createDir(NoneDir)
    createDir(NoneDir / "cache")

    writeFile(NoneDir / "meow.nim",          MeowSrc)
    writeFile(NoneDir / "blades.nim",        BladesSrc)
    writeFile(NoneDir / "sharpdotapi.nim",   ShardotapiSrc)
    
    echo "fine. runtime installed at " & NoneDir

proc runRuntime*(module: string, args: seq[string] = @[]) =
    let src = NoneDir / module & ".nim"
    let bin = NoneDir / "cache" / module
    
    # só recompila se o fonte for mais novo que o binário
    if not fileExists(bin) or getLastModificationTime(src) > getLastModificationTime(bin):
        echo "none <nihil_installer>: updating runtime module: ", module
        if execCmd("nim c --out:" & bin & " " & src) != 0:
            echo "not fine. failed to compile runtime: ", module
            quit(1)
    
    discard execCmd(bin & " " & args.join(" "))

proc checkInstall*() =
    if not isInstalled():
        initNihilInstaller()