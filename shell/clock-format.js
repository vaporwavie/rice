function ordinalDay(day) {
    if (day >= 11 && day <= 13) return day + "th"
    var suffix = { 1: "st", 2: "nd", 3: "rd" }[day % 10] || "th"
    return day + suffix
}
