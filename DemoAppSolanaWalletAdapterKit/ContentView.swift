//
//  ContentView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Samuel Martineau on 2025-10-13.
//

import SwiftUI
import SolanaWalletAdapterKit



struct ContentView: View {
    @State private var viewModel = ViewModel()
    @State private var showingWalletSelection: Bool = false
    @State private var walletId: String? = nil
    //this will have the wallet id
    //not sure if it is called an id or a public key,
    // rename variable if necessary
    var body: some View {
        NavigationStack {
            VStack{
                Button(buttonText){
//                    toggleWalletConfig()
                    print(UIApplication.shared.canOpenURL(URL(string: "solflare://hello")!), UIApplication.shared.canOpenURL(URL(string: "backpack://hello")!), UIApplication.shared.canOpenURL(URL(string: "phantom://hello")!))
                }.walletButtonStyle()
                
                Button("Pair with Solflare") {
                    Task {
                        try! await viewModel.pairSolflare()
                    }
                }.walletButtonStyle()
                
                Button("Unpair with Solflare") {
                    Task {
                        try! await viewModel.unpairSolflare()
                    }
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
