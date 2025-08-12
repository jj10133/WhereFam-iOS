// src/location-manager.js
const c = require('compact-encoding')
const hyperswarmManager = require('./hyperswarm-manager')
const ipc = require('./ipc')

const locationChannelProtocol = 'location-updates'
const locationChannels = new Map() // Map to hold active protomux message senders

function setupLocationProtocol() {
    hyperswarmManager.registerProtocol(locationChannelProtocol, (mux, peerPublicKey) => {
        const channel = mux.createChannel({
            protocol: locationChannelProtocol,
            onopen() {
//                console.log(`Location protocol channel opened with ${peerPublicKey}.`)
            },
            onclose() {
//                console.log(`Location protocol channel closed with ${peerPublicKey}.`)
                locationChannels.delete(peerPublicKey)
            }
        })

        const locationMessage = channel.addMessage({
            encoding: c.json,
            onmessage(message) {
                // Received a location update from a peer
                ipc.send('locationUpdate', message)
            }
        })

        locationChannels.set(peerPublicKey, locationMessage)
        channel.open()
    })
}

function sendLocationToPeers(locationData) {
    const message = {
        id: locationData.id,
        name: locationData.name,
        latitude: locationData.latitude,
        longitude: locationData.longitude
    }

    for (const locationMessage of locationChannels.values()) {
        try {
            locationMessage.send(message)
        } catch (e) {
            console.error('Error sending location update via protomux:', e)
        }
    }
    console.log('Sent user location to peers via protomux.')
}

module.exports = {
    setupLocationProtocol,
    sendLocationToPeers
}
