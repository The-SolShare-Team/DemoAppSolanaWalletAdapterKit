//
//  SignAndSendTransactionView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Dang Khoa Chiem on 2025-11-29.
//

import SwiftUI

struct SignTransactionView: View {
    var viewModel: ViewModel
    
    @State var fromAccountText: String = ""
    @State var toAccountText: String = ""
    @State var lamportsAmountText: String = ""
    
    var body: some View {
        Form {
            TextField("From Account Public Key", text: $fromAccountText)
            TextField("To Account Public Key", text: $toAccountText)
            TextField("Amount of Lamports", text: $lamportsAmountText)
            Button("Submit") {
                Task {
                    try await viewModel.signTransaction(
                        fromAccount: fromAccountText,
                        toAccount: toAccountText,
                        lamportsAmount: lamportsAmountText)
                }
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("Sign Transaction")
    }
}
