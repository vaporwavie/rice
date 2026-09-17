import test from "node:test"
import assert from "node:assert/strict"
import { isLive, parseFeed, upcoming, nextToday, remaining, dayLabel, groupByDay } from "../calendar-feed.mjs"

const at = (day, hours, minutes = 0) => new Date(2026, 8, day, hours, minutes).getTime()
const now = at(17, 10)
const feed = events => JSON.stringify({ events, updatedAt: now - 1000 })

test("parseFeed sorts valid events and drops malformed ones", () => {
    const events = parseFeed(feed([
        { title: "Later", startsAt: at(17, 15) },
        { title: "", startsAt: at(17, 11) },
        { title: "No start" },
        null,
        { title: "Sooner", startsAt: at(17, 11), remaining: "in 1h" },
    ]), now)
    assert.deepEqual(events, [
        { title: "Sooner", startsAt: at(17, 11) },
        { title: "Later", startsAt: at(17, 15) },
    ])
})

test("parseFeed hides a feed the app stopped refreshing", () => {
    const stale = JSON.stringify({ events: [{ title: "Standup", startsAt: at(17, 11) }], updatedAt: now - 91000 })
    assert.deepEqual(parseFeed(stale, now), [])
})

test("isLive follows the feed's heartbeat", () => {
    assert.equal(isLive(feed([]), now), true)
    assert.equal(isLive(JSON.stringify({ events: [], updatedAt: now - 91000 }), now), false)
    assert.equal(isLive("", now), false)
})

test("parseFeed survives garbage", () => {
    assert.deepEqual(parseFeed("", now), [])
    assert.deepEqual(parseFeed("{", now), [])
    assert.deepEqual(parseFeed("null", now), [])
    assert.deepEqual(parseFeed(JSON.stringify({ updatedAt: now }), now), [])
})

test("upcoming drops events that already started", () => {
    const events = [{ title: "Past", startsAt: at(17, 9) }, { title: "Next", startsAt: at(17, 11) }]
    assert.deepEqual(upcoming(events, now).map(event => event.title), ["Next"])
})

test("nextToday stops at local midnight", () => {
    const tomorrow = [{ title: "Tomorrow", startsAt: at(18, 9) }]
    assert.equal(nextToday(tomorrow, now), null)
    const lateToday = [{ title: "Late", startsAt: at(17, 23, 59) }, ...tomorrow]
    assert.equal(nextToday(lateToday, now).title, "Late")
    assert.equal(nextToday([{ title: "Past", startsAt: at(17, 9) }], now), null)
})

test("remaining matches the app's countdown wording", () => {
    assert.equal(remaining(now, now), "now")
    assert.equal(remaining(now + 30000, now), "in 1 min")
    assert.equal(remaining(at(17, 10, 12), now), "in 12 min")
    assert.equal(remaining(at(17, 11), now), "in 1h")
    assert.equal(remaining(at(17, 12, 5), now), "in 2h 5m")
    assert.equal(remaining(at(18, 10), now), "in 1d")
    assert.equal(remaining(at(19, 13, 30), now), "in 2d 3h")
})

test("dayLabel names today and tomorrow only", () => {
    assert.equal(dayLabel(at(17, 23), now), "Today")
    assert.equal(dayLabel(at(18, 0), now), "Tomorrow")
    assert.equal(dayLabel(at(19, 9), now), "")
})

test("groupByDay keeps order and splits on the local day", () => {
    const groups = groupByDay([
        { title: "A", startsAt: at(17, 11) },
        { title: "B", startsAt: at(17, 15) },
        { title: "C", startsAt: at(18, 9) },
    ], now)
    assert.deepEqual(groups.map(group => [group.label, group.events.map(event => event.title)]), [
        ["Today", ["A", "B"]],
        ["Tomorrow", ["C"]],
    ])
})
