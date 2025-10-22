//
//  WalletSelectionView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-15.
//

// https://solana.com/developers/cookbook/wallets/connect-wallet-react
// referencing the demo app on this webpage, a user clicks connect to wallet and is shown a
// new view with a list of detected wallets
// these are the swift components for that view

import SwiftUI

// each row has the following layout
// {icon} walletName  <- spacer -> DETECTED
struct WalletRow: View {
    let walletName: String
    let walletIcon: String //icon name, reference assets folder
    let onConnect: () -> Void
    
    var body: some View {
        Button(action: onConnect) {
            HStack {
                Image(systemName: walletIcon)
                    .walletIconStyle()
                
                Text(walletName)
                    .walletNameStyle()
                
                Spacer()
                
                Text("Detected")
                    .detectedTextStyle()
            }.walletRowBackground()
        }.plainButtonStyle()
        
    }
}

struct WalletSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var walletId: String?
    @EnvironmentObject var pathManager: NavigationPathManager
    // Temporary hardcoded wallets for now
    let wallets = [
        ("Phantom", "wallet.pass"),
        ("Solflare", "flame"),
        ("Backpack", "backpack")
    ]
    
    var body: some View {
        
        VStack {
            Text("Connect to a Wallet:")
                .connectTextStyle()
                VStack(spacing: 15){
                    ForEach(wallets, id: \.0) {wallet in
                            WalletRow(
                                walletName: wallet.0,
                                walletIcon: wallet.1,
                                onConnect: {
                                    handleWalletConnection(wallet.0)
                                }
                            )
                    }
                }
                .padding()
            
        }.blackScreenStyle()
    }
    private func handleWalletConnection(_ walletName: String) {
            print("Connecting to: \(walletName)")
            // TODO: Call wallet.connect() here, add a loading thing to navigation stack
            walletId = walletName
            dismiss()
    }
}

#Preview {
    
    WalletSelectionView(walletId: .constant(nil))
}
