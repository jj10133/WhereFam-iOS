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
    
    // Register the corestore replication protocol
    hyperswarmManager.registerProtocol('hypercore-replication', (mux) => {
      // Replicate the corestore over the protomux channel
      store.replicate(mux)
    })
    
    const server = new BlobServer(store, {
      token: false
    })
    await server.listen()
    console.log('BlobServer listening.')
    
    const filenameOpts = { filename: '/20250512.pmtiles' }
    
    const link = server.getLink(key, filenameOpts)
    console.log('link', link)
    
    const swarm = hyperswarmManager.getSwarm()
    const topic = Hypercore.discoveryKey(key)
      swarm.join(topic, { server: false, client: true })
  } catch (error) {
    console.error('Error getting maps:', error)
    throw error
  }
}

module.exports = {
  getMaps
}
