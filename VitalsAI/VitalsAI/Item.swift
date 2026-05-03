//
//  Item.swift
//  VitalsAI
//
//  Created by surya ssvm on 4/24/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
