// A convenient place to put styles to avoid clutter in demo app functional views

import Foundation
import SwiftUI

// Connect to wallet button styles
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

// Wallet icon style when opening wallet selection UI
extension Image {
    func walletIconStyle() -> some View {
        self
            .resizable()
            .frame(width: 40, height: 40)
            .foregroundColor(.purple)
    }
}

// Styles for the individual wallet row components
extension View {
    func walletNameStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(Color.primary)
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

// Styles for the big wallet connection component
extension View {
    func connectTextStyle() -> some View {
        self
            .font(.title)
            .foregroundColor(Color.primary)
            .padding()
    }
}

// Additional card styles
extension View {
    func cardStyle(backgroundColor: Color = Color(.systemBackground)) -> some View {
        self
            .padding()
            .background(backgroundColor)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    func sectionCardStyle() -> some View {
        self
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(15)
    }
}

// Status indicator styles
extension View {
    func statusDotStyle(color: Color) -> some View {
        self
            .frame(width: 8, height: 8)
            .background(color)
            .clipShape(Circle())
    }
}

// Loading overlay style
extension View {
    func loadingOverlay(isLoading: Bool) -> some View {
        self
            .overlay(
                Group {
                    if isLoading {
                        Color.black.opacity(0.1)
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                }
            )
    }
}