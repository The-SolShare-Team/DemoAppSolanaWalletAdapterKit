//
//  NavigationPathManager.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-22.
//

import Foundation
import SwiftUI
import Combine

// ObservableObject managing NavigationPath with serialization to persistent storage
class NavigationPathManager: ObservableObject {
    @Published var path: NavigationPath

    private let storageKey = "navigationPath"

    // MARK: - Static helpers for persistence
    static func readSerializedData() -> Data? {
        return UserDefaults.standard.data(forKey: "navigationPath")
    }

    static func writeSerializedData(_ data: Data) {
        UserDefaults.standard.set(data, forKey: "navigationPath")
    }

    // MARK: - Init
    init() {
        if let data = Self.readSerializedData() {
            do {
                let representation = try JSONDecoder().decode(
                    NavigationPath.CodableRepresentation.self,
                    from: data
                )
                self.path = NavigationPath(representation)
            } catch {
                print("Failed to decode NavigationPath from storage: \(error)")
                self.path = NavigationPath()
            }
        } else {
            self.path = NavigationPath()
        }
    }

    // MARK: - Save
    func save() {
        guard let representation = path.codable else { return }
        do {
            let data = try JSONEncoder().encode(representation)
            Self.writeSerializedData(data)
        } catch {
            print("Failed to encode NavigationPath for storage: \(error)")
        }
    }

    // Optional: reset
    func reset() {
        path = NavigationPath()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    
}


enum Destination: Codable, Hashable {
    case signTransaction
    case signMessage
    case signAndSendTransaction
    case signAllTransactions
    case browse
    case disconnect
    case walletSelection
    case providerMethods
    // You can add more cases with associated values if needed
    // case transactionDetail(String)
    // case messageDetail(id: String)
}
