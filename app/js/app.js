// src/index.js
const ipc = require('./ipc')
const hyperbeeManager = require('./hyperbee-manager')
const hyperswarmManager = require('./hyperswarm-manager')
const mapManager = require('./map-manager')

console.log('Application starting...')

// IPC Event Listeners
ipc.on('start', async (data) => {
  const documentsPath = data['path']
  try {
    await hyperbeeManager.initializeHyperbee(documentsPath)
    const keyPair = await hyperbeeManager.getOrCreateKeyPair()
    await hyperswarmManager.initializeHyperswarm(keyPair)
  } catch (error) {
    console.error('Failed to start application:', error)
  }
})

ipc.on('fetchMaps', async (data) => {
  const documentsPath = data['path']
  console.log('Received "fetchMaps" event with path:', documentsPath)
  try {
    await mapManager.getMaps(documentsPath)
  } catch (error) {
    console.error('Failed to fetch maps:', error)
  }
})

ipc.on('requestPublicKey', async () => {
  try {
    const publicKey = await hyperbeeManager.getPublicKeyFromDb()
    if (publicKey) {
      ipc.send('publicKeyResponse', { publicKey: publicKey })
    } else {
      console.warn('Public key not found in database.')
    }
  } catch (error) {
    console.error('Error requesting public key:', error)
  }
})

ipc.on('joinPeer', async (data) => {
  const peerPublicKey = data['peerPublicKey']
  console.log('Received "joinPeer" event for:', peerPublicKey)
  try {
    hyperswarmManager.joinPeer(peerPublicKey)
  } catch (error) {
    console.error('Failed to join peer:', error)
  }
})

ipc.on('locationUpdate', async (data) => {
  console.log('Received "locationUpdate" event.')
  try {
    hyperswarmManager.sendUserLocationToPeers(data)
  } catch (error) {
    console.error('Failed to send user location:', error)
  }
})
