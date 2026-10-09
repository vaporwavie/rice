import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const context = vm.createContext({})
vm.runInContext(readFileSync(new URL("../groups.js", import.meta.url), "utf8"), context)
const focusedGroup = clients => JSON.parse(JSON.stringify(context.focusedGroup(clients)))
const client = { address: "b", grouped: ["a", "b", "c"], focusHistoryID: 0, class: "google-chrome" }

test("lists the focused group's apps in group order with the active index", () => {
    const members = [client, { address: "a", grouped: ["a", "b", "c"], focusHistoryID: 3, class: "", initialClass: "kitty" }]
    assert.deepEqual(focusedGroup(members), { active: 1, apps: [
        { address: "a", appId: "kitty" },
        { address: "b", appId: "google-chrome" },
        { address: "c", appId: "" }
    ] })
})

test("returns nothing unless the focused window is in a group of two or more", () => {
    assert.equal(focusedGroup([]), null)
    assert.equal(focusedGroup([{ ...client, focusHistoryID: 1 }]), null)
    assert.equal(focusedGroup([{ ...client, grouped: ["b"] }]), null)
    assert.equal(focusedGroup([{ ...client, grouped: [] }]), null)
    assert.equal(focusedGroup([{ ...client, focusHistoryID: 1 }, { address: "z", grouped: [], focusHistoryID: 0 }]), null)
})
