//
//  ProtocolCardView.swift
//  ZhuravliCompetitions
//
//  Created by AI Assistant on 23.11.2025.
//

import SwiftUI

struct ProtocolCardView: View {
    let savedProtocol: SavedProtocol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Протокол соревнования")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Нажмите, чтобы открыть")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Информация о протоколе
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text(savedProtocol.protocolData.competitionDate)
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text(savedProtocol.protocolData.location)
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text("Дисциплин: \(savedProtocol.protocolData.disciplines.count)")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    Text("Результатов: \(savedProtocol.resultTimes.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    Text("Сохранено: \(formatDate(savedProtocol.savedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

#Preview {
    ProtocolCardView(savedProtocol: SavedProtocol(
        id: "1",
        protocolData: createTestProtocol(),
        resultTimes: ["uuid1": "01:23:45", "uuid2": "01:24:50"]
    ))
    .padding()
}

