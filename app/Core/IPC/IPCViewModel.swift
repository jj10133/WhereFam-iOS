//
//  BareIPC.swift
//  App
//
//  Created by joker on 2025-01-30.
//

import Foundation
import BareKit
import SwiftData

class IPCViewModel: ObservableObject {
    var ipc: IPC?
    var modelContext: ModelContext?
    
    @Published var publicKey: String = ""
    @Published var updatedPeopleLocation: [String: LocationUpdates] = [:]
    
    @Published var link: String = ""
    
    func configure(with ipc: IPC?) {
        self.ipc = ipc
    }
    
    func readFromIPC() async {
        for await chunck in ipc! {
            processIncomingMessage(chunck)
        }
    }
    
    func writeToIPC(message: [String: Any]) async {
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
            await ipc?.write(data: data)
        } catch(let error) {
            print("Debug: Error writing to IPC: \(error.localizedDescription)")
        }
    }
    
    func processIncomingMessage(_ message: Data) {
        guard let incomingMessage = try? JSONDecoder().decode(IncomingMessage.self, from: message) else {
            print("Failed to decode incoming message")
            return
        }
        
        switch incomingMessage.action {
        case "requestPublicKey":
            handlePublicKeyRequest(incomingMessage)
        case "locationUpdate":
            handleLocationUpdate(incomingMessage)
        case "requestLink":
            handleLinkRequest(incomingMessage)
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
        
        let updatedPerson = LocationUpdates(id: newId, name: name, latitude: latitude, longitude: longitude)
        DispatchQueue.main.async {
            self.updatedPeopleLocation[newId] = updatedPerson
        }
        
        let fetchDescriptor = FetchDescriptor(
            predicate: #Predicate<People> { $0.id == newId }
        )
        
        do {
            if let person = try modelContext?.fetch(fetchDescriptor).first {
                person.name = name
                person.latitude = latitude
                person.longitude = longitude
            } else {
                modelContext?.insert(People(id: newId, name: name, latitude: latitude, longitude: longitude))
            }
            try modelContext?.save()
        } catch(let error) {
            print("Error occurred: \(error.localizedDescription)")
        }
        
        // TODO: Need to save but swiftdata is not working as expected to render the UI
        // Did try actor approach not working!! Help needed
    }
    
    private func handleLinkRequest(_ incomingMessage: IncomingMessage) {
        if let dataDictionary = incomingMessage.data.value as? [String: Any],
           let link = dataDictionary["link"] as? String {
            DispatchQueue.main.async {
                self.link = link
            }
        } else {
            print("Invalid format or missing publicKey in the data.")
        }
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

class LocationUpdates: Identifiable, ObservableObject {
    @Published var id: String
    @Published var name: String?
    @Published var latitude: Double?
    @Published var longitude: Double?
    
    init(id: String, name: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
