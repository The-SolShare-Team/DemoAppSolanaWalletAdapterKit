//
//  providerMethodsView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-11-02.
//
import SwiftUI
import Foundation


struct providerMethodsView : View {
    @EnvironmentObject var pathManager: NavigationPathManager
    
    var body : some View {
        VStack {
            Button(action: {pathManager.path.append(Destination.signTransaction)} ) {
                Text("Sign Transaction")
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
            
            Button(action: {pathManager.path.append(Destination.disconnect)}) {
                Text("Disconnect")
            }
            .walletButtonStyle()
        }
    }
}
