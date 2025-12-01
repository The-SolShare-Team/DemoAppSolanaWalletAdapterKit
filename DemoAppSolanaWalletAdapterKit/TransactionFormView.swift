//
//  TransactionFormView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Shared transaction form used by Sign and Sign+Send views.
//

import SolanaTransactions
import SwiftUI

struct TransactionFormView: View {
    let title: String
    var selectedPublicKey: PublicKey?
    var submit: (PublicKey, Int64) async throws -> String?

    @Environment(\.presentationMode) var presentationMode

    @State var toAccountText: String = ""
    @State var lamportsAmount: Int64 = 0

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var didSucceed: Bool = false

    let lamportFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.allowsFloats = false
        return f
    }()

    private var isSubmitDisabled: Bool {
        guard selectedPublicKey != nil else { return true }
        if toAccountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if PublicKey(string: toAccountText) == nil { return true }
        if lamportsAmount <= 0 { return true }
        return false
    }

    var body: some View {
        Form {
            TextField("From Account Public Key", text: .constant(selectedPublicKey?.description ?? "No account selected"))
                .disabled(true)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("To Account Public Key", text: $toAccountText)
            TextField("Amount of Lamports", value: $lamportsAmount, formatter: lamportFormatter)
                .keyboardType(.numberPad)
            Button("Submit") {
                Task {
                    do {
                        let pk = PublicKey(string: toAccountText)!
                        let response = try await submit(pk, lamportsAmount)
                        if let response = response {
                            alertMessage = response
                            didSucceed = true
                            showAlert = true
                        }
                    } catch {
                        alertMessage = String(describing: error)
                        didSucceed = false
                        showAlert = true
                    }
                }
            }
            .disabled(isSubmitDisabled)
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle(title)
        .scrollDismissesKeyboard(.interactively)
        .alert("Response", isPresented: $showAlert) {
            Button("OK") {
                if didSucceed {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

}
