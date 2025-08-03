// src/hyperswarm-manager.js
const Hyperswarm = require('hyperswarm')
const b4a = require('b4a')
const Protomux = require('protomux')

let swarm = null
const protocolHandlers = new Map()
let connections = []

async function initializeHyperswarm(keyPair) {
  if (swarm) {
    console.warn('Hyperswarm already initialized.')
    return swarm
  }
  try {
    swarm = new Hyperswarm({ keyPair: keyPair })
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
  connections.push(mux)

  // Call all registered protocol handlers for this new connection
  for (const handler of protocolHandlers.values()) {
    handler(mux, peerPublicKey)
  }

  conn.once('close', () => {
    connections = connections.filter(m => m !== mux)
    console.log(
      'Connection closed with peer:',
      peerPublicKey,
      '. Remaining connections:',
      connections.length
    )
  })

  conn.on('error', (e) => console.log(`Connection error with peer ${peerPublicKey}: ${e}`))
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
    swarm.joinPeer(b4a.from(peerPublicKey, 'base64'))
    console.log('Attempting to join peer:', peerPublicKey)
  } catch (error) {
    console.error('Error joining peer:', error)
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
  getSwarm,
  registerProtocol,
  connections // Expose connections for sending data
}
