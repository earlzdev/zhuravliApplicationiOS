//
//  Competition.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import Foundation

struct Competition: Codable, Identifiable {
    let id: String
    let description: String
    let location: String
    let date: String
    let isActive: Bool
    let registeredCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case location
        case date
        case isActive = "is_active"
        case registeredCount = "registered_count"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: self.date) {
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: date)
        }
        return date
    }
}

