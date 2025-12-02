//
//  CompetitionsView.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import SwiftUI

struct CompetitionsView: View {
    @StateObject private var service = CompetitionService()
    
    var body: some View {
        NavigationView {
            ZStack {
                if service.isLoading {
                    ProgressView("Загрузка соревнований...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = service.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                        Button("Повторить") {
                            Task {
                                await service.fetchCompetitions()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if service.competitions.isEmpty {
                    VStack {
                        Spacer()
                        Text("Нет доступных соревнований")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(service.competitions) { competition in
                                CompetitionCardView(competition: competition)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Соревнования")
            .task {
                await service.fetchCompetitions()
            }
            .refreshable {
                await service.fetchCompetitions()
            }
        }
    }
}

#Preview {
    CompetitionsView()
}

