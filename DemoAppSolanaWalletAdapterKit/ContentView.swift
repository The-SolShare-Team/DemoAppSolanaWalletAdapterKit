// Hello from the Demo Workflow
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
                }
                Button("Clear Keychain") {
                    try! viewModel.keychain.deleteAll()
                }
                Button("Debug") {
                    print(viewModel.walletManager.connectedWallets)
                }
                Button("Sign Transaction") {
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
                            
                            print(transaction)
                            
                            let response = try await viewModel.walletManager.connectedWallets[0].signTransaction(transaction: transaction,)
                            
                            print(response)
                        } catch {
                            print("Caught error: \(error)")
                        }
                    }
                }
                Button("Sign All Transactions") {
                    Task {
                        do {
                            let solanaRPC = SolanaRPCClient(endpoint: .devnet)
                            let latestBlockhash = try! await solanaRPC.getLatestBlockhash().blockhash
                            let transaction1 = try! SolanaTransactions.Transaction(blockhash: latestBlockhash) {
                                SystemProgram.transfer(
                                    from: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW",
                                    to: "CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz",
                                    lamports: 1_000_000_000)
                            }
                            let transaction2 = try! SolanaTransactions.Transaction(blockhash: latestBlockhash) {
                                SystemProgram.transfer(
                                    from: "CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz",
                                    to: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW",
                                    lamports: 100_000_000)
                            }
                            
                            let response = try await viewModel.walletManager.connectedWallets[0].signAllTransactions(transactions: [transaction1,transaction2])
                            
                            print(response)
                        } catch {
                            print("Caught error: \(error)")
                        }
                    }
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
                Button("Sign Message") {
                    Task {
                        do {
                            let response = try await viewModel.walletManager.connectedWallets[0].signMessage(message: "Hello World!".data(using: .utf8)!, display: .utf8)
                            print(response)
                        } catch {
                            print("Caught error: \(error)")
                        }
                    }
                }
                Button("Browse") {
                    Task {
                        do {
                            let response = try await viewModel.walletManager.connectedWallets[0].browse(url: URL(string: "https://apple.com")!, ref: URL(string: "https://solshare.team")!)
                            print(response)
                        } catch {
                            print("Caught error: \(error)")
                        }
                    }
                }
                Button("Send SOL to Phantom") {
                    Task {
                        do {
                            let solanaRPC = SolanaRPCClient(endpoint: .devnet)
                            let latestBlockhash = try! await solanaRPC.getLatestBlockhash().blockhash
                            let transaction = try! SolanaTransactions.Transaction(blockhash: latestBlockhash) {
                                SystemProgram.transfer(
                                    from: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW",
                                    to: "Gz4m7AXonTJUSYcfJkHa8JLu6PuMwkj7BmAfFkqqKcis",
                                    lamports: 1_000_000_000)
                            }
                            
                            print(transaction)
                            
                            let response = try await viewModel.walletManager.connectedWallets[0].signAndSendTransaction(transaction: transaction, sendOptions: nil)
                            
                            print(response)
                        } catch {
                            print("Caught error: \(error)")
                        }
                    }
                }
                Button("Send SOL from Phantom") {
                    Task {
                        do {
                            let solanaRPC = SolanaRPCClient(endpoint: .devnet)
                            let latestBlockhash = try! await solanaRPC.getLatestBlockhash().blockhash
                            let transaction = try! SolanaTransactions.Transaction(blockhash: latestBlockhash) {
                                SystemProgram.transfer(
                                    from: "Gz4m7AXonTJUSYcfJkHa8JLu6PuMwkj7BmAfFkqqKcis",
                                    to: "CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz",
                                    lamports: 100_000_000)
                            }
                            
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
}

#Preview {
    ContentView()
}