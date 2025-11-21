//
//  signTransactionView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-27.
//

import Foundation
import SwiftUI
import SolanaWalletAdapterKit

struct signTransactionView: View {
    var body: some View {
        VStack {
            Text("✅ Transaction Details View")
                .font(.title)
                .padding()
            Text("This view was pushed onto the stack.")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Sign a Transaction")
    }
    
    
    func buildTransaction () async throws -> Void {
    }
}


