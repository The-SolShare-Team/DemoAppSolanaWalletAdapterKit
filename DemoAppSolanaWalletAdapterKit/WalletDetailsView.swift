
//
//  WalletDetailsView.swift
//  DemoAppSolanaWalletAdapterKit
//

import SwiftUI
import SolanaWalletAdapterKit

struct WalletDetailsView: View {
    @EnvironmentObject private var viewModel: WalletViewModel
    @EnvironmentObject var pathManager: NavigationPathManager

    var body: some View {
        // Use a Group to handle the optional wallet gracefully
        if let wallet = viewModel.selectedWallet {
            walletDetailsContent(for: wallet)
        }else {
            Text("No wallet selected")
        }
        
    }
    
    @ViewBuilder
    private func walletDetailsContent(for wallet: WalletData) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Balance Display
                VStack(spacing: 10) {
                    Text("Balance")
                        .font(.headline)
                    
                    
                    Text(wallet.formattedBalance + " SOL")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                    
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 15) {
                    if wallet.wallet.connection != nil {
                        Button("Provider Methods") {
                            // Navigate using the main path manager
                            pathManager.path.append(Destination.providerMethods)
                        }
                        .walletButtonStyle()
                    }
                    
                    Button("Disconnect Wallet") {
                        viewModel.disconnectWallet(wallet)
                        // Good UX: automatically go back to the list after disconnecting
                        pathManager.path.removeLast()
                    }
                    .redButtonStyle()
                    
                }
            }
            .padding()
        }
        .navigationTitle(wallet.provider)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            print("RENDER: WalletDetailsView")
        }
    }
}
