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
    let id: UUID
    let disciplineName: String
    let description: String
    let genders: [GenderCategory]
    
    init(disciplineName: String, description: String, genders: [GenderCategory]) {
        self.disciplineName = disciplineName
        self.description = description
        self.genders = genders
        // Генерируем UUID для локального использования
        self.id = UUID()
    }
    
    // Вспомогательный инициализатор для тестовых данных с явным ID
    init(id: String, disciplineName: String, description: String, genders: [GenderCategory]) {
        self.id = UUID(uuidString: id) ?? UUID()
        self.disciplineName = disciplineName
        self.description = description
        self.genders = genders
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.disciplineName = try container.decode(String.self, forKey: .disciplineName)
        self.description = try container.decode(String.self, forKey: .description)
        self.genders = try container.decode([GenderCategory].self, forKey: .genders)
        
        // Декодируем discipline_id с сервера или используем сохраненный ID
        if let savedId = try? container.decode(UUID.self, forKey: .id) {
            self.id = savedId
        } else if let disciplineIdString = try? container.decode(String.self, forKey: .disciplineId),
                  let uuidFromServer = UUID(uuidString: disciplineIdString) {
            self.id = uuidFromServer
        } else {
            self.id = UUID()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(disciplineName, forKey: .disciplineName)
        try container.encode(description, forKey: .description)
        try container.encode(genders, forKey: .genders)
    }
    
    enum CodingKeys: String, CodingKey {
        case id // Для локального хранилища
        case disciplineId = "discipline_id" // Для декодирования с сервера
        case disciplineName = "discipline_name"
        case description
        case genders
    }
}

struct GenderCategory: Codable, Identifiable {
    let id = UUID()
    let gender: String
    let ageCategories: [AgeCategory]
    
    init(gender: String, ageCategories: [AgeCategory]) {
        self.gender = gender
        self.ageCategories = ageCategories
    }
    
    enum CodingKeys: String, CodingKey {
        case gender
        case ageCategories = "age_categories"
    }
}

struct AgeCategory: Codable, Identifiable {
    let id = UUID()
    let categoryName: String
    let heats: [[Participant?]]
    
    init(categoryName: String, heats: [[Participant?]]) {
        self.categoryName = categoryName
        self.heats = heats
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        
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
        case categoryName = "category_name"
        case heats
    }
}

// MARK: - Модель для relay результата (одна запись - одна сотка с временем)
struct RelayResultEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let distance: Int // Дистанция в метрах (0-100)
    let time: String // Время в формате mm:ss:ms
    
    init(distance: Int, time: String) {
        self.id = UUID()
        self.distance = distance
        self.time = time
    }
}

// MARK: - Модель для отправки результата на бекенд
struct FinishProtocolEntry: Codable {
    let disciplineId: String
    let disciplineType: String
    let participantId: String
    let participantName: String
    let finishTime: String?
    let meters: Int?
    let relayResults: String? // Времена для каждых 100 метров в формате "67,68,69,34" (секунды)
    
    enum CodingKeys: String, CodingKey {
        case disciplineId = "discipline_id"
        case disciplineType = "discipline_type"
        case participantId = "participant_id"
        case participantName = "participant_name"
        case finishTime = "finish_time"
        case meters
        case relayResults = "relay_results"
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
    
    // Вспомогательный инициализатор для тестовых данных с явным ID
    init(id: String, fullName: String, gender: String, dateOfBirth: String, club: String, applicationTime: String, teamName: String?) {
        self.id = UUID(uuidString: id) ?? Participant.generateStableUUID(
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            club: club
        )
        self.fullName = fullName
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.club = club
        self.applicationTime = applicationTime
        self.teamName = teamName
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
        
        // Пытаемся декодировать ID в следующем порядке:
        // 1. Из локального хранилища (поле "id" как UUID)
        if let savedId = try? container.decode(UUID.self, forKey: .id) {
            self.id = savedId
            print("🔵 [Participant] Загружен сохраненный ID: \(savedId) для \(fullName)")
        }
        // 2. С сервера (поле "participant_id" как String UUID)
        else if let participantIdString = try? container.decode(String.self, forKey: .participantId),
                let uuidFromServer = UUID(uuidString: participantIdString) {
            self.id = uuidFromServer
            print("🔵 [Participant] Загружен ID с сервера: \(uuidFromServer) для \(fullName)")
        }
        // 3. Генерируем стабильный UUID
        else {
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
        case id // Для локального хранилища
        case participantId = "participant_id" // Для декодирования с сервера
        case fullName = "full_name"
        case gender
        case dateOfBirth = "date_of_birth"
        case club
        case applicationTime = "application_time"
        case teamName = "team_name"
    }
}

