//
//  ContentView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Samuel Martineau on 2025-10-13.
//

import SwiftUI
import SolanaWalletAdapterKit



struct ContentView: View {
    @State private var showingWalletSelection: Bool = false
    @State private var walletId: String? = nil
    //this will have the wallet id
    //not sure if it is called an id or a public key,
    // rename variable if necessary
    var body: some View {
        NavigationStack {
            VStack{
                Button(action: toggleWalletConfig){
                            Text(buttonText)
                }.walletButtonStyle()
                
            }
            .blackScreenStyle()
            .navigationTitle("Solana Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingWalletSelection) {
                WalletSelectionView(walletId: $walletId)
            }
        }
    }
    
    private var buttonText: String {
        if let id = walletId {
            return "Connected: \(id)"
        } else {
            return "Select Wallet"
        }
    }
    
    private func toggleWalletConfig() {
        print("toggling wallet")
        self.showingWalletSelection.toggle()
    }
    
    
}

#Preview {
    ContentView()
}
