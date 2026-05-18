# nothing/_src/commands/blade/blades.nim
import ../../nihil_installer
import std/strutils
import osproc, os

const BladesDir = DotNone / "blades"

# ====================
# Blade Resolvers
# ====================
proc installBlade*(bladefile: string) =
    if not fileExists(bladefile):
        echo "not fine. file not found: " & bladefile
        quit(1)

    createDir(BladesDir)

    let dest = BladesDir / bladefile.extractFilename()
    copyFile(bladefile, dest)

    echo "fine. blade installed: " & dest

proc findBlade(name: string): string =
    # tenta com e sem .nim
    let withExt    = BladesDir / name & ".nim"
    let withoutExt = BladesDir / name
    if fileExists(withExt):    return withExt
    if fileExists(withoutExt): return withoutExt
    return ""

# ====================
# sharpness
# ====================
proc sharpness(bladefile: string): string =
    let tempFile    = bladefile.changeFileExt("") & "_temp_sharp.nim"
    let sharpInclude = "include \"" & NoneDir / "sharpdotapi.nim" & "\"\n\n"
    let original    = readFile(bladefile)

    let dangerous = [
        "removeFile",
        "removeDir",
        "execCmd",
        "execShellCmd",
        "staticExec",
        "gorgeEx",
    ]

    for line in original.splitLines():
        let stripped = line.strip()
        
        # exclui comentários que tenham o dangerous
        if stripped.startsWith("#"): continue
        for danger in dangerous:
            if danger in stripped:
                echo "not fine. blade uses forbidden call: " & danger
                quit(1)

    writeFile(tempFile, sharpInclude & original)
    return tempFile

proc runBlade*(bladefile: string): tuple[bin: string, code: int] =
    # resolve se é arquivo local ou blade instalado
    let resolved =
        if fileExists(bladefile): bladefile
        else: findBlade(bladefile)

    if resolved.len == 0:
        echo "not fine. blade not found: " & bladefile
        return ("", 1)

    let tempFile = sharpness(resolved)
    let binName  = getTempDir() / resolved.extractFilename().changeFileExt("")

    if execCmd("nim c --hints:off --warnings:off --out:" & binName & " " & tempFile) != 0:
        removeFile(tempFile)
        echo "not fine. compilation failed"
        return ("", 1)

    removeFile(tempFile)

    let bladeArgs = commandLineParams()[2..^1].join(" ")
    let exitCode  = execCmd(binName & " " & bladeArgs)
    return (binName, exitCode)

proc killBlade*(binName: string) =
    if binName.len == 0: return
    try:
        removeFile(binName)
        echo "fine. blade killed"
    except:
        echo "not fine. bin not found: " & binName