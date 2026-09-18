import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const context = vm.createContext({})
vm.runInContext(readFileSync(new URL("../clock-format.js", import.meta.url), "utf8"), context)

test("formats every day of the month with its ordinal suffix", () => {
    const expected = [
        "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th",
        "11th", "12th", "13th", "14th", "15th", "16th", "17th", "18th", "19th", "20th",
        "21st", "22nd", "23rd", "24th", "25th", "26th", "27th", "28th", "29th", "30th", "31st"
    ]
    for (const [index, day] of expected.entries()) {
        assert.equal(context.ordinalDay(index + 1), day)
    }
})
