function indicators(clients, monitor) {
    if (!monitor) return []
    return clients.filter(function(client) {
        return client.visible && client.mapped && !client.hidden && !client.fullscreen
            && client.monitor === monitor.id && client.grouped && client.grouped.length > 1
    }).map(function(client) {
        return {
            count: client.grouped.length,
            active: client.grouped.indexOf(client.address),
            apps: client.grouped.map(function(address) {
                var member = clients.find(function(candidate) { return candidate.address === address })
                return { address: address, appId: member ? (member.class || member.initialClass || "") : "" }
            }),
            x: client.at[0] - monitor.x + client.size[0] - 8,
            y: client.at[1] - monitor.y + 8
        }
    })
}
