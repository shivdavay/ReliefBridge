// ReliefBridge/Views/FleetCommand/KPICardView.swift
// Individual KPI metric card displayed in the Fleet Command carousel.
// Validates: Requirements 2.3, 2.4, 2.5, 2.6, 2.7

import SwiftUI

/// A fixed-width card displaying a single fleet-wide KPI metric.
///
/// - `card.title`: label at the top
/// - `card.value`: large monospaced readout, Efficiency Green when healthy, white otherwise
/// - `card.unit`: small unit label below the value
struct KPICardView: View {

    let card: KPICard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(card.title)
                .font(Theme.Fonts.sansSerif(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // Value
            Text(card.value)
                .font(Theme.Fonts.monospacedDigit(size: 26, weight: .bold))
                .foregroundColor(card.isHealthy ? Theme.Colors.efficiencyGreen : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // Unit
            Text(card.unit)
                .font(Theme.Fonts.sansSerif(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(14)
        .frame(width: 160, height: 110, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            card.isHealthy
                                ? Theme.Colors.efficiencyGreen.opacity(0.25)
                                : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
    }
}
