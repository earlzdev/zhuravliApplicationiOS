//
//  ProtocolService.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import Foundation

class ProtocolService: ObservableObject {
    @Published var protocolData: ProtocolResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSubmitting = false
    @Published var submitSuccessMessage: String?
    
    func fetchProtocol(competitionId: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let urlString = "\(Constants.baseUrl)/api/competitions/\(competitionId)/start-protocol"
        print("🔵 [ProtocolService] Запрос протокола:")
        print("   URL: \(urlString)")
        print("   Competition ID: \(competitionId)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [ProtocolService] Неверный URL: \(urlString)")
            await MainActor.run {
                errorMessage = "Неверный URL"
                isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("aB7dK9mLpQ2xZ3nV6yRwT0sCgJhX8eFuMqWtYrEvB1oN4UiHdSz", forHTTPHeaderField: "X-Auth-Token")
        request.httpMethod = "GET"
        
        print("   Headers: X-Auth-Token = aB7dK9mLpQ2xZ3nV6yRwT0sCgJhX8eFuMqWtYrEvB1oN4UiHdSz")
        
        var responseData: Data?
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [ProtocolService] Неверный тип ответа")
                await MainActor.run {
                    errorMessage = "Неверный тип ответа от сервера"
                    isLoading = false
                }
                return
            }
            
            print("📡 [ProtocolService] Ответ сервера:")
            print("   HTTP Status Code: \(httpResponse.statusCode)")
            print("   Headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Response Body: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorDetails = String(data: data, encoding: .utf8) ?? "Нет данных"
                print("❌ [ProtocolService] Ошибка HTTP \(httpResponse.statusCode):")
                print("   \(errorDetails)")
                
                await MainActor.run {
                    if httpResponse.statusCode == 422 {
                        errorMessage = "Ошибка 422: Неверные данные запроса. Проверьте ID соревнования.\nДетали: \(errorDetails)"
                    } else {
                        errorMessage = "Ошибка \(httpResponse.statusCode): \(errorDetails)"
                    }
                    isLoading = false
                }
                return
            }
            
            print("✅ [ProtocolService] Успешный ответ, декодирование данных...")
            
            let decoder = JSONDecoder()
            let protocolData = try decoder.decode(ProtocolResponse.self, from: data)
            
            print("✅ [ProtocolService] Данные успешно декодированы:")
            print("   Competition Name: \(protocolData.competitionName)")
            print("   Disciplines Count: \(protocolData.disciplines.count)")
            
            await MainActor.run {
                self.protocolData = protocolData
                self.isLoading = false
            }
        } catch let decodingError as DecodingError {
            print("❌ [ProtocolService] Ошибка декодирования JSON:")
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("   Type Mismatch: \(type)")
                print("   Context: \(context.debugDescription)")
                print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .valueNotFound(let type, let context):
                print("   Value Not Found: \(type)")
                print("   Context: \(context.debugDescription)")
                print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .keyNotFound(let key, let context):
                print("   Key Not Found: \(key.stringValue)")
                print("   Context: \(context.debugDescription)")
                print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .dataCorrupted(let context):
                print("   Data Corrupted")
                print("   Context: \(context.debugDescription)")
                print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            @unknown default:
                print("   Unknown error: \(decodingError)")
            }
            
            if let data = responseData, let responseString = String(data: data, encoding: .utf8) {
                print("   Response data: \(responseString)")
            }
            
