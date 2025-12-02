//
//  MainTabView.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CompetitionsView()
                .tabItem {
                    Label("Соревнования", systemImage: "trophy.fill")
                }
            
            MeowView()
                .tabItem {
                    Label("Мяу", systemImage: "cat.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}

