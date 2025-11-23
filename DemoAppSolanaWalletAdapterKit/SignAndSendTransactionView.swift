//
//  SignandSendTransactionView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-11-22.
//

import Foundation
import SwiftUI



struct SignAndSendTransactionView: View {
    @EnvironmentObject var pathManager: NavigationPathManager
    @EnvironmentObject private var viewModel: WalletViewModel
    @State private var selectedToWalletPublicKey: String?
    @State private var amount: String = ""
    @State private var isBuilding: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section(header: Text("Transfer SOL between connected wallets")) {
                
                HStack {
                    Text("From: ")
                    Spacer()
                    Text("\(viewModel.selectedWallet?.formattedPublicKey ?? ""): \(viewModel.selectedWallet?.formattedBalance ?? "") SOL")
                        .foregroundColor(.secondary)
                }
                
                Picker("To: ", selection: $selectedToWalletPublicKey) {
                    ForEach(viewModel.wallets, id: \.id) { toWallet in
                        if toWallet.publicKey != viewModel.selectedWallet?.publicKey {
                            Text("\(toWallet.formattedPublicKey): \(toWallet.formattedBalance) SOL")
                                .tag(toWallet.publicKey as String?)
                        }
                    }
                }
                .disabled(viewModel.wallets.count <= 1)
                
                HStack {
                    Text("Amount (SOL)")
                    TextField("0.0", text: $amount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                Button(action: handleBuildTransaction) {
                    if isBuilding {
                        HStack {
                            ProgressView()
                            Text("Building Transaction...")
                        }
                    } else {
                        Text("Build and Send Transaction")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                }
                .walletButtonStyle()
                .background(
                    (isBuilding || selectedToWalletPublicKey == nil || amount.isEmpty) ? Color.gray : Color.blue
                )
                .cornerRadius(10)
                .disabled(isBuilding || selectedToWalletPublicKey == nil || amount.isEmpty)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Sign and send a transaction")
        .task {
            print("RENDER: SignAndSendTransactionView")
        }
    }
    
    private func handleBuildTransaction() {
        guard let toPublicKey = selectedToWalletPublicKey else {
            errorMessage = "Please select a wallet to send to"
            return
        }
        guard let amountDouble = Double(amount), amountDouble > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard let fromPublicKey = viewModel.selectedWallet?.publicKey else {
            errorMessage = "No wallet selected"
            return
        }
        
        isBuilding = true
        errorMessage = nil
        
        Task {
            do {
                errorMessage = try await viewModel.buildTransaction(
                    from: fromPublicKey,
                    to: toPublicKey,
                    lamports: Int64(amountDouble * 1_000_000_000)
                )
                isBuilding = false
            } catch {
                isBuilding = false
                errorMessage = "Failed to build transaction: \(error.localizedDescription)"
            }
        }
    }
}
