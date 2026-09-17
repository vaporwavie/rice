const STALE_MS = 90000

function read(text, now) {
    let feed
    try {
        feed = JSON.parse(text)
    } catch (error) {
        return null
    }
    if (!feed || !Number.isFinite(feed.updatedAt) || now - feed.updatedAt > STALE_MS) return null
    return feed
}

export function isLive(text, now) {
    return read(text, now) !== null
}

export function parseFeed(text, now) {
    const feed = read(text, now)
    if (!feed || !Array.isArray(feed.events)) return []
    return feed.events
        .filter(event => event && typeof event.title === "string" && event.title !== "" && Number.isFinite(event.startsAt))
        .map(event => ({ title: event.title, startsAt: event.startsAt }))
        .sort((a, b) => a.startsAt - b.startsAt)
}

export function upcoming(events, now) {
    return events.filter(event => event.startsAt >= now)
}

export function nextToday(events, now) {
    const day = new Date(now)
    const midnight = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1).getTime()
    return upcoming(events, now).find(event => event.startsAt < midnight) || null
}

export function remaining(startsAt, now) {
    const minutes = Math.ceil((startsAt - now) / 60000)
    if (minutes <= 0) return "now"
    if (minutes < 60) return "in " + minutes + " min"
    const hours = Math.floor(minutes / 60)
    const rest = minutes % 60
    if (hours < 24) return "in " + hours + "h" + (rest ? " " + rest + "m" : "")
    const days = Math.floor(hours / 24)
    return "in " + days + "d" + (hours % 24 ? " " + (hours % 24) + "h" : "")
}

export function dayLabel(startsAt, now) {
    const start = new Date(startsAt)
    const today = new Date(now)
    const days = Math.round((new Date(start.getFullYear(), start.getMonth(), start.getDate())
        - new Date(today.getFullYear(), today.getMonth(), today.getDate())) / 86400000)
    if (days === 0) return "Today"
    if (days === 1) return "Tomorrow"
    return ""
}

export function groupByDay(events, now) {
    const groups = []
    for (const event of events) {
        const start = new Date(event.startsAt)
        const key = start.getFullYear() + "-" + start.getMonth() + "-" + start.getDate()
        let group = groups[groups.length - 1]
        if (!group || group.key !== key) {
            group = { key, startsAt: event.startsAt, label: dayLabel(event.startsAt, now), events: [] }
            groups.push(group)
        }
        group.events.push(event)
    }
    return groups
}
