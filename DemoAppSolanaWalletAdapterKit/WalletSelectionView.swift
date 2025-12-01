//
//  WalletSelectionView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-15.
//

import SwiftUI
import SolanaWalletAdapterKit
import SolanaRPC

struct WalletRow: View {
    let wallet: any Wallet.Type
    let onConnect: () -> Void
    
    var body: some View {
        Button(action: onConnect) {
            HStack {
                Image(systemName: "wallet.pass")
                    .walletIconStyle()
                
                Text(String(describing: wallet))
                    .walletNameStyle()
                
                Spacer()
                
                if wallet.isProbablyAvailable() {
                    Text("Detected")
                        .detectedTextStyle()
                }
            }.walletRowBackground()
        }.plainButtonStyle()
        
    }
}

struct WalletSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ViewModel.self) var viewModel
    
    var availableWallets: [String] {
        viewModel.walletManager.availableWalletsMap.map { $0.value.identifier }
    }
    
    var body: some View {
        VStack {
            Text("Connect to a Wallet:")
                .connectTextStyle()
            VStack(spacing: 15){
                ForEach(availableWallets, id: \.self) { w in
                    WalletRow(
                        wallet: viewModel.walletManager.availableWalletsMap[w]!,
                        onConnect: {
                            Task {
                                try await handleWalletConnection(viewModel.walletManager.availableWalletsMap[w]!)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private func handleWalletConnection(_ wallet: any Wallet.Type) async throws {
        try await viewModel.walletManager.pair(wallet)
        dismiss()
    }
}
