//
//  CompetitionCardView.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import SwiftUI

struct CompetitionCardView: View {
    let competition: Competition
    
    var body: some View {
        NavigationLink(destination: ProtocolListView(competition: competition)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(competition.description)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if competition.isActive {
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
                
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                    Text("Зарегистрировано: \(competition.registeredCount)")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CompetitionCardView(competition: Competition(
        id: "1",
        description: "Соревнования 06.12.2025",
        location: "Клуб СССР",
        date: "2025-12-06",
        isActive: true,
        registeredCount: 50
    ))
    .padding()
}

