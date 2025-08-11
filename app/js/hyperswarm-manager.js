// src/hyperswarm-manager.js
const Hyperswarm = require('hyperswarm')
const b4a = require('b4a')
const Protomux = require('protomux')
const hyperbeeManager = require('./hyperbee-manager.js')
const ipc = require('./ipc')

let swarm = null
const protocolHandlers = new Map()
let connections = []

async function initializeHyperswarm(keyPair) {
    if (swarm) {
        console.warn('Hyperswarm already initialized.')
        return swarm
    }
    try {
        swarm = new Hyperswarm({
            keyPair: keyPair
            // firewall: async (remotePublicKey) => {
            //     const remoteKeyBase64 = b4a.toString(remotePublicKey, 'base64')
            //     const knownPeers = await hyperbeeManager.getKnownPeers()
            //     const isKnown = knownPeers.has(remoteKeyBase64)
            //
            //     if (!isKnown) {
            //         console.log(`Rejecting connection from unknown peer: ${remoteKeyBase64}`);
            //     }
            //
            //     // Return false to allow the connection, true to reject it
            //     return !isKnown;
            // }
        })

        const knownPeers = await hyperbeeManager.getKnownPeers()

        for (const peerKey of knownPeers) {
            joinPeer(peerKey)
        }
        swarm.listen()
        swarm.on('connection', handleConnection)
        console.log('Hyperswarm initialized and listening.')
        return swarm
    } catch (error) {
        console.error('Error initializing Hyperswarm:', error)
        throw error
    }
}

function handleConnection(conn, info) {
    const peerPublicKey = b4a.toString(info.publicKey, 'base64')
    console.log('New connection established with peer:', peerPublicKey)

    // Use protomux to multiplex on this connection
    const mux = new Protomux(conn)
    connections.push({ mux, publicKey: peerPublicKey })

    // Call all registered protocol handlers for this new connection
    for (const handler of protocolHandlers.values()) {
        handler(mux, peerPublicKey)
    }

    conn.on('close', () => {
        connections = connections.filter((m) => m !== mux)
        ipc.send('peerDisconnected', { peerKey: peerPublicKey })
        console.log("Deleted peer ID" + peerPublicKey)
        console.log(
            'Connection closed with peer:',
            peerPublicKey,
            '. Remaining connections:',
            connections.length
        )
    })

    conn.on('error', (e) =>
        console.log(`Connection error with peer ${peerPublicKey}: ${e}`)
    )
}

function closeConnection(peerPublicKey) {
    const connectionIndex = connections.findIndex(
        (c) => c.publicKey === peerPublicKey
    )
    if (connectionIndex !== -1) {
        const connection = connections[connectionIndex]
        // This will trigger the 'close' event handler, which cleans up the connections array
        connection.mux.stream.destroy()
        console.log(`Manually closed connection with peer: ${peerPublicKey}`)
    } else {
        console.log(`No active connection found for peer: ${peerPublicKey}`)
    }
}

/**
 * Registers a handler for a specific protocol.
 * The handler function will be called for every new connection.
 * @param {string} protocolName
 * @param {function(Protomux, string)} handler
 */
function registerProtocol(protocolName, handler) {
    protocolHandlers.set(protocolName, handler)
}

function joinPeer(peerPublicKey) {
    if (!swarm) {
        console.error('Hyperswarm not initialized. Cannot join peer.')
        return
    }
    try {

        const publicKeyBuffer = b4a.from(peerPublicKey, 'base64');
        swarm.joinPeer(publicKeyBuffer)
        console.log('Attempting to join peer:', peerPublicKey)
    } catch (error) {
        console.error('Error joining peer:', error)
    }
}

function leavePeer(peerPublicKey) {
    if (!swarm) {
        console.error('Hyperswarm not initialized. Cannot join peer.')
        return
    }
    try {
        swarm.leavePeer(b4a.from(peerPublicKey, 'base64'))
        console.log('Attempting to leave peer:', peerPublicKey)
    } catch (error) {
        console.error('Error leaving peer:', error)
    }
}

function getSwarm() {
    if (!swarm) {
        throw new Error('Hyperswarm is not initialized yet.')
    }
    return swarm
}

module.exports = {
    initializeHyperswarm,
    joinPeer,
    leavePeer,
    getSwarm,
    registerProtocol,
    connections,
    closeConnection
}
