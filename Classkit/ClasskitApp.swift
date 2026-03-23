//
//  ClasskitApp.swift
//  Classkit
//
//  Created by William Jung on 3/23/26.
//

import SwiftUI
import SwiftData

@main
struct ClasskitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Teacher.self,
            Subject.self,
            Classroom.self,
            Lesson.self,
            LessonNote.self,
            PDFDocumentModel.self,
            PDFPageAnnotation.self,
            Assignment.self,
            AssignmentAttachment.self,
            Submission.self,
            ScannedProblem.self,
            CanvasOverlay.self
        ])
    }
}
