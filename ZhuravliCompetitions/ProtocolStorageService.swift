//
//  ProtocolStorageService.swift
//  ZhuravliCompetitions
//
//  Created by AI Assistant on 23.11.2025.
//

import Foundation

/// Модель для сохранения протокола с результатами
struct SavedProtocol: Codable, Identifiable {
    let id: String // ID соревнования
    let protocolData: ProtocolResponse
    var resultTimes: [String: String] // UUID участника -> время результата (для individual)
    var relayResults: [String: [RelayResultEntry]] // UUID участника -> массив записей (для relay)
    var savedAt: Date
    
    init(id: String, protocolData: ProtocolResponse, resultTimes: [String: String] = [:], relayResults: [String: [RelayResultEntry]] = [:]) {
        self.id = id
        self.protocolData = protocolData
        self.resultTimes = resultTimes
        self.relayResults = relayResults
        self.savedAt = Date()
    }
}

/// Сервис для работы с локальным хранилищем протоколов
class ProtocolStorageService {
    static let shared = ProtocolStorageService()
    
    private let fileManager = FileManager.default
    private let protocolsDirectory: URL
    
    private init() {
        // Создаем директорию для хранения протоколов
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        protocolsDirectory = documentsDirectory.appendingPathComponent("Protocols", isDirectory: true)
        
        // Создаем директорию, если её нет
        if !fileManager.fileExists(atPath: protocolsDirectory.path) {
            try? fileManager.createDirectory(at: protocolsDirectory, withIntermediateDirectories: true)
        }
        
        print("📂 [ProtocolStorage] Директория протоколов: \(protocolsDirectory.path)")
    }
    
    // MARK: - Сохранение протокола
    
    func saveProtocol(_ savedProtocol: SavedProtocol) {
        let fileURL = protocolFileURL(for: savedProtocol.id)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedProtocol)
            try data.write(to: fileURL)
            
            print("✅ [ProtocolStorage] Протокол сохранен: \(savedProtocol.id)")
            print("   Файл: \(fileURL.path)")
        } catch {
            print("❌ [ProtocolStorage] Ошибка сохранения протокола: \(error)")
        }
    }
    
    // MARK: - Загрузка протокола
    
    func loadProtocol(competitionId: String) -> SavedProtocol? {
        let fileURL = protocolFileURL(for: competitionId)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("ℹ️ [ProtocolStorage] Протокол не найден: \(competitionId)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let savedProtocol = try decoder.decode(SavedProtocol.self, from: data)
            
            print("✅ [ProtocolStorage] Протокол загружен: \(competitionId)")
            print("   Результатов сохранено: \(savedProtocol.resultTimes.count)")
            
            return savedProtocol
        } catch {
            print("❌ [ProtocolStorage] Ошибка загрузки протокола: \(error)")
            return nil
        }
    }
    
    // MARK: - Проверка наличия протокола
    
    func hasProtocol(competitionId: String) -> Bool {
        let fileURL = protocolFileURL(for: competitionId)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Обновление результатов
    
    func updateResultTimes(competitionId: String, resultTimes: [String: String], relayResults: [String: [RelayResultEntry]]? = nil) {
        guard var savedProtocol = loadProtocol(competitionId: competitionId) else {
            print("❌ [ProtocolStorage] Не удалось загрузить протокол для обновления: \(competitionId)")
            return
        }
        
        savedProtocol.resultTimes = resultTimes
        if let relayResults = relayResults {
            savedProtocol.relayResults = relayResults
        }
        savedProtocol.savedAt = Date() // Обновляем время сохранения
        saveProtocol(savedProtocol)
        
        print("✅ [ProtocolStorage] Результаты обновлены для: \(competitionId)")
        print("   Individual результатов: \(resultTimes.count)")
        print("   Relay результатов: \(savedProtocol.relayResults.count)")
    }
    
    // MARK: - Удаление протокола
    
    func deleteProtocol(competitionId: String) {
        let fileURL = protocolFileURL(for: competitionId)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("✅ [ProtocolStorage] Протокол удален: \(competitionId)")
        } catch {
            print("❌ [ProtocolStorage] Ошибка удаления протокола: \(error)")
        }
    }
    
    // MARK: - Вспомогательные методы
    
    private func protocolFileURL(for competitionId: String) -> URL {
        return protocolsDirectory.appendingPathComponent("\(competitionId).json")
    }
}

