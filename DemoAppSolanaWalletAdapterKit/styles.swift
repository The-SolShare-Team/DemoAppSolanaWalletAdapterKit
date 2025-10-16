//
//  styles.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-15.
//

// A convenient place to put styles to avoid clutter in demo app functional views

import Foundation
import SwiftUI

//make a view fill the whole screen with background black (better on my eyes)
extension View {
    func blackScreenStyle() -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            self
        }
    }
}


//connect to wallet button styles
struct WalletButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ? Color.purple.opacity(0.7) : Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
            .font(.headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

extension View {
    func walletButtonStyle() -> some View {
        self.buttonStyle(WalletButtonStyle())
    }
}


//wallet icon style when opening wallet selection UI

extension Image {
    func walletIconStyle() -> some View {
        self
            .resizable()
            .frame(width: 40, height: 40)
            .foregroundColor(.blue)
    }
}


// styles for the individual wallet row components
extension View {
    func walletNameStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(Color.white)
        }
        
    func detectedTextStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(.green)
    }
    func walletRowBackground() -> some View {
            self
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
    }
    func plainButtonStyle() -> some View {
        self
            .buttonStyle(PlainButtonStyle())
    }
}

// styles for the big wallet connection component
extension View {
    func connectTextStyle() -> some View {
        self
            .font(.title)
            .foregroundStyle(Color.white)
            .padding()
    }
}