            await MainActor.run {
                errorMessage = "Ошибка декодирования: \(decodingError.localizedDescription)"
                isLoading = false
            }
        } catch {
            print("❌ [ProtocolService] Общая ошибка:")
            print("   \(error.localizedDescription)")
            print("   \(error)")
            
            if let data = responseData, let responseString = String(data: data, encoding: .utf8) {
                print("   Response data: \(responseString)")
            }
            
            await MainActor.run {
                errorMessage = "Ошибка: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Отправка заполненного протокола
    
    func submitFinishProtocol(
        competitionId: String,
        protocolData: ProtocolResponse,
        resultTimes: [String: String],
        relayResults: [String: [RelayResultEntry]]
    ) async -> Bool {
        await MainActor.run {
            isSubmitting = true
            errorMessage = nil
            submitSuccessMessage = nil
        }
        
        // Собираем все записи для отправки
        var entries: [FinishProtocolEntry] = []
        
        // Проходим по всем дисциплинам и участникам
        for discipline in protocolData.disciplines {
            for genderCategory in discipline.genders {
                for ageCategory in genderCategory.ageCategories {
                    for heat in ageCategory.heats {
                        for participant in heat.compactMap({ $0 }) {
                            // Определяем тип дисциплины (эстафета или индивидуальная)
                            let isRelay = participant.teamName != nil || 
                                         discipline.disciplineName.lowercased().contains("эстафет")
                            
                            // Используем составной ключ: disciplineId-participantId
                            let resultKey = "\(discipline.id.uuidString)-\(participant.id.uuidString)"
                            
                            // Создаем запись для отправки
                            let entry: FinishProtocolEntry?
                            
                            if isRelay {
                                // Для эстафет проверяем наличие relay результатов
                                guard let relayEntries = relayResults[resultKey],
                                      !relayEntries.isEmpty else {
                                    continue
                                }
                                
                                // Вычисляем общее количество метров
                                let totalMeters = relayEntries.reduce(0) { $0 + $1.distance }
                                
                                // Формируем строку с временами в секундах
                                let relayResultsString = relayEntries.map { entry in
                                    // Конвертируем время из mm:ss:ms в секунды
                                    timeStringToSeconds(entry.time)
                                }.joined(separator: ",")
                                
                                entry = FinishProtocolEntry(
                                    disciplineId: discipline.id.uuidString,
                                    disciplineType: "relay",
                                    participantId: participant.id.uuidString,
                                    participantName: participant.fullName,
                                    finishTime: nil,
                                    meters: totalMeters,
                                    relayResults: relayResultsString
                                )
                            } else {
                                // Для индивидуальных дисциплин проверяем наличие результата
                                guard let resultValue = resultTimes[resultKey],
                                      isValidResult(resultValue) else {
                                    continue
                                }
                                
                                entry = FinishProtocolEntry(
                                    disciplineId: discipline.id.uuidString,
                                    disciplineType: "individual",
                                    participantId: participant.id.uuidString,
                                    participantName: participant.fullName,
                                    finishTime: resultValue,
                                    meters: nil,
                                    relayResults: nil
                                )
                            }
                            
                            if let entry = entry {
                                entries.append(entry)
                            }
                        }
                    }
                }
            }
        }
        
        // Проверяем, есть ли что отправлять
        guard !entries.isEmpty else {
            await MainActor.run {
                isSubmitting = false
                errorMessage = "Нет результатов для отправки"
            }
            return false
        }
        
        // Отправляем все записи одним запросом
        let success = await sendAllEntries(competitionId: competitionId, entries: entries)
        
        await MainActor.run {
            isSubmitting = false
        }
        
        return success
    }
    
    // MARK: - Вспомогательные методы для конвертации времени
    
    private func timeStringToSeconds(_ timeString: String) -> String {
        // Формат: mm:ss:ms -> конвертируем в формат "секунды.миллисекунды"
        let components = timeString.replacingOccurrences(of: ".", with: ":").split(separator: ":")
        
        guard components.count >= 2 else {
            return "0.00"
        }
        
        let minutes = Int(components[0]) ?? 0
        let seconds = Int(components[1]) ?? 0
        let milliseconds = components.count >= 3 ? (Int(components[2]) ?? 0) : 0
        
        // Вычисляем общее количество секунд (без миллисекунд)
        let totalSeconds = minutes * 60 + seconds
        
        // Форматируем как "секунды.миллисекунды" (например, "73.12")
        return String(format: "%d.%02d", totalSeconds, milliseconds)
    }
    
    private func sendAllEntries(competitionId: String, entries: [FinishProtocolEntry]) async -> Bool {
        let urlString = "\(Constants.baseUrl)/api/competitions/\(competitionId)/finish-protocol"
        
        print("📤 [ProtocolService] Отправка протокола:")
        print("   URL: \(urlString)")
        print("   Количество записей: \(entries.count)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [ProtocolService] Неверный URL: \(urlString)")
            await MainActor.run {
                errorMessage = "Неверный URL"
            }
            return false
        }
        
        var request = URLRequest(url: url)
        request.setValue("aB7dK9mLpQ2xZ3nV6yRwT0sCgJhX8eFuMqWtYrEvB1oN4UiHdSz", forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(entries)
            
            // Логируем тело запроса для отладки
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("   Request Body (первые 500 символов): \(String(jsonString.prefix(500)))")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [ProtocolService] Неверный тип ответа")
                await MainActor.run {
                    errorMessage = "Неверный тип ответа от сервера"
                }
                return false
            }
            
            print("📡 [ProtocolService] Ответ сервера:")
            print("   HTTP Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Response Body: \(responseString)")
            }
            
            if httpResponse.statusCode == 200 {
                // Пытаемся декодировать ответ для получения статистики
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let responseData = json["data"] as? [String: Any],
                   let processedCount = responseData["processed_count"] as? Int,
                   let individualCount = responseData["individual_count"] as? Int,
                   let relayCount = responseData["relay_count"] as? Int {
                    
                    print("✅ [ProtocolService] Протокол успешно отправлен:")
                    print("   Обработано: \(processedCount)")
                    print("   Individual: \(individualCount)")
                    print("   Relay: \(relayCount)")
                    
                    await MainActor.run {
                        submitSuccessMessage = "Успешно отправлено \(processedCount) результатов (Individual: \(individualCount), Relay: \(relayCount))"
                    }
                } else {
                    print("✅ [ProtocolService] Протокол успешно отправлен (статистика недоступна)")
                    await MainActor.run {
                        submitSuccessMessage = "Успешно отправлено \(entries.count) результатов"
                    }
                }
                
                return true
            } else {
                let errorDetails = String(data: data, encoding: .utf8) ?? "Нет данных"
                print("❌ [ProtocolService] Ошибка \(httpResponse.statusCode): \(errorDetails)")
                
                await MainActor.run {
                    errorMessage = "Ошибка \(httpResponse.statusCode): \(errorDetails)"
                }
                return false
            }
        } catch {
            print("❌ [ProtocolService] Ошибка при отправке протокола: \(error)")
            await MainActor.run {
                errorMessage = "Ошибка при отправке: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    private func isValidResult(_ value: String) -> Bool {
        // Проверяем, что значение не пустое и не является "пустым" результатом
        guard !value.isEmpty else { return false }
        
        // Исключаем "пустые" значения времени (00:00:00 и его варианты)
        if value == "00:00:00" || value == "00:00:0" || value == "0:00:00" {
            return false
        }
        
        // Исключаем "пустые" значения дистанции (0 м)
        if value == "0 м" || value == "0м" {
            return false
        }
        
        return true
    }
}

