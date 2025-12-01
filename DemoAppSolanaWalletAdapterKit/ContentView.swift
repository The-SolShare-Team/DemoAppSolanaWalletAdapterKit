//
//  ContentView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Samuel Martineau on 2025-10-13.
//

import SwiftUI
import SolanaWalletAdapterKit
import SimpleKeychain
import SolanaTransactions
import SolanaRPC

struct ContentView: View {
    @State private var viewModel = ViewModel()
    @State private var showingWalletSelection: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack{
                Button("Pair Wallets") {
                    showingWalletSelection = true
                }.padding()
                
                Button("Clear Keychain") {
                    try! viewModel.keychain.deleteAll()
                }.padding()
                
                NavigationLink("Sign and Send Transaction") {
                    SignAndSendTransactionView(viewModel: viewModel)
                }
                .padding()
                
                NavigationLink("Sign Transaction") {
                    SignTransactionView(viewModel: viewModel)
                }
                .padding()
                
                List(viewModel.walletManager.connectedWallets.indices, id: \.self) { i in
                    let wallet = viewModel.walletManager.connectedWallets[i]
                    HStack {
                        if let key = wallet.publicKey {
                            Text(String(describing: key))
                        } else {
                            Text("No public key")
                        }
                        Spacer()
                        if viewModel.selectedWalletIndex == i {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedWalletIndex = i
                    }
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
