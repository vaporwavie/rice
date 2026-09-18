import test from "node:test"
import assert from "node:assert/strict"
import { isLive, parseFeed, upcoming, nextToday, remaining, dayLabel, groupByDay, eventKey, nextAlert } from "../calendar-feed.mjs"

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

test("parseFeed keeps the join label only when the app sent one", () => {
    const events = parseFeed(feed([
        { title: "Call", startsAt: at(17, 11), join: "Join Zoom meeting" },
        { title: "Focus", startsAt: at(17, 12), join: "" },
    ]), now)
    assert.deepEqual(events, [
        { title: "Call", startsAt: at(17, 11), join: "Join Zoom meeting" },
        { title: "Focus", startsAt: at(17, 12) },
    ])
})

test("nextAlert raises an event in its last minute and holds it past the start", () => {
    const call = { title: "Call", startsAt: at(17, 10, 1) }
    assert.equal(nextAlert(null, "", [call], now - 1000), null)
    assert.equal(nextAlert(null, "", [call], now), call)
    assert.equal(nextAlert(call, "", [], at(17, 10, 6)), call)
    assert.equal(nextAlert(call, "", [], at(17, 10, 6) + 1000), null)
})

test("nextAlert stays quiet after a dismissal and moves on to the next event", () => {
    const call = { title: "Call", startsAt: at(17, 10, 1) }
    const review = { title: "Review", startsAt: at(17, 10, 31) }
    assert.equal(nextAlert(call, eventKey(call), [call], now), null)
    assert.equal(nextAlert(call, eventKey(call), [], at(17, 10, 2)), null)
    assert.equal(nextAlert(call, "", [review], at(17, 10, 30)), review)
})
