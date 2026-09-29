import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const context = vm.createContext({})
vm.runInContext(readFileSync(new URL("../nina-format.js", import.meta.url), "utf8"), context)

test("labels hotkeys the way Nina's settings window does", () => {
    assert.equal(context.comboLabel(["KEY_RIGHTCTRL"]), "Right Ctrl")
    assert.equal(context.comboLabel(["KEY_LEFTMETA", "KEY_SPACE"]), "Super+Space")
    assert.equal(context.keyLabel("KEY_KP7"), "Numpad 7")
    assert.equal(context.keyLabel("KEY_F12"), "F12")
    assert.equal(context.keyLabel("KEY_VOLUMEUP"), "Volumeup")
    assert.equal(context.comboLabel([]), "Not set")
})

test("keeps only whitelisted settings fields", () => {
    const summary = context.settingsSummary(JSON.stringify({
        active_model: "canary-1b-v2", language: "de", hotkey: ["KEY_F9", 3],
        anthropic_api_key: "sk-secret", openai_api_key: "sk-other", filter_fillers: false
    }))
    assert.deepEqual(JSON.parse(JSON.stringify(summary)),
        { model: "canary-1b-v2", language: "de", hotkey: ["KEY_F9"], fillers: false })
    assert.ok(!JSON.stringify(summary).includes("sk-"))
    assert.equal(context.modelName("canary-1b-v2"), "Canary 1B v2")
    assert.equal(context.modelName("custom"), "custom")
    assert.equal(context.languageLabel(""), "Any")
})

test("reads history newest first and skips broken lines", () => {
    const text = [
        '{"id":1,"created_at":1000,"text":"first","audio_ms":1500,"duration_ms":10}',
        "{broken",
        '{"id":3,"created_at":3000,"text":"third","audio_ms":500,"duration_ms":10}',
        '{"id":2,"text":"no timestamp"}',
        ""
    ].join("\n")
    const entries = context.parseHistory(text)
    assert.deepEqual([...entries.map(e => e.id)], [3, 1])
    assert.equal(entries[1].audioMs, 1500)
    assert.equal(context.parseHistory("").length, 0)
})

test("formats times, durations and today's totals", () => {
    const now = new Date(2026, 8, 29, 15, 0).getTime()
    assert.equal(context.when(new Date(2026, 8, 29, 9, 5).getTime(), now), "Today 09:05")
    assert.equal(context.when(new Date(2026, 8, 28, 23, 59).getTime(), now), "Yesterday 23:59")
    assert.equal(context.when(new Date(2026, 8, 2, 7, 0).getTime(), now), "Sep 2 07:00")
    assert.equal(context.when(new Date(2025, 11, 31, 7, 0).getTime(), now), "Dec 31 2025 07:00")
    assert.equal(context.duration(4400), "4s")
    assert.equal(context.duration(125000), "2m 05s")
    const stats = context.todayStats([
        { createdAt: new Date(2026, 8, 29, 10).getTime(), audioMs: 3000, text: "one two" },
        { createdAt: new Date(2026, 8, 28, 10).getTime(), audioMs: 9000, text: "old" }
    ], now)
    assert.deepEqual(JSON.parse(JSON.stringify(stats)), { takes: 1, audio: 3000, words: 2 })
    assert.ok(context.matches({ text: "Hello World" }, " world "))
    assert.ok(!context.matches({ text: "Hello" }, "bye"))
})
