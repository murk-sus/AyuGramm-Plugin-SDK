// Tests of the VoidGram API names and of the `ayu` compatibility alias.
// Run: PRELUDE=../../prelude/prelude.swift node --test void.test.ts
import assert from "node:assert/strict";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { loadPrelude, Sandbox } from "./mock.ts";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const prelude = loadPrelude(process.env.PRELUDE ?? path.join(root, "prelude/prelude.swift"));

test("voidgram, $void and globalThis.void are the same object as ayu", () => {
  const sandbox = new Sandbox({ prelude });
  sandbox.load(`
    globalThis.sameA = voidgram === ayu;
    globalThis.sameB = globalThis.$void === ayu;
    globalThis.sameC = globalThis.void === ayu;
    globalThis.id = voidgram.pluginId;
  `);
  const context = (sandbox as any).context;
  assert.equal(context.sameA, true);
  assert.equal(context.sameB, true);
  assert.equal(context.sameC, true);
  assert.equal(context.id, "test-plugin");
  sandbox.dispose();
});

test("a plugin written with the voidgram names works like the ayu one", () => {
  const hooks = new Sandbox({ prelude });
  hooks.load(`
    voidgram.hooks.before(voidgram.hooks.points.outgoingText, (text) => text + '!');
  `);
  assert.equal(hooks.send("hello"), "hello!");
  hooks.dispose();

  const commands = new Sandbox({ prelude });
  commands.load(`voidgram.commands.register('vcmd', 'Void command', () => 'from void');`);
  assert.equal(commands.send(".vcmd"), "from void");
  commands.dispose();
});

test("legacy ayu plugins keep working next to voidgram plugins", () => {
  const sandbox = new Sandbox({ prelude });
  sandbox.load(`ayu.hooks.before(ayu.hooks.points.outgoingText, (text) => text + '?');`);
  assert.equal(sandbox.send("still here"), "still here?");
  sandbox.dispose();
});

test("VoidGram extensions of the API share storage and settings", () => {
  const sandbox = new Sandbox({ prelude });
  sandbox.load(`
    voidgram.storage.set('k', 'v');
    globalThis.readBack = ayu.storage.get('k');
  `);
  assert.equal((sandbox as any).context.readBack, "v");
  sandbox.dispose();
});

test("capabilities, resources and the accessibility/appearance views answer", () => {
  const sandbox = new Sandbox({ prelude, responders: {
    "sdk.capabilities": () => ({ value: ["ui.alert", "messages.send"] }),
    "plugin.resources": () => ({ value: { id: "test-plugin", thermalState: "nominal" } }),
    "accessibility.info": () => ({ value: { voiceOver: false } }),
    "appearance.info": () => ({ value: { dark: true } })
  } });
  sandbox.load(`
    globalThis.caps = voidgram.sdk.capabilities();
    globalThis.res = voidgram.plugin.resources();
    globalThis.a11y = voidgram.accessibility.info();
    globalThis.look = voidgram.appearance.info();
  `);
  const context = (sandbox as any).context;
  assert.deepEqual([...context.caps], ["ui.alert", "messages.send"]);
  assert.equal(context.res.thermalState, "nominal");
  assert.equal(context.a11y.voiceOver, false);
  assert.equal(context.look.dark, true);
  sandbox.dispose();
});

test("events.off silences one listener and leaves the others", () => {
  const sandbox = new Sandbox({ prelude });
  sandbox.load(`
    globalThis.got = [];
    const first = () => globalThis.got.push('first');
    const second = () => globalThis.got.push('second');
    voidgram.on('chatOpen', first);
    voidgram.on('chatOpen', second);
    voidgram.events.off('chatOpen', first);
  `);
  sandbox.emit("chatOpen", { peerId: "1" });
  assert.deepEqual([...(sandbox as any).context.got], ["second"]);
  sandbox.dispose();
});

test("storage.transaction writes several keys in one call", () => {
  const sandbox = new Sandbox({ prelude, responders: { "storage.transaction": (args) => ({ ok: true, count: Object.keys(args.values || {}).length }) } });
  sandbox.load(`globalThis.answer = voidgram.storage.transaction({ a: '1', b: '2' });`);
  assert.equal((sandbox as any).context.answer.count, 2);
  sandbox.dispose();
});

test("chat.draft.insert and clear reach the host", () => {
  const sandbox = new Sandbox({ prelude });
  sandbox.load(`voidgram.chat.draft.insert('hello'); voidgram.chat.draft.clear();`);
  const ops = (sandbox as any).calls.map((call: any) => call.op);
  assert.ok(ops.includes("chat.draft.insert"));
  assert.ok(ops.includes("chat.draft.clear"));
  sandbox.dispose();
});
