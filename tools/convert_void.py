"""Convert an AyuGram-era plugin file to the VoidGram API names.

The app keeps the old names working, so this tool is for authors who want to
publish a plugin in the new style. It only rewrites code, never string
literals or comments, and it never changes the plugin's logic.

    python3 tools/convert_void.py plugin.ayu.js plugin.void.js
    python3 tools/convert_void.py plugin.ayupy plugin.voidpy

JavaScript cannot use `void` as a bare identifier (it is a reserved word), so
JavaScript plugins get `voidgram` (the same object as `ayu` and
`globalThis.void`). Python and Lua get `void`.
"""
import argparse
import re
import sys
from pathlib import Path

LANGUAGES = {
    "js": "js",
    "ayujs": "js",
    "voidjs": "js",
    "py": "py",
    "ayupy": "py",
    "voidpy": "py",
    "lua": "lua",
    "ayulua": "lua",
    "voidlua": "lua",
}

# The namespace a language uses after the rename.
NAMESPACES = {"js": "voidgram", "py": "void", "lua": "void"}

IDENTIFIER = re.compile(r"\bayu(?=\s*(?:\.|\[))")


def language_of(path: Path) -> str:
    """`plugin.ayu.js` is JavaScript; `.ayujs` is JavaScript too."""
    suffix = path.suffix.lower().lstrip(".")
    if suffix in LANGUAGES:
        return LANGUAGES[suffix]
    # A double extension such as `.void.js` is JavaScript as well.
    parts = path.name.lower().split(".")
    if len(parts) >= 3 and parts[-2] in ("ayu", "void"):
        return LANGUAGES.get(parts[-2] + parts[-1], LANGUAGES.get(parts[-1], ""))
    raise ValueError(f"Unknown plugin extension: {path.suffix}")


def output_name(path: Path, language: str) -> str:
    """The new file keeps the id and gets the `void` spelling of the language."""
    stem = path.name
    for old, new in ((".ayu.js", ".void.js"), (".ayu.py", ".void.py"), (".ayu.lua", ".void.lua"),
                     (".ayujs", ".voidjs"), (".ayupy", ".voidpy"), (".ayulua", ".voidlua"),
                     (".js", ".void.js"), (".py", ".void.py"), (".lua", ".void.lua")):
        if stem.lower().endswith(old):
            return stem[: -len(old)] + new
    return stem + {"js": ".void.js", "py": ".void.py", "lua": ".void.lua"}[language]


def _scan(source: str, language: str):
    """Yield (start, end, is_code) chunks; strings and comments are not code."""
    i = 0
    n = len(source)
    code_start = 0

    while i < n:
        ch = source[i]
        end = None
        if language == "py" and ch == "#":
            end = source.find("\n", i)
            end = n if end < 0 else end
        elif language == "lua" and source.startswith("--", i):
            if source.startswith("--[[", i):
                found = source.find("]]", i + 4)
                end = n if found < 0 else found + 2
            else:
                found = source.find("\n", i)
                end = n if found < 0 else found
        elif language == "js" and source.startswith("//", i):
            found = source.find("\n", i)
            end = n if found < 0 else found
        elif language == "js" and source.startswith("/*", i):
            found = source.find("*/", i + 2)
            end = n if found < 0 else found + 2
        elif ch in ("'", '"', "`"):
            quote = ch
            triple = language != "js" and source.startswith(ch * 3, i)
            if triple:
                found = source.find(ch * 3, i + 3)
                end = n if found < 0 else found + 3
            else:
                j = i + 1
                while j < n:
                    if source[j] == "\\":
                        j += 2
                        continue
                    if source[j] == quote:
                        j += 1
                        break
                    j += 1
                end = min(j, n)
        if end is None:
            i += 1
            continue
        if i > code_start:
            yield (code_start, i, True)
        yield (i, end, False)
        i = end
        code_start = i
    if code_start < n:
        yield (code_start, n, True)


def convert_source(source: str, language: str) -> str:
    """Rewrite `ayu.` outside strings and comments, and the header marker."""
    namespace = NAMESPACES[language]
    pieces = []
    for start, end, is_code in _scan(source, language):
        if is_code and end > start:
            pieces.append(IDENTIFIER.sub(namespace, source[start:end]))
        else:
            pieces.append(source[start:end])
    text = "".join(pieces)
    return text.replace("==AyuPlugin==", "==VoidPlugin==").replace("==/AyuPlugin==", "==/VoidPlugin==")


def convert(source: Path, destination: Path) -> Path:
    if source.resolve() == destination.resolve():
        raise ValueError("Keep the original plugin; choose a different output path")
    if not 0 < source.stat().st_size <= 512 * 1024:
        raise ValueError("Plugin size must be between 1 byte and 512 KB")
    if source.read_bytes().startswith(b"\x00asm"):
        raise ValueError("WebAssembly plugins cannot be rewritten; build them with void_alloc/void_dispatch or keep ayu.host")
    language = language_of(source)
    text = source.read_text(encoding="utf-8")
    converted = convert_source(text, language)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(converted, encoding="utf-8")
    return destination


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path, nargs="?")
    args = parser.parse_args(argv)
    destination = args.destination or Path(output_name(args.source, language_of(args.source)))
    try:
        convert(args.source, destination)
    except (OSError, UnicodeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    print(destination)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
