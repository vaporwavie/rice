import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const context = vm.createContext({})
vm.runInContext(readFileSync(new URL("../group-dots.js", import.meta.url), "utf8"), context)
const indicators = (clients, monitor) => JSON.parse(JSON.stringify(context.indicators(clients, monitor)))
const monitor = { id: 1, x: 1920, y: -200, activeWorkspace: { id: 1 }, specialWorkspace: { id: 0 } }
const client = {
    address: "b", grouped: ["a", "b", "c"], monitor: 1,
    workspace: { id: 1 },
    visible: true, mapped: true, hidden: false, fullscreen: 0,
    at: [2020, -100], size: [800, 600]
}

test("anchors dots eight pixels from the upper-right edge in monitor-local coordinates", () => {
    assert.deepEqual(indicators([client], monitor), [{ count: 3, active: 1, apps: [
        { address: "a", appId: "" }, { address: "b", appId: "" }, { address: "c", appId: "" }
    ], x: 892, y: 108 }])
    assert.equal(indicators([{ ...client, address: "c" }], monitor)[0].active, 2)
    assert.equal(indicators([{ ...client, size: [1000, 600] }], monitor)[0].x, 1092)
    assert.equal(indicators([{ ...client, grouped: ["a", "b", "c", "d"] }], monitor)[0].x, 892)
})

test("resolves app icons in group order including inactive and missing members", () => {
    const members = [
        { ...client, class: "google-chrome" },
        { ...client, address: "a", visible: false, class: "", initialClass: "kitty" }
    ]
    assert.deepEqual(indicators(members, monitor)[0].apps, [
        { address: "a", appId: "kitty" },
        { address: "b", appId: "google-chrome" },
        { address: "c", appId: "" }
    ])
})

test("omits inactive members, other monitors, single windows and fullscreen windows", () => {
    for (const change of [
        { visible: false }, { mapped: false }, { hidden: true },
        { fullscreen: 2 }, { monitor: 0 }, { grouped: ["b"] }, { grouped: [] }
    ]) assert.deepEqual(indicators([{ ...client, ...change }], monitor), [])
    assert.deepEqual(indicators([client], null), [])
})

test("hides a visible group on other workspaces and restores it when switching back", () => {
    assert.equal(indicators([client], monitor).length, 1)
    assert.deepEqual(indicators([client], { ...monitor, activeWorkspace: { id: 3 } }), [])
    assert.equal(indicators([client], monitor).length, 1)
    assert.deepEqual(indicators([{ ...client, workspace: undefined }], monitor), [])
    assert.deepEqual(indicators([client], { ...monitor, activeWorkspace: undefined }), [])
})

test("shows special-workspace groups only while their workspace is open", () => {
    const special = { ...client, workspace: { id: -99 } }
    const open = { ...monitor, specialWorkspace: { id: -99 } }
    assert.deepEqual(indicators([special], monitor), [])
    assert.equal(indicators([special], open).length, 1)
    assert.deepEqual(indicators([client], open), [])
    assert.deepEqual(indicators([special], { ...open, id: 2 }), [])
})
