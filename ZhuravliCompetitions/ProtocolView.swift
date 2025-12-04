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
    @State private var resultTimes: [String: String] = [:]
    @State private var relayResults: [String: [RelayResultEntry]] = [:]
    
    init(competitionId: String, protocolData: ProtocolResponse, initialResultTimes: [String: String] = [:], initialRelayResults: [String: [RelayResultEntry]] = [:]) {
        self.competitionId = competitionId
        self.protocolData = protocolData
        _resultTimes = State(initialValue: initialResultTimes)
        _relayResults = State(initialValue: initialRelayResults)
        
        print("🔵 [ProtocolView] Инициализация для соревнования: \(competitionId)")
        print("   Загружено individual результатов: \(initialResultTimes.count)")
        print("   Загружено relay результатов: \(initialRelayResults.count)")
        if !initialResultTimes.isEmpty {
            print("   Первые несколько ID результатов:")
            for (id, time) in initialResultTimes.prefix(3) {
                print("   - ID: \(id) -> Время: \(time)")
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Дисциплины
                ForEach(protocolData.disciplines) { discipline in
                    DisciplineSection(
                        discipline: discipline,
                        resultTimes: $resultTimes,
                        relayResults: $relayResults
                    )
                }
            }
            .padding()
        }
        .onChange(of: resultTimes) { _, newValue in
            // Автоматически сохраняем результаты при изменении
            saveResults(resultTimes: newValue, relayResults: relayResults)
        }
        .onChange(of: relayResults) { _, newValue in
            // Автоматически сохраняем relay результаты при изменении
            saveResults(resultTimes: resultTimes, relayResults: newValue)
        }
    }
    
    // MARK: - Сохранение результатов
    
    private func saveResults(resultTimes: [String: String], relayResults: [String: [RelayResultEntry]]) {
        print("💾 [ProtocolView] Сохранение результатов для: \(competitionId)")
        print("   Individual результатов: \(resultTimes.count)")
        print("   Relay результатов: \(relayResults.count)")
        
        // Сохраняем результаты
        ProtocolStorageService.shared.updateResultTimes(
            competitionId: competitionId,
            resultTimes: resultTimes,
            relayResults: relayResults
        )
    }
}

struct DisciplineSection: View {
    let discipline: Discipline
    @Binding var resultTimes: [String: String]
    @Binding var relayResults: [String: [RelayResultEntry]]
    
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
            
