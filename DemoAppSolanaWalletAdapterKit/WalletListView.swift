//
////
////  WalletListView.swift
////  DemoAppSolanaWalletAdapterKit
////
//
//import SwiftUI
//
//struct WalletListView: View {
//    @EnvironmentObject private var viewModel: WalletViewModel
//    @EnvironmentObject var pathManager: NavigationPathManager
//
//    var body: some View {
//        List(viewModel.wallets, id: \.id) { wallet in
//            // Tapping a row now navigates to the details view
//            Button {
//                viewModel.selectedWallet = wallet
//                pathManager.path.append(Destination.walletDetails)
//            } label: {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(wallet.formattedPublicKey)
//                        .walletNameStyle()
//                
//                    Text(wallet.provider)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                }
//            }
//            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                Button("Disconnect", role: .destructive) {
//                    viewModel.disconnectWallet(wallet)
//                }
//            }
//        }
//        .navigationTitle("Wallets")
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button {
//                    pathManager.path.append(Destination.walletSelection)
//                } label: {
//                    Image(systemName: "plus")
//                }
//            }
//        }
//    }
//}
