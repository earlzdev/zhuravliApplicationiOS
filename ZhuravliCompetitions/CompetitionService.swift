//
//  CompetitionService.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import Foundation

class CompetitionService: ObservableObject {
    @Published var competitions: [Competition] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchCompetitions() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let urlString = "\(Constants.baseUrl)/api/athlete/competitions"
        print("🔵 [CompetitionService] Запрос списка соревнований:")
        print("   URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [CompetitionService] Неверный URL: \(urlString)")
            await MainActor.run {
                errorMessage = "Неверный URL"
                isLoading = false
            }
            return
        }
        
        var responseData: Data?
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            responseData = data
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [CompetitionService] Неверный тип ответа")
                await MainActor.run {
                    errorMessage = "Неверный тип ответа от сервера"
                    isLoading = false
                }
                return
            }
            
            print("📡 [CompetitionService] Ответ сервера:")
            print("   HTTP Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Response Body: \(responseString.prefix(500))...") // Первые 500 символов
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorDetails = String(data: data, encoding: .utf8) ?? "Нет данных"
                print("❌ [CompetitionService] Ошибка HTTP \(httpResponse.statusCode):")
                print("   \(errorDetails)")
                
                await MainActor.run {
                    errorMessage = "Ошибка \(httpResponse.statusCode): \(errorDetails)"
                    isLoading = false
                }
                return
            }
            
            print("✅ [CompetitionService] Успешный ответ, декодирование данных...")
            
            let decoder = JSONDecoder()
            let competitions = try decoder.decode([Competition].self, from: data)
            
            print("✅ [CompetitionService] Данные успешно декодированы:")
            print("   Competitions Count: \(competitions.count)")
            
            await MainActor.run {
                self.competitions = competitions
                self.isLoading = false
            }
        } catch let decodingError as DecodingError {
            print("❌ [CompetitionService] Ошибка декодирования JSON:")
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("   Type Mismatch: \(type)")
                print("   Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value Not Found: \(type)")
                print("   Context: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("   Key Not Found: \(key.stringValue)")
                print("   Context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   Data Corrupted: \(context.debugDescription)")
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
            print("❌ [CompetitionService] Общая ошибка:")
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
}

