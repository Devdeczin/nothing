# none
> **a (suspiciously) versatile pocket knife (for terminals)**
> by [`markarchive`](docs_and_stuff/markarquive.md)

`NONE V0.000...`

started as a bad `cat`. became something else.

---

## what it is

`none` is a minimal terminal tool written in Nim. it reads files, runs a small REPL called meow, and supports plugins called blades: compiled Nim programs that run under a sandboxed API called Sharp.

it doesn't try to be pretty. it tries to work.

---

## install

**requirements:** Nim compiler installed and in PATH.

```bash
git clone https://github.com/devdeczin/none
cd none/_src
nim c -d:release none
sudo ln -s $(pwd)/none /usr/local/bin/none
```

on first run, `none` installs its runtime to `~/.none/`.

---

## usage

```
none [file]         read a file (the whole reason this exists)
none meow!          start the meow REPL
none blade <name>   run an installed blade
none blade install <file.nim>   install a blade
none -h             help
none -h:[cmd]       help for a specific command
none -v             version
```

---

## meow

a small REPL for quick things.

```
meow ~> echo hello world
hello world
meow ~> let x 42
fine.
meow ~> mathematics 2*x
not fine. unknown command: x
meow ~> mathematics 2*21
42
meow ~> rand
73
meow ~> exit
bye.
```

available commands: `echo`, `let`, `mathematics`, `rand`, `help`, `exit`.
(i was bored when i did that, at 0.333333..., the meow will serve some useful purpose [i hope])

---

## blades

blades are plugins: `.nim` files that run under the Sharp API. none compiles and executes them on demand, then cleans up the binary.

```bash
none blade install scribble.nim
none blade scribble add "remember to sleep"
none blade scribble list
```

blades don't import anything. the Sharp API is injected automatically before compilation.

see [`docs_and_stuff/sharpDOTapi.md`](docs_and_stuff/sharpDOTapi.md) for the full API reference.

### included blades

| blade | description |
|---|---|
| `scribble` | quick notes |
| `tether` | project organizer |

### writing a blade

```nim
# hello.nim
sharp.init()
sharp.metadata.details("hello", "0.000...", "you")

let bladeArgs = sharp.args()
sharp.print("fine. hello, " & bladeArgs.join(" "))
```

```bash
none blade install hello.nim
none blade hello world
# [hello] fine. hello, world
```

blades cannot use `removeFile`, `removeDir`, `execCmd`, `execShellCmd`, `staticExec`, or `gorgeEx`. if your blade needs those, it's doing too much.

---

## project structure

```
none/
├── README.md
├── docs_and_stuff
│   ├── markarquive.md
│   └── sharpDOTapi.md
└── _src
    ├── bin
    │   └── none
    ├── blade_examples
    │   ├── scribble.nim
    │   └── tether.nim
    ├── commands
    │   ├── blade
    │   │   ├── blades.nim
    │   │   └── sharpdotapi.nim
    │   ├── meow.nim
    │   └── static_config.nim
    ├── nihil_installer.nim
    └── none.nim
```

at runtime, modules are installed to `~/.none/runtime/` and blade binaries compile to `/tmp/`.

---

## license

copyright 2026 devdeczin: do whatever you want with it (except crimes, if that's even possible).

read the (real) [license](LICENSE)

---

*fine.*