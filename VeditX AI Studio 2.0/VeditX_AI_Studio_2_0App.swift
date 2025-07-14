//
//  VeditX_AI_Studio_2_0App.swift
//  VeditX AI Studio 2.0
//
//  Created by Sanjay Shah on 14/07/25.
//

import SwiftUI

@main
struct VeditX_AI_Studio_2_0App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    // Handle new project
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Button("Open Project...") {
                    // Handle open project
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save Project") {
                    // Handle save project
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            
            CommandGroup(after: .importExport) {
                Button("Import Media...") {
                    // Handle import media
                }
                .keyboardShortcut("i", modifiers: .command)
                
                Divider()
                
                Button("Export Video...") {
                    // Handle export video
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}
