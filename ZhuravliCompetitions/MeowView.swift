//
//  MeowView.swift
//  ZhuravliCompetitions
//
//  Created by Ilya Saushin on 22.11.2025.
//

import SwiftUI

struct MeowView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("Мяу")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .navigationTitle("Мяу")
        }
    }
}

#Preview {
    MeowView()
}

