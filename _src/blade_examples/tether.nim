# nothing/_src/commands/blade/tether.nim
# a project organizer for none
# usage:
#   none blade tether new "none" --code
#   none blade tether list
#   none blade tether info none
#   none blade tether note none "precisa de refactor no parse"
#   none blade tether todo none "implementar seasick"
#   none blade tether done none "implementar seasick"
#   none blade tether update none "v2 - adicionado blade system"
#   none blade tether read none
#   none blade tether tag none writing
#   none blade tether link none "https://github.com/..."
#   none blade tether rm none

sharp.init()
sharp.metadata.details("tether", "0.000...", "devdeczin")

import std/[json, strutils, times, sequtils]
import posix

# ===========
# types
# ===========
type
    TodoItem = object
        text : string
        done : bool

    Update = object
        label : string
        desc  : string

    Project = object
        name    : string
        tags    : seq[string]
        link    : string
        path    : string
        notes   : seq[string]
        todos   : seq[TodoItem]
        updates : seq[Update]
        readme  : string

# =============
# valid tags
# =============
const ValidTags = [
    "code", "writing", "drawing", "animation",
    "done", "wip", "not-started"
]

# ==============
# persistence
# ==============

proc loadProjects(): JsonNode =
    if not sharp.hasdata():
        return newJObject()
    try:
        return parseJson(sharp.loaddata())
    except:
        return newJObject()

proc saveProjects(data: JsonNode) =
    sharp.savedata($data)

proc projectToJson(p: Project): JsonNode =
    let todosArr = newJArray()
    for t in p.todos:
        todosArr.add(%*{"text": t.text, "done": t.done})

    let updatesArr = newJArray()
    for u in p.updates:
        updatesArr.add(%*{"label": u.label, "desc": u.desc})

    let tagsArr = newJArray()
    for tag in p.tags:
        tagsArr.add(%tag)

    let notesArr = newJArray()
    for note in p.notes:
        notesArr.add(%note)

    return %*{
        "name"    : p.name,
        "tags"    : tagsArr,
        "link"    : p.link,
        "path"    : p.path,
        "notes"   : notesArr,
        "todos"   : todosArr,
        "updates" : updatesArr,
        "readme"  : p.readme
    }

proc jsonToProject(j: JsonNode): Project =
    result.name   = j["name"].getStr()
    result.link   = j["link"].getStr()
    result.path   = j["path"].getStr()
    result.readme = j["readme"].getStr()

    for tag in j["tags"]:
        result.tags.add(tag.getStr())
    for note in j["notes"]:
        result.notes.add(note.getStr())
    for t in j["todos"]:
        result.todos.add(TodoItem(text: t["text"].getStr(), done: t["done"].getBool()))
    for u in j["updates"]:
        result.updates.add(Update(label: u["label"].getStr(), desc: u["desc"].getStr()))

# ========
# helpers
# =========
const
    Sep     = "---"
    SepFat  = "==="

proc exists(data: JsonNode, name: string): bool =
    data.hasKey(name)

proc getProject(data: JsonNode, name: string): Project =
    if not data.exists(name):
        sharp.error("project not found: " & name)
        sharp.exit(1)
    return jsonToProject(data[name])

proc statusSymbol(done: bool): string =
    if done: "[x]" else: "[ ]"

proc tagList(tags: seq[string]): string =
    if tags.len == 0: return "none"
    return tags.join(", ")

# ==========
# commands
# ==========
proc cmdNew(name: string, args: seq[string]) =
    var data = loadProjects()
    if data.exists(name):
        sharp.error("project already exists: " & name)
        sharp.exit(1)

    var p = Project(
        name   : name,
        link   : "",
        path   : sharp.bladepath(),
        readme : "",
        tags   : @[],
        notes  : @[],
        todos  : @[],
        updates: @[]
    )

    # processa flags de tag iniciais (--code, --writing, etc)
    for arg in args:
        if arg.startsWith("--"):
            let tag = arg[2..^1]
            if tag in ValidTags:
                p.tags.add(tag)
            else:
                sharp.error("unknown tag: " & tag)
                sharp.exit(1)

    if p.tags.len == 0:
        p.tags.add("not-started")

    data[name] = projectToJson(p)
    saveProjects(data)
    sharp.print("fine. project created: " & name)
    sharp.print("tags: " & tagList(p.tags))

