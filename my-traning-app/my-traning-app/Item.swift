//
//  Item.swift
//  my-traning-app
//
//  Created by HiroakiSaito on 2025/08/31.
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
