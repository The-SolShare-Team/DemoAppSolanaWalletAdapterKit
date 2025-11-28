// TestHost/TestHostApp.swift
import SwiftUI
import SolanaWalletAdapterKit

@main
struct TestHostApp: App {
    init() {
        // Register callback scheme
        SolanaWalletAdapter.registerCallbackScheme("solanaMWADemoTest")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    let handled = SolanaWalletAdapter.handleOnOpenURL(url)
                    print("TestHost: URL handled: \(handled)")
                }
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Test Host")
                .font(.title)
            Text("Running tests...")
                .foregroundColor(.gray)
        }
    }
}