proc cmdList() =
    let data = loadProjects()
    if data.len == 0:
        sharp.print("no projects yet.")
        return
    sharp.print(SepFat)
    for name, proj in data:
        let p = jsonToProject(proj)
        let todosDone  = p.todos.filterIt(it.done).len
        let todosTotal = p.todos.len
        sharp.print(name & "  [" & tagList(p.tags) & "]")
        if todosTotal > 0:
            sharp.print("  todos: " & $todosDone & "/" & $todosTotal & " done")
        if p.updates.len > 0:
            sharp.print("  latest: " & p.updates[^1].label)
    sharp.print(SepFat)

proc cmdInfo(name: string) =
    let data = loadProjects()
    let p    = getProject(data, name)

    sharp.print(SepFat)
    sharp.print("project : " & p.name)
    sharp.print("tags    : " & tagList(p.tags))
    if p.link.len > 0:
        sharp.print("link    : " & p.link)

    if p.path.len > 0:
        sharp.print("path    : " & p.path)

    if p.notes.len > 0:
        sharp.print(Sep)
        sharp.print("notes:")
        for i, note in p.notes:
            sharp.print("  [" & $(i+1) & "] " & note)

    if p.todos.len > 0:
        sharp.print(Sep)
        sharp.print("todos:")
        for t in p.todos:
            sharp.print("  " & statusSymbol(t.done) & " " & t.text)

    if p.updates.len > 0:
        sharp.print(Sep)
        sharp.print("updates:")
        for u in p.updates:
            sharp.print("  " & u.label & " — " & u.desc)

    if p.readme.len > 0:
        sharp.print(Sep)
        sharp.print("readme: (use 'read' to view)")

    sharp.print(SepFat)

proc cmdNote(name, note: string) =
    var data = loadProjects()
    var p    = getProject(data, name)
    p.notes.add(note)
    data[name] = projectToJson(p)
    saveProjects(data)
    sharp.print("fine. note added to " & name)

proc cmdTodo(name, todo: string) =
    var data = loadProjects()
    var p    = getProject(data, name)
    p.todos.add(TodoItem(text: todo, done: false))
    data[name] = projectToJson(p)
    saveProjects(data)
    sharp.print("fine. todo added: " & todo)

proc cmdDone(name, todo: string) =
    var data = loadProjects()
    var p    = getProject(data, name)
    var found = false
    for i in 0..<p.todos.len:
        if p.todos[i].text == todo:
            p.todos[i].done = true
            found = true
            break
    if not found:
        # tenta por índice
        try:
            let idx = parseInt(todo) - 1
            if idx >= 0 and idx < p.todos.len:
                p.todos[idx].done = true
                found = true
        except: discard
    if not found:
        sharp.error("todo not found: " & todo)
        sharp.exit(1)
    data[name] = projectToJson(p)
    saveProjects(data)
    sharp.print("fine. todo marked as done.")

proc cmdUpdate(name, label, desc: string) =
    var data = loadProjects()
    var p    = getProject(data, name)
    p.updates.add(Update(label: label, desc: desc))
    data[name] = projectToJson(p)
    saveProjects(data)
    sharp.print("fine. update logged: " & label)

proc cmdRead(name: string) =
    let data = loadProjects()
    let p    = getProject(data, name)
    if p.readme.len == 0:
        sharp.print("no readme yet. use: tether readme " & name & " \"...\"")
        return
    sharp.print(SepFat)
    sharp.print(p.name)
    sharp.print(Sep)
    sharp.print(p.readme)
    sharp.print(SepFat)

proc cmdReadme(name: string, args: seq[string]) =
    var data = loadProjects()
    var p    = getProject(data, name)

    if args.len > 0 and args[0] == "--file":
        if args.len < 2:
            sharp.error("usage: readme <n> --file <path>")
            sharp.exit(1)
        let path = args[1]
        if not fileExists(path):
            sharp.error("file not found: " & path)
            sharp.exit(1)
        p.readme = readFile(path)
    elif args.len > 0:
        p.readme = args.join(" ")
    else:
        sharp.error("usage: readme <n> --file <path>  OR  readme <n> <text>")
        sharp.exit(1)

    data[name] = projectToJson(p)
    saveProjects(data)
    sharp.print("fine. readme set for " & name)

