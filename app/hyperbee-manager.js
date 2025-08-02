const Hyperbee = require('hyperbee')
const Hypercore = require('hypercore')
const b4a = require('b4a')
const sodium = require('sodium-native')

let db = null

async function initializeHyperbee(documentsPath) {
  if (db) {
    console.warn('Hyperbee already initialized.')
    return db
  }
  try {
    const core = new Hypercore(documentsPath, { valueEncoding: 'json' })
    db = new Hyperbee(core, { keyEncoding: 'utf-8', valueEncoding: 'json' })
    await db.ready() // Ensure the database is ready
    return db
  } catch (error) {
    console.error('Error initializing Hyperbee:', error)
    throw error
  }
}

async function getOrCreateKeyPair() {
  if (!db) {
    throw new Error('Hyperbee not initialized. Call initialize Hyperbee first.')
  }

  try {
    const publicKeyEntry = await db.get('publicKey')
    const secretKeyEntry = await db.get('secretKey')

    if (publicKeyEntry && secretKeyEntry) {
      return {
        publicKey: b4a.from(publicKeyEntry.value, 'base64'),
        secretKey: b4a.from(secretKeyEntry.value, 'base64')
      }
    }

    const publicKey = b4a.alloc(32)
    const secretKey = b4a.alloc(64)
    sodium.crypto_sign_keypair(publicKey, secretKey)

    await db.put('publicKey', b4a.toString(publicKey, 'base64'))
    await db.put('secretKey', b4a.toString(secretKey, 'base64'))

    return { publicKey, secretKey }
  } catch (error) {
    console.error('Error retrieving or generating keys:', error)
    throw error
  }
}

async function getPublicKeyFromDb() {
  if (!db) {
    throw new Error('Hyperbee not initialized. Call initializeHyperbee first.')
  }
  const publicKeyBase64 = await db.get('publicKey')
  return publicKeyBase64 ? publicKeyBase64.value : null
}

module.exports = {
  initializeHyperbee,
  getOrCreateKeyPair,
  getPublicKeyFromDb
}
