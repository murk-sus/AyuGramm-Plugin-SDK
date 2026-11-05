import tempfile
import unittest
from pathlib import Path

import convert_void


JS = """// ==AyuPlugin==
// @id demo
// @name Demo
// ==/AyuPlugin==
const keep = "ayu.in.string";
ayu.hooks.before(ayu.hooks.points.outgoingText, (text) => text + "!");
// ayu.in.comment
ayu.log(keep);
"""

PYTHON = """# ==AyuPlugin==
# @id demo_py
# ==/AyuPlugin==
@ayu.hooks.before(ayu.hooks.points.outgoing_text)
def shout(text, ctx):
    return text + "! ayu.in.string"
"""

LUA = """-- @id demo_lua
ayu.hooks.before(ayu.points.outgoing_text, function(text, ctx) return text .. "! ayu.in.string" end)
"""


class ConvertVoidTests(unittest.TestCase):
    def test_javascript_uses_voidgram_and_leaves_strings_comments(self):
        result = convert_void.convert_source(JS, "js")
        self.assertIn("voidgram.hooks.before(voidgram.hooks.points.outgoingText", result)
        self.assertIn('"ayu.in.string"', result)
        self.assertIn("// ayu.in.comment", result)
        self.assertIn("==VoidPlugin==", result)
        self.assertIn("==/VoidPlugin==", result)
        self.assertNotIn("ayu.hooks", result)

    def test_python_and_lua_use_void(self):
        python = convert_void.convert_source(PYTHON, "py")
        self.assertIn("@void.hooks.before(void.hooks.points.outgoing_text)", python)
        self.assertIn('"! ayu.in.string"', python)
        lua = convert_void.convert_source(LUA, "lua")
        self.assertIn("void.hooks.before(void.points.outgoing_text", lua)
        self.assertIn('"! ayu.in.string"', lua)

    def test_double_extension_stays_javascript(self):
        self.assertEqual(convert_void.language_of(Path("x.void.js")), "js")
        self.assertEqual(convert_void.language_of(Path("x.ayupy")), "py")
        self.assertEqual(convert_void.language_of(Path("x.voidlua")), "lua")

    def test_output_name(self):
        self.assertEqual(convert_void.output_name(Path("x.ayu.js"), "js"), "x.void.js")
        self.assertEqual(convert_void.output_name(Path("x.py"), "py"), "x.void.py")

    def test_convert_writes_a_new_file(self):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / "demo.ayu.js"
            source.write_text(JS, encoding="utf-8")
            destination = Path(folder) / "demo.void.js"
            convert_void.convert(source, destination)
            self.assertIn("voidgram.hooks", destination.read_text(encoding="utf-8"))
            self.assertIn("ayu.hooks", source.read_text(encoding="utf-8"))

    def test_wasm_is_refused(self):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / "demo.wasm"
            source.write_bytes(b"\x00asm\x01\x00\x00\x00")
            with self.assertRaises(ValueError):
                convert_void.convert(source, Path(folder) / "demo.void.wasm")


if __name__ == "__main__":
    unittest.main()
