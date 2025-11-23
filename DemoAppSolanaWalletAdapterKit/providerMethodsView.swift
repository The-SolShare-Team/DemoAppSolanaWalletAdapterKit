//
//  providerMethodsView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-11-02.
//
import SwiftUI
import Foundation


struct ProviderMethodsView : View {
    @EnvironmentObject var pathManager: NavigationPathManager
    @EnvironmentObject private var viewModel: WalletViewModel
    
    var body : some View {
        VStack {
            Button(action: {pathManager.path.append(Destination.signTransaction)} ) {
                Text("Sign a Transaction")
            }.walletButtonStyle()
            
            Button(action: {pathManager.path.append(Destination.signMessage)}) {
                Text("Sign Message")
            }.walletButtonStyle()
            
            Button(action: {pathManager.path.append(Destination.signAndSendTransaction)}) {
                Text("Sign & Send Transaction")
            }.walletButtonStyle()
            
            Button(action: {pathManager.path.append(Destination.signAllTransactions)}) {
                Text("Sign All Transactions")
            }.walletButtonStyle()
            
            Button(action: {pathManager.path.append(Destination.browse)}) {
                Text("Browse")
            }.walletButtonStyle()
//            
//            Button(action: {pathManager.path.append(Destination.disconnect(walletID: walletID))}) {
//                Text("Disconnect")
//            }
            .walletButtonStyle()
        }.task {
            print("RENDER: ProviderView")
        }
    }
}