            // Полы (новая иерархия: Discipline -> Gender -> AgeCategory -> heats)
            ForEach(discipline.genders) { genderCategory in
                GenderSection(
                    genderCategory: genderCategory,
                    disciplineName: discipline.disciplineName,
                    resultTimes: $resultTimes,
                    relayResults: $relayResults
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct GenderSection: View {
    let genderCategory: GenderCategory
    let disciplineName: String
    @Binding var resultTimes: [String: String]
    @Binding var relayResults: [String: [RelayResultEntry]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Название пола
            Text(genderCategory.gender)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.top, 8)
            
            // Возрастные категории
            ForEach(genderCategory.ageCategories) { ageCategory in
                AgeCategorySection(
                    ageCategory: ageCategory,
                    disciplineName: disciplineName,
                    resultTimes: $resultTimes,
                    relayResults: $relayResults
                )
            }
        }
    }
}

struct AgeCategorySection: View {
    let ageCategory: AgeCategory
    let disciplineName: String
    @Binding var resultTimes: [String: String]
    @Binding var relayResults: [String: [RelayResultEntry]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Название возрастной категории
            Text(ageCategory.categoryName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            // Заплывы (heats)
            ForEach(Array(ageCategory.heats.enumerated()), id: \.offset) { heatIndex, heat in
                HeatView(
                    heat: heat,
                    heatNumber: heatIndex + 1,
                    disciplineName: disciplineName,
                    resultTimes: $resultTimes,
                    relayResults: $relayResults
                )
            }
        }
//        .padding(.leading, 16)
    }
}

struct HeatView: View {
    let heat: [Participant?]
    let heatNumber: Int
    let disciplineName: String
    @Binding var resultTimes: [String: String]
    @Binding var relayResults: [String: [RelayResultEntry]]
    
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
                        disciplineName: disciplineName,
                        resultTime: Binding(
                            get: { resultTimes[participant.id.uuidString] },
                            set: { resultTimes[participant.id.uuidString] = $0 }
                        ),
                        relayResultEntries: Binding(
                            get: { relayResults[participant.id.uuidString] ?? [] },
                            set: { relayResults[participant.id.uuidString] = $0.isEmpty ? nil : $0 }
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
    let disciplineName: String
    @Binding var resultTime: String?
    @Binding var relayResultEntries: [RelayResultEntry]
    @State private var showTimePicker = false
    @State private var showRelayPicker = false
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    @State private var selectedMilliseconds: Int = 0
    @State private var selectedDistance: Int = 100 // По умолчанию 100 метров
    
    // Проверка, является ли это эстафетой (командная эстафета)
    private var isRelay: Bool {
        let isTeamRelay = participant.teamName != nil
        let disciplineIsRelay = disciplineName.lowercased().contains("эстафет")
        return isTeamRelay || disciplineIsRelay
    }
    
    // Общее количество метров для relay
    private var totalMeters: Int {
        relayResultEntries.reduce(0) { $0 + $1.distance }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
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
                    
                    if isRelay {
                        // Для эстафет показываем только дату рождения
                        Label(participant.dateOfBirth, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        // Для индивидуальных заплывов показываем все данные
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
                }
                
                Spacer(minLength: 0)
                
                // Для individual - показываем кнопку ввода времени справа, выровненную по центру
                if !isRelay {
                    Button(action: {
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
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(resultTime != nil ? Color.green : Color.blue)
                            .cornerRadius(10)
                    }
                } else {
                    // Для эстафет - кнопка "Добавить" справа, выровненная по центру
                    Button(action: {
                        selectedDistance = 100
                        selectedMinutes = 0
                        selectedSeconds = 0
                        selectedMilliseconds = 0
                        showRelayPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Добавить")
                                .fontWeight(.semibold)
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
            }
            
            // Для relay - показываем список записей
            if isRelay && !relayResultEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // Таблица с записями
                    VStack(spacing: 4) {
                        // Заголовок таблицы
                        HStack {
                            Text("Дистанция")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Время")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Итого")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 60)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        
                        // Записи
                        ForEach(relayResultEntries) { entry in
                            HStack {
                                Text("\(entry.distance) м")
                                    .font(.caption)
                                Spacer()
                                Text(entry.time)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                Button(action: {
                                    relayResultEntries.removeAll { $0.id == entry.id }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .frame(width: 60)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                        
                        // Итоговая строка
                        HStack {
                            Text("Итого:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(totalMeters) м")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Spacer()
                            Text("")
                                .frame(width: 60)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
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
        .sheet(isPresented: $showRelayPicker) {
            RelayPickerView(
                distance: $selectedDistance,
                minutes: $selectedMinutes,
                seconds: $selectedSeconds,
                milliseconds: $selectedMilliseconds,
                onSave: {
                    let time = formatTime(minutes: selectedMinutes, seconds: selectedSeconds, milliseconds: selectedMilliseconds)
                    let entry = RelayResultEntry(distance: selectedDistance, time: time)
                    relayResultEntries.append(entry)
                    showRelayPicker = false
                }
            )
            .presentationDetents([.fraction(0.5)])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            print("👤 [ParticipantRow] \(participant.fullName)")
            print("   ID: \(participant.id)")
            print("   ResultTime: \(resultTime ?? "нет")")
            print("   Relay entries: \(relayResultEntries.count)")
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

struct RelayPickerView: View {
    @Binding var distance: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Binding var milliseconds: Int
    let onSave: () -> Void
    
    // Значения от 0 до 100 метров
    private let distances: [Int] = Array(0...100)
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Spacer()
                    .frame(height: 10)
                Text("Добавить результат")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                
                HStack(spacing: 0) {
                    // Пикер дистанции
                    VStack(spacing: 4) {
                        Text("Метры")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Дистанция", selection: $distance) {
                            ForEach(distances, id: \.self) { dist in
                                Text("\(dist)")
                                    .tag(dist)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Пикер времени
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
                    .frame(maxWidth: .infinity)
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
        id: "e2794ac2-32e3-4970-850b-5052efdbaad3",
        disciplineName: "50 метров вольный стиль 6-18 лет",
        description: "50 метров вольным стилем",
        genders: [
            GenderCategory(
                gender: "Мужчины",
                ageCategories: [
                    AgeCategory(
                        categoryName: "6 лет и младше",
                        heats: [
                            [
                                nil,
                                Participant(
                                    id: "c75759c4-0fa2-4d1f-afc9-b4748030ddbb",
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
                    ),
                    AgeCategory(
                        categoryName: "7-9 лет",
                        heats: [
                            [
                                Participant(
                                    id: "b16c2c4f-3c02-4fe3-86f2-26e4d229d406",
                                    fullName: "Смирнов Максим Дмитриевич",
                                    gender: "male",
                                    dateOfBirth: "03.09.2018",
                                    club: "ТЕСТ",
                                    applicationTime: "00:50:59",
                                    teamName: nil
                                ),
                                Participant(
                                    id: "2617d961-e2ba-4115-9b51-11bd7ef1c198",
                                    fullName: "Николаев Роман Максимович",
                                    gender: "male",
                                    dateOfBirth: "08.03.2017",
                                    club: "ТЕСТ",
                                    applicationTime: "00:46:56",
                                    teamName: nil
                                )
                            ]
                        ]
                    )
                ]
            ),
            GenderCategory(
                gender: "Женщины",
                ageCategories: [
                    AgeCategory(
                        categoryName: "7-9 лет",
                        heats: [
                            [
                                nil,
                                Participant(
                                    id: "00366ced-a341-4d99-8d6e-aae741c7ee61",
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
        id: "d21ea4ef-dbd2-4c78-a332-0d14ad17c813",
        disciplineName: "50 метров на спине 6-18 лет",
        description: "50 метров на спине",
        genders: [
            GenderCategory(
                gender: "Мужчины",
                ageCategories: [
                    AgeCategory(
                        categoryName: "10-12 лет",
                        heats: [
                            [
                                Participant(
                                    id: "e5da8b45-3041-4cf1-9a5d-c5f3a4f52c62",
                                    fullName: "Орлов Фёдор Максимович",
                                    gender: "male",
                                    dateOfBirth: "09.05.2015",
                                    club: "ТЕСТ",
                                    applicationTime: "00:45:92",
                                    teamName: nil
                                ),
                                Participant(
                                    id: "5d017439-8361-491f-a6dc-61ae3f742c09",
                                    fullName: "Фёдоров Андрей Александрович",
                                    gender: "male",
                                    dateOfBirth: "05.08.2013",
                                    club: "ТЕСТ",
                                    applicationTime: "00:45:11",
                                    teamName: nil
                                ),
                                Participant(
                                    id: "2d175369-0779-4590-9c6c-28909a6f7c87",
                                    fullName: "Орлов Михаил Дмитриевич",
                                    gender: "male",
                                    dateOfBirth: "29.07.2015",
                                    club: "ТЕСТ",
                                    applicationTime: "00:54:33",
                                    teamName: nil
                                )
                            ]
                        ]
                    )
                ]
            ),
            GenderCategory(
                gender: "Женщины",
                ageCategories: [
                    AgeCategory(
                        categoryName: "10-12 лет",
                        heats: [
                            [
                                Participant(
                                    id: "0409ba25-9cff-48f3-9801-67a8a9ecb6f0",
                                    fullName: "Степанова Вероника Николаевна",
                                    gender: "female",
                                    dateOfBirth: "27.06.2015",
                                    club: "ТЕСТ",
                                    applicationTime: "00:45:20",
                                    teamName: nil
                                ),
                                Participant(
                                    id: "2b032b5c-31de-4489-ba3a-80d60a1c51d0",
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
        id: "405a9a16-a281-4525-a0e2-c7a782d30907",
        disciplineName: "50 метров брасс 7-18 лет",
        description: "50 метров брассом",
        genders: [
            GenderCategory(
                gender: "Женщины",
                ageCategories: [
                    AgeCategory(
                        categoryName: "13-15 лет",
                        heats: [
                            [
                                nil,
                                Participant(
                                    id: "35f697b2-7377-45fb-a59d-3b7865339cd4",
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
                    ),
                    AgeCategory(
                        categoryName: "16-17 лет",
                        heats: [
                            [
                                nil,
                                Participant(
                                    id: "91ca5938-9d57-489b-aeaa-901ff8c87b8a",
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

