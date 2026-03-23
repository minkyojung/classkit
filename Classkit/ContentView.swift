//
//  ContentView.swift
//  Classkit
//
//  Created by William Jung on 3/23/26.
//

import SwiftUI
import SwiftData

enum AppRole: String {
    case teacher
    case student
}

struct ContentView: View {
    @Query private var teachers: [Teacher]
    @State private var hasCompletedSetup = false
    @State private var selectedRole: AppRole?

    private var currentTeacher: Teacher? {
        teachers.first
    }

    var body: some View {
        Group {
            if let role = selectedRole {
                switch role {
                case .teacher:
                    if currentTeacher != nil || hasCompletedSetup {
                        MainView()
                            .toolbar {
                                ToolbarItem(placement: .navigation) {
                                    roleSwitchButton
                                }
                            }
                    } else {
                        ProfileSetupView {
                            hasCompletedSetup = true
                        }
                    }
                case .student:
                    StudentMainView(onSwitchRole: { selectedRole = nil })
                }
            } else {
                RoleSelectionView(onSelect: { role in
                    selectedRole = role
                })
            }
        }
    }

    private var roleSwitchButton: some View {
        Button {
            selectedRole = nil
        } label: {
            Image(systemName: "arrow.left.arrow.right")
        }
        .accessibilityLabel("역할 전환")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Teacher.self, inMemory: true)
}
