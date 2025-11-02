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
    @EnvironmentObject var mwAdapter: MobileWalletAdapter
    @EnvironmentObject var pathManager: NavigationPathManager
    
    var body: some View {
        NavigationStack(path: $pathManager.path){
            VStack{
                Button(action: toggleWalletConfig){
                            Text(buttonText)
                }.walletButtonStyle()
                
                if walletId != nil {
                    VStack {
                        Button(action: {pathManager.path.append(Destination.signTransaction)} ) {
                            Text("Sign Transaction")
                        }.walletButtonStyle()
                        
                        Button(action: {pathManager.path.append(Destination.signMessage)}) {
                            Text("Sign Message")
                        }.walletButtonStyle()
                        
                        Button(action: {pathManager.path.append(Destination.signAndSendTransaction)}) {
                            Text("Sign & Send Transaction")
                        }.walletButtonStyle()
                        
                        Button(action: {pathManager.path.append(Destination.signAllTransactions)}) {
                            Text("Sign All Transactions")
                        }.walletButtonStyle()
                        
                        Button(action: {pathManager.path.append(Destination.browse)}) {
                            Text("Browse")
                        }.walletButtonStyle()
                        
                        Button(action: {pathManager.path.append(Destination.disconnect)}) {
                            Text("Disconnect")
                        }
                        .walletButtonStyle()
                    }
                }
                
            }
            .blackScreenStyle()
            .navigationTitle("Solana Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingWalletSelection) {
                WalletSelectionView(walletId: $walletId)
            }
            .navigationDestination(for: Destination.self) {destination in
                switch destination {
                case .signTransaction:
                    signTransactionView()
                default:
                    EmptyView()
                }
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
