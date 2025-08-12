//
//  SQLiteManager.swift
//  WhereFam
//
//  Created by joker on 2025-08-10.
//

import Foundation
import SQLite

class SQLiteManager {
    static let shared = SQLiteManager()
    private var db: Connection!
    
    private let people = Table("people")
    private let id = SQLite.Expression<String>("id")
    private let name = SQLite.Expression<String?>("name")
    private let image = SQLite.Expression<Data?>("image")
    private let latitude = SQLite.Expression<Double?>("latitude")
    private let longitude = SQLite.Expression<Double?>("longitude")
    
    private init() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        do {
            db = try Connection("\(path)/location.sqlite3")
            try createTable()
        } catch {
            print("Error connecting or creating database: \(error)")
        }
    }
    
    private func createTable() throws {
        try db.run(people.create(ifNotExists: true) { table in
            table.column(id, primaryKey: true)
            table.column(name)
            table.column(image)
            table.column(latitude)
            table.column(longitude)
        })
    }
    
    func fetchAllPeople() -> [People] {
        var allPeople: [People] = []
        do {
            for person in try db.prepare(people) {
                let p = People(
                    id: person[id],
                    name: person[name],
                    image: person[image],
                    latitude: person[latitude],
                    longitude: person[longitude]
                )
                allPeople.append(p)
            }
        } catch {
            print("Failed to fetch all people: \(error)")
        }
        return allPeople
    }
    
    func findPerson(id: String) -> People? {
        let query = people.filter(self.id == id)
        do {
            if let person = try db.pluck(query) {
                return People(
                    id: person[self.id],
                    name: person[name],
                    image: person[image],
                    latitude: person[latitude],
                    longitude: person[longitude]
                )
            }
        } catch {
            print("Failed to find person with ID \(id): \(error)")
        }
        return nil
    }
    
    func savePerson(_ person: People) {
        guard !person.id.isEmpty else {
            print("Error: Attempt to save person with empty ID.")
            return
        }
        let upsert = people.insert(or: .replace,
                                   id <- person.id,
                                   name <- person.name,
                                   image <- person.image,
                                   latitude <- person.latitude,
                                   longitude <- person.longitude
        )
        do {
            try db.run(upsert)
        } catch {
            print("Failed to save person: \(error)")
        }
    }
    
    func deletePerson(id: String) {
        let personToDelete = people.filter(self.id == id)
        do {
            if try db.run(personToDelete.delete()) > 0 {
                print("Successfully deleted person with ID: \(id)")
            } else {
                print("No person found to delete with ID: \(id)")
            }
        } catch {
            print("Failed to delete person: \(error)")
        }
    }
}
