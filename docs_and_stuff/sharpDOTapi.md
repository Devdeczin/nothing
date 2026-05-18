# Sharp.api
**the blade API for none**
version `0.000...`

---

Sharp is the API injected into every blade before compilation. You don't import it, you don't include it: it's just there. Every blade has access to a global `sharp` object that exposes the functions below.

The first thing every blade should do is call `sharp.init()`. Without it, cache and path functions won't work correctly.

---

## lifecycle

```nim
sharp.init()
```
Initializes the sharp state. Sets up cache directory at `~/.none/blades/cache/`. Call this before anything else.

```nim
sharp.exit(code: int)
```
Exits the blade with the given exit code. `0` is fine, anything else is not fine.

```nim
sharp.version(): string
```
Returns the Sharp API version string.

---

## metadata

```nim
sharp.metadata.details(name, version, author: string)
```
Sets the blade identity. Used by `sharp.print` and `sharp.error` as prefix.

```nim
sharp.metadata.get(): string
```
Returns the metadata as a readable string. Example: `"scribble v1.0 by devdeczin"`.

---

## i/o

```nim
sharp.print(text: string)
```
Prints to stdout. If metadata is set, prefixes with `[blade_name]`.

```nim
sharp.error(text: string)
```
Prints to stderr with `not fine.` prefix.

```nim
sharp.input(prompt: string): string
```
Reads a line from stdin. Prints `prompt` before reading if provided.

```nim
sharp.args(): seq[string]
```
Returns the arguments passed to the blade after the blade name.

Example: `none blade scribble add "note"` → `bladeArgs = @["add", "note"]`

---

## cache

Each blade gets its own cache directory at `~/.none/blades/cache/`.

```nim
sharp.hasdata(): bool
```
Returns true if the blade has saved data.

```nim
sharp.savedata(data: string)
```
Saves a string to the blade cache. Overwrites previous data.

```nim
sharp.loaddata(): string
```
Loads the previously saved string. Returns `""` if nothing saved.

```nim
sharp.cleardata()
```
Deletes the blade cache.

```nim
sharp.cachepath(): string
```
Returns the full path to the blade cache directory.

---

## environment

```nim
sharp.env(key: string): string
```
Reads an environment variable. Returns `""` if not set.

```nim
sharp.env(key, default: string): string
```
Reads an environment variable with a fallback value.

```nim
sharp.homepath(): string
```
Returns `~/.none/`.

```nim
sharp.bladepath(): string
```
Returns the directory where the blade file lives.

---

## none communication

```nim
sharp.call(cmd: string)
```
Sends a command to the none host process via stdout using the `__NONE__:` protocol.

```nim
sharp.log(msg: string)
```
Writes a log message to stderr without polluting stdout. Useful for debug.

---

## writing a blade

A minimal blade looks like this:

```nim
# hello.nim
sharp.init()
sharp.metadata.details("hello", "0.000...", "you")

sharp.print("fine.")
```

A blade that uses args and cache:

```nim
# counter.nim
sharp.init()
sharp.metadata.details("counter", "0.000...", "you")

let bladeArgs = sharp.args()

var count = 0
if sharp.hasdata():
  count = parseInt(sharp.loaddata())

if bladeArgs.len > 0 and bladeArgs[0] == "reset":
  sharp.savedata("0")
  sharp.print("fine. counter reset.")
  sharp.exit(0)

count += 1
sharp.savedata($count)
sharp.print("count: " & $count)
```

---

## what blades cannot do

For safety, the following calls are blocked by the `sharpness` compiler and will prevent the blade from running:

- `removeFile`
- `removeDir`
- `execCmd`
- `execShellCmd`
- `staticExec`
- `gorgeEx`

If your blade needs any of these, it's doing too much and probably shouldn't be a blade.

---

## installing a blade

```
none blade install myblade.nim
```

After installing, run from anywhere:

```
none blade myblade
```

---

*sharp is part of none: a (suspiciously) versatile pocket knife (for terminals)*