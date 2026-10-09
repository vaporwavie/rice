import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const context = vm.createContext({})
vm.runInContext(readFileSync(new URL("../windows.js", import.meta.url), "utf8"), context)
const workspaceWindows = (clients, workspace) => JSON.parse(JSON.stringify(context.workspaceWindows(clients, workspace)))
const window = (address, stableId, extra = {}) => ({
    address, stableId, class: address, title: address + " title", mapped: true, hidden: false,
    grouped: [], focusHistoryID: 5, workspace: { id: 1 }, ...extra
})

test("lists the workspace's cycle targets in stable id order, marking active and next", () => {
    const clients = [
        window("c", "1a"),
        window("a", "9", { focusHistoryID: 0 }),
        window("b", "10"),
        window("elsewhere", "2", { workspace: { id: 2 } }),
        window("unmapped", "3", { mapped: false })
    ]
    assert.deepEqual(workspaceWindows(clients, 1).map(({ address, active, next }) => [address, active, next]), [
        ["a", true, false],
        ["b", false, true],
        ["c", false, false]
    ])
})

test("wraps next to the first window when the last one is active", () => {
    const clients = [window("a", "1"), window("b", "2", { focusHistoryID: 0 })]
    assert.deepEqual(workspaceWindows(clients, 1).map(({ next }) => next), [true, false])
})

test("marks no next when the workspace has one window or none is focused", () => {
    assert.deepEqual(workspaceWindows([window("a", "1", { focusHistoryID: 0 })], 1).map(({ next }) => next), [false])
    assert.deepEqual(workspaceWindows([window("a", "1"), window("b", "2")], 1).map(({ active, next }) => [active, next]), [[false, false], [false, false]])
})

test("folds hidden group members into the visible group head in group order", () => {
    const grouped = ["g2", "g1"]
    const clients = [
        window("g1", "1", { grouped, hidden: true, class: "", initialClass: "kitty" }),
        window("g2", "2", { grouped, focusHistoryID: 0 }),
        window("solo", "3")
    ]
    assert.deepEqual(workspaceWindows(clients, 1), [
        { address: "g2", appId: "g2", title: "g2 title", active: true, next: false, members: [
            { address: "g2", appId: "g2", title: "g2 title", shown: true },
            { address: "g1", appId: "kitty", title: "g1 title", shown: false }
        ] },
        { address: "solo", appId: "solo", title: "solo title", active: false, next: true, members: [] }
    ])
})

test("returns nothing for an empty or unknown workspace", () => {
    assert.deepEqual(workspaceWindows([], 1), [])
    assert.deepEqual(workspaceWindows([window("a", "1")], 7), [])
})
