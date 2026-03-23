//
//  ContentView.swift
//  Classkit
//
//  Created by William Jung on 3/23/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var teachers: [Teacher]
    @State private var hasCompletedSetup = false

    private var currentTeacher: Teacher? {
        teachers.first
    }

    var body: some View {
        if currentTeacher != nil || hasCompletedSetup {
            MainView()
        } else {
            ProfileSetupView {
                hasCompletedSetup = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Teacher.self, inMemory: true)
}
