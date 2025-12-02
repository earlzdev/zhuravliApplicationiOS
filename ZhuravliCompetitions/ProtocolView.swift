//
//  ProtocolView.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import SwiftUI

struct ProtocolView: View {
    let competitionId: String
    let protocolData: ProtocolResponse
    @State private var resultTimes: [UUID: String] = [:]
    
    init(competitionId: String, protocolData: ProtocolResponse, initialResultTimes: [UUID: String] = [:]) {
        self.competitionId = competitionId
        self.protocolData = protocolData
        _resultTimes = State(initialValue: initialResultTimes)
        
        print("🔵 [ProtocolView] Инициализация для соревнования: \(competitionId)")
        print("   Загружено результатов: \(initialResultTimes.count)")
        if !initialResultTimes.isEmpty {
            print("   Первые несколько UUID результатов:")
            for (uuid, time) in initialResultTimes.prefix(3) {
                print("   - UUID: \(uuid.uuidString) -> Время: \(time)")
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Заголовок соревнования
//                VStack(alignment: .leading, spacing: 8) {
//                    Text(protocolData.competitionName)
//                        .font(.title)
//                        .fontWeight(.bold)
//                    
//                    HStack {
//                        Image(systemName: "calendar")
//                            .foregroundColor(.blue)
//                        Text(protocolData.competitionDate)
//                            .font(.subheadline)
//                    }
//                    
//                    HStack {
//                        Image(systemName: "location.fill")
//                            .foregroundColor(.blue)
//                        Text(protocolData.location)
//                            .font(.subheadline)
//                    }
//                }
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(12)
                
                // Дисциплины
                ForEach(protocolData.disciplines) { discipline in
                    DisciplineSection(discipline: discipline, resultTimes: $resultTimes)
                }
            }
            .padding()
        }
        .onChange(of: resultTimes) { _, newValue in
            // Автоматически сохраняем результаты при изменении
            saveResultTimes(newValue)
        }
    }
    
    // MARK: - Сохранение результатов
    
    private func saveResultTimes(_ times: [UUID: String]) {
        // Конвертируем UUID -> String в String -> String для сохранения
        let timesDict = times.reduce(into: [String: String]()) { result, pair in
            result[pair.key.uuidString] = pair.value
        }
        
        print("💾 [ProtocolView] Сохранение результатов для: \(competitionId)")
        print("   Количество результатов: \(timesDict.count)")
        
        // Сохраняем результаты
        ProtocolStorageService.shared.updateResultTimes(
            competitionId: competitionId,
            resultTimes: timesDict
        )
    }
}

