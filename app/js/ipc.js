const { IPC } = BareKit
const EventEmitter = require('bare-events')

const emitter = new EventEmitter()
let ipcBuffer = ''

IPC.setEncoding('utf8')

IPC.on('data', async (chunck) => {
  ipcBuffer += chunck

  let newLineIndex
  while ((newLineIndex = ipcBuffer.indexOf('\n')) !== -1) {
    const line = ipcBuffer.substring(0, newLineIndex).trim()
    ipcBuffer = ipcBuffer.substring(newLineIndex + 1)

    if (line.length === 0) {
      continue
    }

    try {
      const message = JSON.parse(line)
      emitter.emit(message.action, message.data)
    } catch (error) {
      console.error('Error handling IPC message: ', error)
    }
  }
})

function sendIPCMessage(action, data) {
  const message = { action, data }
  IPC.write(JSON.stringify(message) + '\n')
}

module.exports = {
  on: emitter.on.bind(emitter),
  send: sendIPCMessage
}
