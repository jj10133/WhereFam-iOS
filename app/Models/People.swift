//
//  Members.swift
//  App
//
//  Created by joker on 2025-01-15.
//

import SwiftData

@Model
class People {
    @Attribute(.unique) var id: String
    var name: String?
    var image: Data?
    var latitude: Double?
    var longitude: Double?
    
    init(id: String, name: String? = nil, image: Data? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.image = image
        self.latitude = latitude
        self.longitude = longitude
    }
}
