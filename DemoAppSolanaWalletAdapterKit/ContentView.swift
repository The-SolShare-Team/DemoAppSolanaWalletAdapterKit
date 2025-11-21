//
//  ContentView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Samuel Martineau on 2025-10-13.
//

import SwiftUI
import SolanaWalletAdapterKit
import SimpleKeychain

struct ContentView: View {
    @State private var viewModel = ViewModel()
    @State private var showingWalletSelection: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack{
                Button("Pair Wallets") {
                    showingWalletSelection = true
                }
                Button("Clear Keychain") {
                    try! viewModel.keychain.deleteAll()
                }
                Button("Debug") {
                    print(viewModel.walletManager.connectedWallets)
                }
            }
            .navigationTitle("SolanaWalletAdapterKit Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingWalletSelection) {
                WalletSelectionView()
            }
        }.environment(viewModel)
    }
}

#Preview {
    ContentView()
}