struct DisciplineSection: View {
    let discipline: Discipline
    @Binding var resultTimes: [UUID: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Название дисциплины
            VStack(alignment: .leading, spacing: 4) {
                Text(discipline.disciplineName)
                    .font(.title2)
                    .fontWeight(.bold)
                
//                Text(discipline.description)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            Divider()
            
            // Возрастные категории
            ForEach(discipline.ageCategories) { ageCategory in
                AgeCategorySection(ageCategory: ageCategory, resultTimes: $resultTimes)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AgeCategorySection: View {
    let ageCategory: AgeCategory
    @Binding var resultTimes: [UUID: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
//             Название возрастной категории
            Text(ageCategory.categoryName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.top, 8)
            
            // Полы
            ForEach(ageCategory.genders) { gender in
                GenderSection(gender: gender, resultTimes: $resultTimes)
            }
        }
    }
}

struct GenderSection: View {
    let gender: Gender
    @Binding var resultTimes: [UUID: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Название пола
            Text(gender.gender)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            // Заплывы (heats)
            ForEach(Array(gender.heats.enumerated()), id: \.offset) { heatIndex, heat in
                HeatView(heat: heat, heatNumber: heatIndex + 1, resultTimes: $resultTimes)
            }
        }
//        .padding(.leading, 16)
    }
}

struct HeatView: View {
    let heat: [Participant?]
    let heatNumber: Int
    @Binding var resultTimes: [UUID: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !heat.isEmpty {
                Text("Заплыв \(heatNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            // Участники в заплыве (показываем все дорожки, включая пустые)
            ForEach(Array(heat.enumerated()), id: \.offset) { laneIndex, participant in
                if let participant = participant {
                    ParticipantRow(
                        participant: participant,
                        lane: laneIndex + 1,
                        resultTime: Binding(
                            get: { resultTimes[participant.id] },
                            set: { resultTimes[participant.id] = $0 }
                        )
                    )
                } else {
                    // Пустая дорожка
                    HStack(spacing: 12) {
                        Text("\(laneIndex + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.gray.opacity(0.5))
                            .cornerRadius(4)
                        
                        Text("Дорожка свободна")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
            }
        }
//        .padding(.leading, 8)
    }
}

struct ParticipantRow: View {
    let participant: Participant
    let lane: Int
    @Binding var resultTime: String?
    @State private var showTimePicker = false
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    @State private var selectedMilliseconds: Int = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Дорожка
            Text("\(lane)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(participant.fullName)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    Label(participant.dateOfBirth, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(participant.club, systemImage: "building.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label(participant.applicationTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .frame(minHeight: 80)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(alignment: .trailing) {
            // Кнопка для ввода времени результата - в overlay, чтобы не влиять на layout
            VStack {
                Spacer()
                Button(action: {
                    // Инициализируем значения из текущего времени, если оно есть
                    if let time = resultTime {
                        parseTimeString(time)
                    } else {
                        selectedMinutes = 0
                        selectedSeconds = 0
                        selectedMilliseconds = 0
                    }
                    showTimePicker = true
                }) {
                    Text(resultTime ?? "Внести время")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(resultTime != nil ? Color.green : Color.blue)
                        .cornerRadius(8)
                }
                .padding(.trailing, 8)
                .padding(.bottom, 4)
            }
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerView(
                minutes: $selectedMinutes,
                seconds: $selectedSeconds,
                milliseconds: $selectedMilliseconds,
                onSave: {
                    resultTime = formatTime(minutes: selectedMinutes, seconds: selectedSeconds, milliseconds: selectedMilliseconds)
                    showTimePicker = false
                }
            )
            .presentationDetents([.fraction(0.5)])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            print("👤 [ParticipantRow] \(participant.fullName)")
            print("   UUID: \(participant.id.uuidString)")
            print("   ResultTime: \(resultTime ?? "нет")")
        }
    }
    
    private func parseTimeString(_ timeString: String) {
        // Формат: MM:SS:MS или MM:SS.MS
        let components = timeString.replacingOccurrences(of: ".", with: ":").split(separator: ":")
        if components.count >= 3 {
            selectedMinutes = Int(components[0]) ?? 0
            selectedSeconds = Int(components[1]) ?? 0
            selectedMilliseconds = Int(components[2]) ?? 0
        } else if components.count == 2 {
            selectedMinutes = Int(components[0]) ?? 0
            selectedSeconds = Int(components[1]) ?? 0
            selectedMilliseconds = 0
        }
    }
    
    private func formatTime(minutes: Int, seconds: Int, milliseconds: Int) -> String {
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }
}

struct TimePickerView: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Binding var milliseconds: Int
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Объединенный пикер времени
            VStack(spacing: 8) {
                Spacer()
                    .frame(height: 10)
                Text("Выберите время")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                
                HStack(spacing: 0) {
                    // Минуты
                    VStack(spacing: 4) {
                        Text("Минуты")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Минуты", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text(String(format: "%02d", minute))
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    
                    Text(":")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal, 4)
                        .padding(.top, 20)
                    
                    // Секунды
                    VStack(spacing: 4) {
                        Text("Секунды")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Секунды", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text(String(format: "%02d", second))
                                    .tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    
                    Text(":")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal, 4)
                        .padding(.top, 20)
                    
                    // Миллисекунды
                    VStack(spacing: 4) {
                        Text("Миллисекунды")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Миллисекунды", selection: $milliseconds) {
                            ForEach(0..<100) { ms in
                                Text(String(format: "%02d", ms))
                                    .tag(ms)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("Сохранить") {
                onSave()
            }
            .foregroundColor(.white)
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    NavigationView {
        ProtocolView(
            competitionId: "test-1",
            protocolData: createTestProtocol()
        )
    }
}

func createTestProtocol() -> ProtocolResponse {
    // Первая дисциплина: 50 метров вольный стиль
    let discipline1 = Discipline(
        disciplineName: "50 метров вольный стиль 6-18 лет",
        description: "50 метров вольным стилем",
        ageCategories: [
            AgeCategory(
                categoryName: "6 лет и младше",
                genders: [
                    Gender(
                        gender: "Мужчины",
                        heats: [
                            [
                                nil,
                                Participant(
                                    fullName: "Козлов Тимофей Иванович",
                                    gender: "male",
                                    dateOfBirth: "15.01.2019",
                                    club: "ТЕСТ",
                                    applicationTime: "00:30:80",
                                    teamName: nil
                                ),
                                nil
                            ]
                        ]
                    )
                ]
            ),
            AgeCategory(
                categoryName: "7-9 лет",
                genders: [
                    Gender(
                        gender: "Мужчины",
                        heats: [
                            [
                                Participant(
                                    fullName: "Смирнов Максим Дмитриевич",
                                    gender: "male",
                                    dateOfBirth: "03.09.2018",
                                    club: "ТЕСТ",
                                    applicationTime: "00:50:59",
                                    teamName: nil
                                ),
                                Participant(
                                    fullName: "Николаев Роман Максимович",
                                    gender: "male",
                                    dateOfBirth: "08.03.2017",
                                    club: "ТЕСТ",
                                    applicationTime: "00:46:56",
                                    teamName: nil
                                )
                            ]
                        ]
                    ),
                    Gender(
                        gender: "Женщины",
                        heats: [
                            [
                                nil,
                                Participant(
                                    fullName: "Семёнова Юлия Михайловна",
                                    gender: "female",
                                    dateOfBirth: "04.10.2016",
                                    club: "ТЕСТ",
                                    applicationTime: "00:39:57",
                                    teamName: nil
                                ),
                                nil
                            ]
                        ]
                    )
                ]
            )
        ]
    )
    
    // Вторая дисциплина: 50 метров на спине
    let discipline2 = Discipline(
        disciplineName: "50 метров на спине 6-18 лет",
        description: "50 метров на спине",
        ageCategories: [
            AgeCategory(
                categoryName: "10-12 лет",
                genders: [
                    Gender(
                        gender: "Мужчины",
                        heats: [
                            [
                                Participant(
                                    fullName: "Орлов Фёдор Максимович",
                                    gender: "male",
                                    dateOfBirth: "09.05.2015",
                                    club: "ТЕСТ",
                                    applicationTime: "00:45:92",
                                    teamName: nil
                                ),
                                Participant(
                                    fullName: "Фёдоров Андрей Александрович",
                                    gender: "male",
                                    dateOfBirth: "05.08.2013",
                                    club: "ТЕСТ",
                                    applicationTime: "00:45:11",
                                    teamName: nil
                                ),
                                Participant(
                                    fullName: "Орлов Михаил Дмитриевич",
                                    gender: "male",
                                    dateOfBirth: "29.07.2015",
                                    club: "ТЕСТ",
                                    applicationTime: "00:54:33",
                                    teamName: nil
                                )
                            ]
                        ]
                    ),
                    Gender(
                        gender: "Женщины",
                        heats: [
                            [
                                Participant(
                                    fullName: "Степанова Вероника Николаевна",
                                    gender: "female",
                                    dateOfBirth: "27.06.2015",
                                    club: "ТЕСТ",
                                    applicationTime: "00:45:20",
                                    teamName: nil
                                ),
                                Participant(
                                    fullName: "Иванова Ольга Павловна",
                                    gender: "female",
                                    dateOfBirth: "07.02.2015",
                                    club: "ТЕСТ",
                                    applicationTime: "00:41:24",
                                    teamName: nil
                                )
                            ]
                        ]
                    )
                ]
            )
        ]
    )
    
    // Третья дисциплина: 50 метров брасс
    let discipline3 = Discipline(
        disciplineName: "50 метров брасс 7-18 лет",
        description: "50 метров брассом",
        ageCategories: [
            AgeCategory(
                categoryName: "13-15 лет",
                genders: [
                    Gender(
                        gender: "Женщины",
                        heats: [
                            [
                                nil,
                                Participant(
                                    fullName: "Соколова Виктория Владимировна",
                                    gender: "female",
                                    dateOfBirth: "07.06.2011",
                                    club: "ТЕСТ",
                                    applicationTime: "00:52:23",
                                    teamName: nil
                                ),
                                nil
                            ]
                        ]
                    )
                ]
            ),
            AgeCategory(
                categoryName: "16-17 лет",
                genders: [
                    Gender(
                        gender: "Женщины",
                        heats: [
                            [
                                nil,
                                Participant(
                                    fullName: "Петрова Надежда Ивановна",
                                    gender: "female",
                                    dateOfBirth: "04.10.2009",
                                    club: "ТЕСТ",
                                    applicationTime: "00:44:01",
                                    teamName: nil
                                ),
                                nil
                            ]
                        ]
                    )
                ]
            )
        ]
    )
    
    return ProtocolResponse(
        competitionName: "Соревнования 06.12.2025",
        competitionDate: "06.12.2025",
        location: "Клуб СССР",
        disciplines: [discipline1, discipline2, discipline3]
    )
}

