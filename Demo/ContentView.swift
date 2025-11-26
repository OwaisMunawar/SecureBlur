//
//  ContentView.swift
//  SecureBlurDemo
//
//  Main view for SecureBlur demo
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BlurTestView()
                .tabItem {
                    Label("Blur", systemImage: "camera.filters")
                }

            SecurityTestView()
                .tabItem {
                    Label("Security", systemImage: "lock.shield")
                }
        }
    }
}

#Preview {
    ContentView()
}
