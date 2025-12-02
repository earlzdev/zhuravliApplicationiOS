//
//  ProtocolListView.swift
//  ZhuravliCompetitions
//
//  Created by AI Assistant on 23.11.2025.
//

import SwiftUI

struct ProtocolListView: View {
    let competition: Competition
    @StateObject private var protocolService = ProtocolService()
    @State private var savedProtocol: SavedProtocol?
    @State private var isLoadingLocal = true
    
    var body: some View {
        ZStack {
            if isLoadingLocal {
                ProgressView("Проверка локальных данных...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let saved = savedProtocol {
                // Протокол есть локально - показываем карточку
                ScrollView {
                    VStack(spacing: 20) {
                        // Информация о соревновании
                        competitionInfoSection
                        
                        // Карточка протокола
                        NavigationLink(destination: ProtocolView(
                            competitionId: competition.id,
                            protocolData: saved.protocolData,
                            initialResultTimes: convertResultTimes(saved.resultTimes)
                        )) {
                            ProtocolCardView(savedProtocol: saved)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            } else {
                // Протокола нет - показываем кнопку загрузки
                VStack(spacing: 24) {
                    competitionInfoSection
                        .padding()
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Протокол не загружен")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Загрузите протокол соревнования, чтобы начать работу с ним")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if protocolService.isLoading {
                            ProgressView("Загрузка протокола...")
                                .padding()
                        } else {
                            Button(action: {
                                Task {
                                    await loadProtocolFromServer()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Загрузить протокол")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        
                        if let errorMessage = protocolService.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationTitle("Протокол")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadLocalProtocol()
        }
        .refreshable {
            await loadProtocolFromServer()
        }
    }
    
    // MARK: - Информация о соревновании
    
    private var competitionInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(competition.description)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text(competition.location)
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(competition.formattedDate)
                    .font(.subheadline)
            }
            
            if competition.isActive {
                HStack {
                    Text("Активно")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Загрузка данных
    
    private func loadLocalProtocol() {
        isLoadingLocal = true
        
        // Проверяем наличие локального протокола
        if let saved = ProtocolStorageService.shared.loadProtocol(competitionId: competition.id) {
            savedProtocol = saved
            print("✅ [ProtocolListView] Локальный протокол загружен для: \(competition.id)")
        } else {
            print("ℹ️ [ProtocolListView] Локальный протокол не найден для: \(competition.id)")
        }
        
        isLoadingLocal = false
    }
    
    private func loadProtocolFromServer() async {
        await protocolService.fetchProtocol(competitionId: competition.id)
        
        if let protocolData = protocolService.protocolData {
            // Сохраняем протокол локально
            let savedProtocol = SavedProtocol(
                id: competition.id,
                protocolData: protocolData,
                resultTimes: [:]
            )
            ProtocolStorageService.shared.saveProtocol(savedProtocol)
            
            // Обновляем UI
            self.savedProtocol = savedProtocol
            
            print("✅ [ProtocolListView] Протокол загружен и сохранен для: \(competition.id)")
        }
    }
    
    // MARK: - Вспомогательные методы
    
    /// Конвертирует словарь String -> String в UUID -> String для передачи в ProtocolView
    private func convertResultTimes(_ times: [String: String]) -> [UUID: String] {
        var result: [UUID: String] = [:]
        
        print("🔄 [ProtocolListView] Конвертация результатов:")
        print("   Входящих результатов: \(times.count)")
        
        for (uuidString, time) in times {
            if let uuid = UUID(uuidString: uuidString) {
                result[uuid] = time
                print("   ✅ UUID: \(uuidString) -> Время: \(time)")
            } else {
                print("   ❌ Не удалось конвертировать UUID: \(uuidString)")
            }
        }
        
        print("   Итого сконвертировано: \(result.count)")
        
        return result
    }
}

#Preview {
    NavigationView {
        ProtocolListView(competition: Competition(
            id: "1",
            description: "Соревнования 06.12.2025",
            location: "Клуб СССР",
            date: "2025-12-06",
            isActive: true,
            registeredCount: 50
        ))
    }
}

