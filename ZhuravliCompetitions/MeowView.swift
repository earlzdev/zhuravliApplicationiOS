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
                Image("zhuzhka")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
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

