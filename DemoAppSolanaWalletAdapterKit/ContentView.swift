
//
//  ContentView.swift
//  DemoAppSolanaWalletAdapterKit
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
        NavigationStack(path: $pathManager.path){
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
                Button("Sign And Send Transaction") {
                    Task {
                        do {
                            let solanaRPC = SolanaRPCClient(endpoint: .devnet)
                            let latestBlockhash = try! await solanaRPC.getLatestBlockhash().blockhash
                            let transaction = try! SolanaTransactions.Transaction(blockhash: latestBlockhash) {
                                SystemProgram.transfer(
                                    from: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW",
                                    to: "CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz",
                                    lamports: 1_000_000_000)
                            }
                            
                            //                        Transaction(signatures: [1111111111111111111111111111111111111111111111111111111111111111], message: SolanaTransactions.VersionedMessage.legacyMessage(SolanaTransactions.LegacyMessage(signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 1, accounts: [HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW, CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz, 11111111111111111111111111111111], blockhash: F2fGr4wB7fRPbHGNkRYpqpZnNcRmJgz4LxNJmEnHN926, instructions: [SolanaTransactions.CompiledInstruction(programIdIndex: 2, accounts: [0, 1], data: [2, 0, 0, 0, 0, 202, 154, 59, 0, 0, 0, 0])])))
                            
                            print(transaction)
                            
                            let response = try await viewModel.walletManager.connectedWallets[0].signAndSendTransaction(transaction: transaction, sendOptions: nil)
                            
                            print(response)
                        } catch {
                            print("Caught error: \(error)")
                        }
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
    
    private func updateBalance(publicKey: String) async throws-> UInt64 {
        return try await SolanaRPCClient.init(endpoint: Endpoint.other(url: URL(string: "https://unsplinted-seasonedly-sienna.ngrok-free.dev")!))
            .getBalance(publicKey: publicKey)
    }
}

#Preview {
    ContentView()
        .environmentObject(WalletViewModel())
        .environmentObject(NavigationPathManager())
}
