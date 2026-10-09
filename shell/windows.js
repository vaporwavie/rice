function appId(client) {
    return client ? (client["class"] || client.initialClass || "") : ""
}

function workspaceWindows(clients, workspace) {
    var targets = clients
        .filter(function(client) {
            return client.mapped && !client.hidden && client.workspace && client.workspace.id === workspace
        })
        .sort(function(a, b) { return parseInt(a.stableId, 16) - parseInt(b.stableId, 16) })
    // Alt+Tab steps through these in stable id order, so next is the one after the focused window.
    var active = targets.findIndex(function(client) { return client.focusHistoryID === 0 })
    var next = active === -1 || targets.length < 2 ? -1 : (active + 1) % targets.length
    return targets.map(function(client, index) {
        var grouped = client.grouped || []
        return {
            address: client.address,
            appId: appId(client),
            title: client.title || "",
            active: index === active,
            next: index === next,
            members: grouped.length < 2 ? [] : grouped.map(function(address) {
                var member = clients.find(function(candidate) { return candidate.address === address })
                return { address: address, appId: appId(member), title: member ? member.title || "" : "", shown: address === client.address }
            })
        }
    })
}
