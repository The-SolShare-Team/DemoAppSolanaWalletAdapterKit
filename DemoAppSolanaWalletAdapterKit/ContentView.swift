//
//  ContentView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Samuel Martineau on 2025-10-13.
//

import SimpleKeychain
import SolanaRPC
import SolanaTransactions
import SolanaWalletAdapterKit
import SwiftUI

struct ContentView: View {
    @State private var viewModel = ViewModel()
    @State private var showingWalletSelection: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Button("Pair Wallets") {
                    showingWalletSelection = true
                }.padding()

                Button("Clear Keychain") {
                    try! viewModel.keychain.deleteAll()
                }.padding()

                NavigationLink("Sign and Send Transaction") {
                    TransactionFormView(title: "Sign and Send Transaction", selectedPublicKey: viewModel.selectedPublicKey) { pk, lam in
                        try await viewModel.signTransaction(toAccount: pk, lamportsAmount: lam, send: true)
                    }
                }
                .padding()

                NavigationLink("Sign Transaction") {
                    TransactionFormView(title: "Sign Transaction", selectedPublicKey: viewModel.selectedPublicKey) { pk, lam in
                        try await viewModel.signTransaction(toAccount: pk, lamportsAmount: lam, send: false)
                    }
                }
                .padding()

                List(viewModel.walletManager.connectedWallets.keys.sorted(), id: \.self) { publicKey in
                    HStack {
                        Text(String(describing: publicKey))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .textSelection(.enabled)
                        Spacer()
                        if viewModel.selectedPublicKey == publicKey {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedPublicKey = publicKey
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
