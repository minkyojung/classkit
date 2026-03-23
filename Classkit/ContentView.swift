//
//  ContentView.swift
//  Classkit
//
//  Created by William Jung on 3/23/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Classroom.self, inMemory: true)
}
