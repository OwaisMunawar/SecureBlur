//
//  ContentView.swift
//  SecureBlurDemo
//
//  Main view for SecureBlur demo
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.shield")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("SecureBlur Demo")
                .font(.title)
            Text("Secure image blurring with biometric authentication")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
