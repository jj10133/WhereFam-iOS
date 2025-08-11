//
//  Members.swift
//  App
//
//  Created by joker on 2025-01-15.
//

import Foundation

struct People: Codable, Identifiable {
    var id: String
    var name: String?
    var image: Data?
    var latitude: Double?
    var longitude: Double?
}
