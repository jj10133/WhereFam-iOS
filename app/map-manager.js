// src/map-manager.js
const Hypercore = require('hypercore')
const Corestore = require('corestore')
const BlobServer = require('hypercore-blob-server')
const b4a = require('b4a')
const { PMTILES_KEY } = require('./constants')
const hyperswarmManager = require('./hyperswarm-manager')

async function getMaps(documentsPath) {
  try {
    const key = b4a.from(PMTILES_KEY, 'hex')
    const store = new Corestore(documentsPath + '/maps')

    // Get the shared hyperswarm instance
    const mapSwarm = hyperswarmManager.getSwarm()

    // Listen for new connections on the shared swarm
    mapSwarm.on('connection', (conn) => {
      store.replicate(conn)
    })

    const server = new BlobServer(store, {
      token: false
    })
    await server.listen()
    console.log('BlobServer listening.')

    const filenameOpts = {
      filename: '/20250512.pmtiles'
    }

    const topic = Hypercore.discoveryKey(key)
    mapSwarm.join(topic)
  } catch (error) {
    console.error('Error getting maps:', error)
    throw error
  }
}

module.exports = {
  getMaps
}
