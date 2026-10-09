function focusedGroup(clients) {
    var client = clients.find(function(candidate) {
        return candidate.focusHistoryID === 0 && candidate.grouped && candidate.grouped.length > 1
    })
    if (!client) return null
    return {
        active: client.grouped.indexOf(client.address),
        apps: client.grouped.map(function(address) {
            var member = clients.find(function(candidate) { return candidate.address === address })
            return { address: address, appId: member ? (member.class || member.initialClass || "") : "" }
        })
    }
}
