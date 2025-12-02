//
//  ProtocolModels.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import Foundation

struct ProtocolResponse: Codable {
    let competitionName: String
    let competitionDate: String
    let location: String
    let disciplines: [Discipline]
    
    init(competitionName: String, competitionDate: String, location: String, disciplines: [Discipline]) {
        self.competitionName = competitionName
        self.competitionDate = competitionDate
        self.location = location
        self.disciplines = disciplines
    }
    
    enum CodingKeys: String, CodingKey {
        case competitionName = "competition_name"
        case competitionDate = "competition_date"
        case location
        case disciplines
    }
}

struct Discipline: Codable, Identifiable {
    let id = UUID()
    let disciplineName: String
    let description: String
    let ageCategories: [AgeCategory]
    
    init(disciplineName: String, description: String, ageCategories: [AgeCategory]) {
        self.disciplineName = disciplineName
        self.description = description
        self.ageCategories = ageCategories
    }
    
    enum CodingKeys: String, CodingKey {
        case disciplineName = "discipline_name"
        case description
        case ageCategories = "age_categories"
    }
}

struct AgeCategory: Codable, Identifiable {
    let id = UUID()
    let categoryName: String
    let genders: [Gender]
    
    init(categoryName: String, genders: [Gender]) {
        self.categoryName = categoryName
        self.genders = genders
    }
    
    enum CodingKeys: String, CodingKey {
        case categoryName = "category_name"
        case genders
    }
}

struct Gender: Codable, Identifiable {
    let id = UUID()
    let gender: String
    let heats: [[Participant?]]
    
    // Обычный инициализатор для создания вручную
    init(gender: String, heats: [[Participant?]]) {
        self.gender = gender
        self.heats = heats
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gender = try container.decode(String.self, forKey: .gender)
        
        // Кастомное декодирование heats для обработки null значений
        var heatsArray: [[Participant?]] = []
        var heatsContainer = try container.nestedUnkeyedContainer(forKey: .heats)
        
        while !heatsContainer.isAtEnd {
            var heatArray: [Participant?] = []
            var heatContainer = try heatsContainer.nestedUnkeyedContainer()
            
            while !heatContainer.isAtEnd {
                if let participant = try? heatContainer.decode(Participant.self) {
                    heatArray.append(participant)
                } else {
                    // Пропускаем null значения
                    _ = try? heatContainer.decodeNil()
                    heatArray.append(nil)
                }
            }
            
            heatsArray.append(heatArray)
        }
        
        heats = heatsArray
    }
    
    enum CodingKeys: String, CodingKey {
        case gender
        case heats
    }
}

struct Participant: Codable, Identifiable {
    let id: UUID
    let fullName: String
    let gender: String
    let dateOfBirth: String
    let club: String
    let applicationTime: String
    let teamName: String?
    
    init(fullName: String, gender: String, dateOfBirth: String, club: String, applicationTime: String, teamName: String?) {
        self.fullName = fullName
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.club = club
        self.applicationTime = applicationTime
        self.teamName = teamName
        
        // Генерируем стабильный UUID на основе данных участника
        self.id = Participant.generateStableUUID(
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            club: club
        )
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Декодируем все поля
        self.fullName = try container.decode(String.self, forKey: .fullName)
        self.gender = try container.decode(String.self, forKey: .gender)
        self.dateOfBirth = try container.decode(String.self, forKey: .dateOfBirth)
        self.club = try container.decode(String.self, forKey: .club)
        self.applicationTime = try container.decode(String.self, forKey: .applicationTime)
        self.teamName = try? container.decode(String.self, forKey: .teamName)
        
        // Пытаемся декодировать ID, если он есть (из локального хранилища)
        if let savedId = try? container.decode(UUID.self, forKey: .id) {
            self.id = savedId
            print("🔵 [Participant] Загружен сохраненный ID: \(savedId) для \(fullName)")
        } else {
            // Если ID нет (первая загрузка с сервера), генерируем стабильный UUID
            self.id = Participant.generateStableUUID(
                fullName: fullName,
                dateOfBirth: dateOfBirth,
                club: club
            )
            print("🆕 [Participant] Сгенерирован новый ID: \(self.id) для \(fullName)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Сохраняем ID для восстановления при следующей загрузке
        try container.encode(id, forKey: .id)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(gender, forKey: .gender)
        try container.encode(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(club, forKey: .club)
        try container.encode(applicationTime, forKey: .applicationTime)
        try container.encodeIfPresent(teamName, forKey: .teamName)
    }
    
    // Генерирует стабильный UUID на основе данных участника
    private static func generateStableUUID(fullName: String, dateOfBirth: String, club: String) -> UUID {
        // Создаем уникальную строку для участника
        let uniqueString = "\(fullName)|\(dateOfBirth)|\(club)"
        
        // Вычисляем хэш
        var hash: Int = 0
        for char in uniqueString.unicodeScalars {
            hash = 31 &* hash &+ Int(char.value)
        }
        
        // Преобразуем хэш в положительное число
        let absHash = abs(hash)
        
        // Создаем UUID строку из хэша
        let uuidString = String(format: "%08x-0000-5000-8000-%012x", 
                               UInt32(absHash >> 32),
                               UInt64(absHash) & 0xFFFFFFFFFFFF)
        
        return UUID(uuidString: uuidString) ?? UUID()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case gender
        case dateOfBirth = "date_of_birth"
        case club
        case applicationTime = "application_time"
        case teamName = "team_name"
    }
}

