//
//  BareIPC.swift
//  App
//
//  Created by joker on 2025-01-30.
//

import Foundation
import BareKit

class IPCViewModel: ObservableObject {
    var ipc: IPC?
    
    @Published var publicKey: String = ""
    @Published var people: [People] = []
    
    private var ipcBuffer = ""
    
    func configure(with ipc: IPC?) {
        self.ipc = ipc
    }
    
    func readFromIPC() async {
        guard let ipc = self.ipc else {
            print("Error: IPC object is nil, cannot read.")
            return
        }
        
        do {
            for try await chunk in ipc {
                if let chunkString = String(data: chunk, encoding: .utf8) {
                    processIncomingChunks(chunkString)
                }
            }
        } catch {
            print("Error reading from IPC: \(error.localizedDescription)")
        }
    }
    
    func writeToIPC(message: [String: Any]) async {
        guard let ipc = self.ipc else {
            print("Error: IPC object is nil, cannot read.")
            return
        }
        
        do {
            var data = try JSONSerialization.data(withJSONObject: message, options: [])
            data.append("\n".data(using: .utf8)!)
            try await ipc.write(data: data)
        } catch(let error) {
            print("Debug: Error writing to IPC: \(error.localizedDescription)")
        }
    }
    
    func processIncomingChunks(_ chunk: String) {
        ipcBuffer.append(chunk)
        
        var lines = ipcBuffer.components(separatedBy: "\n")
        
        // The last element might be an incomplete line.
        // We'll keep it in the buffer for the next chunk.
        ipcBuffer = lines.last ?? ""
        lines.removeLast()
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty {
                continue
            }
            
            guard let data = trimmedLine.data(using: .utf8) else {
                print("Failed to convert string to Data: \(trimmedLine)")
                continue
            }
            
            do {
                let incomingMessage = try JSONDecoder().decode(IncomingMessage.self, from: data)
                handleIPCMessage(incomingMessage)
            } catch {
                print("Error decoding IPC message: \(error.localizedDescription)")
                print("Message content: \(trimmedLine)")
            }
        }
    }
    
    func handleIPCMessage(_ incomingMessage: IncomingMessage) {
        switch incomingMessage.action {
        case "publicKeyResponse":
            handlePublicKeyRequest(incomingMessage)
        case "locationUpdate":
            handleLocationUpdate(incomingMessage)
        case "peerDisconnected":
            handlePeerDisconnected(incomingMessage)
        default:
            print("Unknown action: \(incomingMessage.action)")
        }
    }
    
    private func handlePublicKeyRequest(_ incomingMessage: IncomingMessage) {
        if let dataDictionary = incomingMessage.data.value as? [String: Any],
           let publicKey = dataDictionary["publicKey"] as? String {
            DispatchQueue.main.async {
                self.publicKey = publicKey
            }
        } else {
            print("Invalid format or missing publicKey in the data.")
        }
    }
    
    private func handleLocationUpdate(_ incomingMessage: IncomingMessage) {
        guard let dataDictionary = incomingMessage.data.value as? [String: Any] else {
            print("Invalid location update data.")
            return
        }
        
        guard let newId = dataDictionary["id"] as? String,
              let name = dataDictionary["name"] as? String,
              let latitude = dataDictionary["latitude"] as? Double,
              let longitude = dataDictionary["longitude"] as? Double else {
            print("Invalid person data in location update.")
            return
        }
        
        let person = People(id: newId, name: name, latitude: latitude, longitude: longitude)
        SQLiteManager.shared.savePerson(person)
        refreshPeople()
    }
    
    func refreshPeople() {
        DispatchQueue.main.async {
            self.people = []
            self.people = SQLiteManager.shared.fetchAllPeople()
        }
    }
    
    func handlePeerDisconnected(_ incomingMessage: IncomingMessage) {
        if let dataDictionary = incomingMessage.data.value as? [String: Any],
           let publicKey = dataDictionary["peerKey"] as? String {
            DispatchQueue.main.async {
                self.people.removeAll { $0.id == publicKey }
            }
            SQLiteManager.shared.deletePerson(id: publicKey)
            
        } else {
            print("Invalid format or missing publicKey in the data.")
        }
        refreshPeople()
    }
    
}


@objcMembers final class AnyCodable: NSObject, Codable {
    
    let value: Any?
    
    init(_ value: Any?) {
        self.value = value
    }
    
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if container.decodeNil() {
            self.value = nil
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value.mapValues { $0.value }
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value.map { $0.value }
        }  else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid value cannot be decoded"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let float as Float:
            try container.encode(float)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any?]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        case let encodable as Encodable:
            try encodable.encode(to: encoder)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyEncodable value cannot be encoded")
            throw EncodingError.invalidValue(value ?? "InvalidValue", context)
        }
    }
}

struct IncomingMessage: Codable {
    let action: String
    let data: AnyCodable
}
