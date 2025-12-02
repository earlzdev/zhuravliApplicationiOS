//
//  CompetitionDetailView.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import SwiftUI

struct CompetitionDetailView: View {
    let competition: Competition
    @StateObject private var protocolService = ProtocolService()
    @State private var showProtocol = false
    
    var body: some View {
        Group {
            if showProtocol, let protocolData = protocolService.protocolData {
                ProtocolView(competitionId: competition.id, protocolData: protocolData)
                    .navigationTitle("Протокол")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Заголовок
                        VStack(alignment: .leading, spacing: 12) {
                            Text(competition.description)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if competition.isActive {
                                HStack {
                                    Text("Активно")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Информация о соревновании
                        VStack(alignment: .leading, spacing: 16) {
                            InfoRow(icon: "location.fill", title: "Место проведения", value: competition.location)
                            
                            InfoRow(icon: "calendar", title: "Дата", value: competition.formattedDate)
                            
                            InfoRow(icon: "person.2.fill", title: "Зарегистрировано участников", value: "\(competition.registeredCount)")
                        }
                        .padding(.vertical)
                        
                        Divider()
                        
                        // Кнопка "Сформировать протокол"
                        if protocolService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Загрузка протокола...")
                                Spacer()
                            }
                            .padding()
                        } else {
                            Button(action: {
                                Task {
                                    await protocolService.fetchProtocol(competitionId: competition.id)
                                    if protocolService.protocolData != nil {
                                        showProtocol = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text("Сформировать протокол")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        
                        if let errorMessage = protocolService.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Соревнование")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .tabBar)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        CompetitionDetailView(competition: Competition(
            id: "1",
            description: "Соревнования 06.12.2025",
            location: "Клуб СССР",
            date: "2025-12-06",
            isActive: true,
            registeredCount: 50
        ))
    }
}

