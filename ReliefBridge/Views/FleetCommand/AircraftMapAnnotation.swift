// ReliefBridge/Views/FleetCommand/AircraftMapAnnotation.swift
// Custom map annotation view for airborne aircraft.
// Validates: Requirements 2.2

import SwiftUI
import MapKit

/// A pulsing dot annotation rendered on the map for each airborne aircraft.
///
/// Displays:
/// - A pulsing circle in Efficiency Green (#00FF87) to indicate live position
/// - The aircraft's tail number label below the dot
struct AircraftMapAnnotation: View {

    let aircraft: Aircraft

    /// Controls the scale of the outer pulse ring.
    @State private var isPulsing: Bool = false

    private var accentColor: Color {
        switch aircraft.carrier {
        case .fedex:
            return Theme.Colors.aqua
        case .ups:
            return Theme.Colors.gold
        case .dhl:
            return Theme.Colors.efficiencyGreen
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(accentColor.opacity(0.28))
                    .frame(width: isPulsing ? 28 : 16, height: isPulsing ? 28 : 16)
                    .opacity(isPulsing ? 0.0 : 0.6)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                        value: isPulsing
                    )

                // Inner solid dot
                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.background, lineWidth: 1.5)
                    )
            }

            VStack(spacing: 2) {
                Text(aircraft.flightIdentifier)
                    .font(Theme.Fonts.monospacedDigit(size: 10, weight: .semibold))
                    .foregroundColor(.white)

                Text(aircraft.routeLabel)
                    .font(Theme.Fonts.sansSerif(size: 9, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.Colors.background.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(accentColor.opacity(0.34), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            isPulsing = true
        }
    }
}
