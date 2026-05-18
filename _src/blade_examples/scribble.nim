# nothing/_src/blade_examples/scribble.nim
# um bloco de notas rápido
# uso:
#   none blade scribble add "fazer versão que impede que o file not improved não ocorra toda hora"
#   none blade scribble list
#   none blade scribble clear
#   none blade scribble pop

sharp.init()
sharp.metadata.details("scribble", "0.000...", "devdeczin")

const Sep = "---"

proc loadNotes(): seq[string] =
    if not sharp.hasdata():
        return @[]
    let raw = sharp.loaddata()
    result = @[]
    for line in raw.splitLines():
        if line.strip().len > 0:
            result.add(line)

proc saveNotes(notes: seq[string]) =
    sharp.savedata(notes.join("\n"))

proc cmdAdd(note: string) =
    if note.len == 0:
        sharp.error("nothing to add. usage: add <note>")
        sharp.exit(1)
    var notes = loadNotes()
    notes.add(note)
    saveNotes(notes)
    sharp.print("fine. note saved (" & $notes.len & " total)")

proc cmdList() =
    let notes = loadNotes()
    if notes.len == 0:
        sharp.print("no notes yet.")
        return
    sharp.print(Sep)
    for i, note in notes:
        sharp.print("[" & $(i + 1) & "] " & note)
    sharp.print(Sep)

proc cmdPop() =
    var notes = loadNotes()
    if notes.len == 0:
        sharp.error("no notes to pop.")
        sharp.exit(1)
    let last = notes[^1]
    notes.del(notes.len - 1)
    saveNotes(notes)
    sharp.print("popped: " & last)

proc cmdClear() =
    sharp.cleardata()
    sharp.print("fine. all notes cleared.")

when isMainModule:
    let bladeArgs = sharp.args()
    if bladeArgs.len == 0:
        cmdList()
        sharp.exit(0)
    case bladeArgs[0]
    of "add":
        let note = bladeArgs[1..^1].join(" ")
        cmdAdd(note)
    of "list":
        cmdList()
    of "pop":
        cmdPop()
    of "clear":
        cmdClear()
    else:
        sharp.error("unknown command: " & bladeArgs[0])
        sharp.print("commands: add <note> | list | pop | clear")
        sharp.exit(1)