proc cmdTag(name, tag: string) =
    if tag notin ValidTags:
        sharp.error("unknown tag: " & tag)
        sharp.print("valid tags: " & ValidTags.join(", "))
        sharp.exit(1)
    var data = loadProjects()
    var p    = getProject(data, name)
    if tag notin p.tags:
        p.tags.add(tag)
    data[name] = projectToJson(p)
    saveProjects(data)
    sharp.print("fine. tag added: " & tag)

proc cmdUntag(name, tag: string) =
    var data = loadProjects()
    var p    = getProject(data, name)
    p.tags = p.tags.filterIt(it != tag)
    data[name] = projectToJson(p)
    saveProjects(data)
    sharp.print("fine. tag removed: " & tag)

proc cmdLink(name, link: string) =
    var data = loadProjects()
    var p    = getProject(data, name)
    p.link = link
    data[name] = projectToJson(p)
    saveProjects(data)
    sharp.print("fine. link set: " & link)

proc cmdRm(name: string) =
    var data = loadProjects()
    if not data.exists(name):
        sharp.error("project not found: " & name)
        sharp.exit(1)
    data.delete(name)
    saveProjects(data)
    sharp.print("fine. project removed: " & name)

proc cmdHelp() =
    sharp.print("""
    tether: project organizer

        new <name> [--code|--writing|--drawing|--animation]
        list
        info <name>
        note <name> <note>
        todo <name> <task>
        done <name> <task|index>
        update <name> <label> <desc>
        read <name>
        readme <name> <optional: --file> <text>
        tag <name> <tag>
        untag <name> <tag>
        link <name> <url>
        rm <name>

    tags: code, writing, drawing, animation, done, wip, not-started
    """)

# =========
# entry
# =========
let bladeArgs = sharp.args()

if bladeArgs.len == 0:
    cmdList()
    sharp.exit(0)

case bladeArgs[0]
of "new":
    if bladeArgs.len < 2:
        sharp.error("usage: new <name> [--tag]")
        sharp.exit(1)
    cmdNew(bladeArgs[1], bladeArgs[2..^1])
of "list":
    cmdList()
of "info":
    if bladeArgs.len < 2: sharp.error("usage: info <name>"); sharp.exit(1)
    cmdInfo(bladeArgs[1])
of "note":
    if bladeArgs.len < 3: sharp.error("usage: note <name> <note>"); sharp.exit(1)
    cmdNote(bladeArgs[1], bladeArgs[2..^1].join(" "))
of "todo":
    if bladeArgs.len < 3: sharp.error("usage: todo <name> <task>"); sharp.exit(1)
    cmdTodo(bladeArgs[1], bladeArgs[2..^1].join(" "))
of "done":
    if bladeArgs.len < 3: sharp.error("usage: done <name> <task|index>"); sharp.exit(1)
    cmdDone(bladeArgs[1], bladeArgs[2..^1].join(" "))
of "update":
    if bladeArgs.len < 4: sharp.error("usage: update <name> <label> <desc>"); sharp.exit(1)
    cmdUpdate(bladeArgs[1], bladeArgs[2], bladeArgs[3..^1].join(" "))
of "read":
    if bladeArgs.len < 2: sharp.error("usage: read <name>"); sharp.exit(1)
    cmdRead(bladeArgs[1])
of "readme":
    if bladeArgs.len < 3: sharp.error("usage: readme <name> <text>"); sharp.exit(1)
    cmdReadme(bladeArgs[1], bladeArgs[2..^1])
of "tag":
    if bladeArgs.len < 3: sharp.error("usage: tag <name> <tag>"); sharp.exit(1)
    cmdTag(bladeArgs[1], bladeArgs[2])
of "untag":
    if bladeArgs.len < 3: sharp.error("usage: untag <name> <tag>"); sharp.exit(1)
    cmdUntag(bladeArgs[1], bladeArgs[2])
of "link":
    if bladeArgs.len < 3: sharp.error("usage: link <name> <url>"); sharp.exit(1)
    cmdLink(bladeArgs[1], bladeArgs[2])
of "rm":
    if bladeArgs.len < 2: sharp.error("usage: rm <name>"); sharp.exit(1)
    cmdRm(bladeArgs[1])
of "help":
    cmdHelp()
else:
    sharp.error("unknown command: " & bladeArgs[0])
    sharp.print("use 'tether help' for available commands")
    sharp.exit(1)