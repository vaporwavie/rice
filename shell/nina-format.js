var NAMED = {
    LEFTCTRL: "Left Ctrl", RIGHTCTRL: "Right Ctrl", LEFTSHIFT: "Left Shift", RIGHTSHIFT: "Right Shift",
    LEFTALT: "Left Alt", RIGHTALT: "Right Alt", LEFTMETA: "Super", RIGHTMETA: "Right Super",
    SPACE: "Space", ENTER: "Enter", ESC: "Esc", TAB: "Tab", BACKSPACE: "Backspace",
    CAPSLOCK: "Caps Lock", NUMLOCK: "Num Lock", SCROLLLOCK: "Scroll Lock", INSERT: "Insert",
    DELETE: "Delete", HOME: "Home", END: "End", PAGEUP: "Page Up", PAGEDOWN: "Page Down",
    UP: "Up", DOWN: "Down", LEFT: "Left", RIGHT: "Right", MINUS: "-", EQUAL: "=",
    LEFTBRACE: "[", RIGHTBRACE: "]", SEMICOLON: ";", APOSTROPHE: "'", GRAVE: "`",
    BACKSLASH: "\\", COMMA: ",", DOT: ".", SLASH: "/", "102ND": "<", COMPOSE: "Menu",
    SYSRQ: "Print Screen", PAUSE: "Pause", KPENTER: "Numpad Enter", KPPLUS: "Numpad +",
    KPMINUS: "Numpad -", KPASTERISK: "Numpad *", KPSLASH: "Numpad /", KPDOT: "Numpad ."
}

var MODELS = {
    "parakeet-tdt-0.6b-v3": "Parakeet TDT 0.6B v3",
    "nemotron-3.5-asr-streaming-0.6b": "Nemotron 3.5 ASR 0.6B",
    "parakeet-unified-en-0.6b": "Parakeet Unified EN 0.6B",
    "canary-1b-v2": "Canary 1B v2",
    "cohere-transcribe-03-2026": "Cohere Transcribe"
}

var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

// Mirrors key_label in Nina's src/ui/keys.rs so the bar names the hotkey the way the app does.
function keyLabel(name) {
    var raw = name.indexOf("KEY_") === 0 ? name.slice(4) : name
    if (NAMED[raw]) return NAMED[raw]
    if (raw.indexOf("KP") === 0) return "Numpad " + keyLabel(raw.slice(2))
    if (raw.length <= 3 && /^[A-Z0-9]+$/.test(raw)) return raw
    return raw.split("_").map(function(word) {
        return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
    }).join(" ")
}

function comboLabel(keys) {
    if (!Array.isArray(keys) || keys.length === 0) return "Not set"
    return keys.map(keyLabel).join("+")
}

function modelName(id) {
    if (!id) return "None"
    return MODELS[id] || id
}

function languageLabel(code) {
    return code ? String(code).toUpperCase() : "Any"
}

// Only the fields the bar shows, so API keys in the same file never reach a QML property.
function settingsSummary(text) {
    var raw = JSON.parse(text)
    var { active_model: model = "", language = null, hotkey = [], filter_fillers: fillers = true } = raw || {}
    return {
        model: typeof model === "string" ? model : "",
        language: typeof language === "string" ? language : "",
        hotkey: Array.isArray(hotkey) ? hotkey.filter(function(k) { return typeof k === "string" }) : [],
        fillers: fillers !== false
    }
}

// history.jsonl, newest first, unreadable lines skipped like Nina's own loader does.
function parseHistory(text) {
    var entries = []
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue
        try {
            var entry = JSON.parse(line)
            if (typeof entry.id !== "number" || typeof entry.text !== "string" || typeof entry.created_at !== "number") continue
            entries.push({ id: entry.id, text: entry.text, createdAt: entry.created_at,
                           audioMs: Number(entry.audio_ms) || 0 })
        } catch (e) {
        }
    }
    entries.sort(function(a, b) { return b.createdAt - a.createdAt || b.id - a.id })
    return entries
}

function pad(n) { return n < 10 ? "0" + n : String(n) }

function when(ms, nowMs) {
    var date = new Date(ms)
    var now = new Date(nowMs)
    var time = pad(date.getHours()) + ":" + pad(date.getMinutes())
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
    var day = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime()
    if (day === today) return "Today " + time
    if (day === today - 86400000) return "Yesterday " + time
    var label = MONTHS[date.getMonth()] + " " + date.getDate()
    if (date.getFullYear() !== now.getFullYear()) label += " " + date.getFullYear()
    return label + " " + time
}

function duration(ms) {
    var seconds = Math.round(ms / 1000)
    if (seconds < 60) return seconds + "s"
    var minutes = Math.floor(seconds / 60)
    if (minutes < 60) return minutes + "m " + pad(seconds % 60) + "s"
    return Math.floor(minutes / 60) + "h " + pad(minutes % 60) + "m"
}

function todayStats(entries, nowMs) {
    var now = new Date(nowMs)
    var start = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
    var takes = 0
    var audio = 0
    var words = 0
    for (var i = 0; i < entries.length; i++) {
        if (entries[i].createdAt < start) continue
        takes++
        audio += entries[i].audioMs
        words += entries[i].text.split(/\s+/).filter(function(w) { return w !== "" }).length
    }
    return { takes: takes, audio: audio, words: words }
}

function matches(entry, query) {
    var needle = String(query || "").trim().toLowerCase()
    return needle === "" || entry.text.toLowerCase().indexOf(needle) >= 0
}
