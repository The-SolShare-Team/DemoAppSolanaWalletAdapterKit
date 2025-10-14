//
//  ContentView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Samuel Martineau on 2025-10-13.
//

import SwiftUI
import SolanaWalletAdapterKit

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onTapGesture {
            print(hello())
        }
    }
}

#Preview {
    ContentView()
}
