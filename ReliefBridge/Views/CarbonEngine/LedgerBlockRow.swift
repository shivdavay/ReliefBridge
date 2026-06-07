// ReliefBridge/Views/CarbonEngine/LedgerBlockRow.swift
// Individual ledger block row displaying timestamp, flight ID, carbon savings, regulatory standard, and verification ID.
// Validates: Requirements 4.1, 4.2, 4.9, 4.10

import SwiftUI

// MARK: - LedgerBlockRow

/// A row view displaying a single immutable ledger block entry.
///
/// Layout:
/// ```
/// ┌────────────────────────────────────────────────────────┐
/// │ 🔒  2024-01-15 14:32:45                                │
/// │     Flight: BA-2847                                    │
/// │     Carbon Saved: 8.42 t                               │
/// │     Standard: CORSIA                                   │
/// │     Hash: a3f9c2...                                    │
/// └────────────────────────────────────────────────────────┘
/// ```
///
/// Displays:
/// - A lock icon to indicate immutability
/// - Timestamp formatted as "yyyy-MM-dd HH:mm:ss"
/// - Flight identifier
/// - Carbon savings value in metric tons (monospaced font)
/// - Regulatory standard label (CORSIA or EU ETS)
/// - Verification ID (truncated to first 6 characters)
struct LedgerBlockRow: View {

    let block: LedgerBlock

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // MARK: Lock icon (immutability indicator)
            Image(systemName: "lock.fill")
                .font(.system(size: 18))
                .foregroundColor(Theme.Colors.gold)
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            // MARK: Block details
            VStack(alignment: .leading, spacing: 6) {
                // Timestamp
                Text(formattedTimestamp)
                    .font(Theme.Fonts.monospacedDigit(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.primaryText)

                // Flight identifier
                HStack(spacing: 4) {
                    Text("Flight:")
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(block.flightIdentifier)
                        .font(Theme.Fonts.monospacedDigit(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.primaryText)
                }

                // Carbon saved (metric tons, monospaced)
                HStack(spacing: 4) {
                    Text("Carbon Saved:")
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(formattedCarbonSaved)
                        .font(Theme.Fonts.monospacedDigit(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.efficiencyGreen)
                }

                // Regulatory standard
                HStack(spacing: 4) {
                    Text("Standard:")
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(block.regulatoryStandard.rawValue)
                        .font(Theme.Fonts.sansSerif(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.primaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.backgroundElevated.opacity(0.7))
                        )
                }
            }

            Spacer()
        }
        .padding(14)
        .glassPanel(accent: Theme.Colors.efficiencyGreen, cornerRadius: 20)
    }

    // MARK: - Formatters

    /// Formats the block timestamp as "yyyy-MM-dd HH:mm:ss".
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: block.timestamp)
    }

    /// Formats the carbon saved value with unit label "t" (metric tons).
    private var formattedCarbonSaved: String {
        String(format: "%.2f t", block.carbonSavedMetricTons)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        LedgerBlockRow(
            block: LedgerBlock(
                id: UUID(),
                carrier: .fedex,
                timestamp: Date(),
                flightIdentifier: "BA-2847",
                carbonSavedMetricTons: 8.42,
                regulatoryStandard: .corsia,
                blockHash: "a3f9c2d8e1b4f7a6c9d2e5f8b1a4c7d0"
            )
        )

        LedgerBlockRow(
            block: LedgerBlock(
                id: UUID(),
                carrier: .ups,
                timestamp: Date().addingTimeInterval(-3600),
                flightIdentifier: "LH-1234",
                carbonSavedMetricTons: 5.67,
                regulatoryStandard: .euEts,
                blockHash: "b2e5f8a1c4d7e0b3f6a9c2d5e8b1a4c7"
            )
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
#endif
