// ReliefBridge/Views/CarbonEngine/QuotaProgressRingView.swift
// Circular progress ring chart showing cumulative carbon savings as a percentage of the quarterly quota.
// Validates: Requirements 4.3, 4.4, 4.5

import SwiftUI

// MARK: - QuotaProgressRingView

/// A circular progress ring displaying the airline's cumulative carbon savings
/// as a percentage of the quarterly carbon-offset quota.
///
/// The ring is drawn using SwiftUI's `Canvas` API for precise control over
/// stroke color and fill fraction.
///
/// - Parameters:
///   - progressFraction: The cumulative savings as a fraction of the quarterly quota (0.0 – 1.0+).
///   - ringColor: The stroke color for the progress arc (driven by ViewModel logic).
///
/// The ring displays:
/// - A background track (gray, full circle)
/// - A foreground progress arc (colored, partial circle based on `progressFraction`)
/// - A centered percentage label (monospaced font)
/// - A subtitle label ("of Quarterly Quota")
struct QuotaProgressRingView: View {

    let progressFraction: Double
    let ringColor: Color
    let headline: String
    let supportingText: String

    // MARK: - Constants

    private let lineWidth: CGFloat = 18
    private let trackColor = Color.white.opacity(0.1)

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // MARK: Progress Ring Canvas
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - lineWidth / 2

                // Background track (full circle)
                let trackPath = Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270),
                        clockwise: false
                    )
                }
                context.stroke(
                    trackPath,
                    with: .color(trackColor),
                    lineWidth: lineWidth
                )

                // Foreground progress arc
                let progressAngle = 360.0 * min(progressFraction, 1.0)
                let progressPath = Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + progressAngle),
                        clockwise: false
                    )
                }
                context.stroke(
                    progressPath,
                    with: .color(ringColor.opacity(0.16)),
                    style: StrokeStyle(lineWidth: lineWidth + 10, lineCap: .round)
                )
                context.stroke(
                    progressPath,
                    with: .color(ringColor),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }
            .aspectRatio(1.0, contentMode: .fit)
            .overlay {
                // MARK: Centered percentage label
                VStack(spacing: 4) {
                    Text(formattedPercentage)
                        .font(Theme.Fonts.monospacedDigit(size: 42, weight: .bold))
                        .foregroundColor(Theme.Colors.primaryText)

                    Text(headline)
                        .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)

                    Text("of Quarterly Quota")
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            // MARK: Status message
            statusMessage
                .font(Theme.Fonts.sansSerif(size: 13, weight: .medium))
                .foregroundColor(ringColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(supportingText)
                .font(Theme.Fonts.sansSerif(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(16)
        .glassPanel(accent: ringColor, cornerRadius: 28)
    }

    // MARK: - Helpers

    /// Formats the progress fraction as a percentage string (e.g., "87%").
    private var formattedPercentage: String {
        let percentage = Int(round(progressFraction * 100))
        return "\(percentage)%"
    }

    /// Returns a status message based on the progress fraction and ring color.
    private var statusMessage: some View {
        Group {
            if progressFraction >= 1.0 {
                Text("Quarterly quota achieved!")
            } else if ringColor == Theme.Colors.alertOrange {
                Text("Below target with limited time remaining")
            } else {
                Text("On track to meet quarterly quota")
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("75% Progress - On Track") {
    VStack(spacing: 40) {
        QuotaProgressRingView(
            progressFraction: 0.75,
            ringColor: .accentColor,
            headline: "135.0 t saved",
            supportingText: "45.0 t to target"
        )
        .frame(height: 220)
    }
    .padding()
    .background(Theme.Colors.background)
}

#Preview("50% Progress - Warning") {
    VStack(spacing: 40) {
        QuotaProgressRingView(
            progressFraction: 0.50,
            ringColor: Theme.Colors.alertOrange,
            headline: "90.0 t saved",
            supportingText: "90.0 t to target"
        )
        .frame(height: 220)
    }
    .padding()
    .background(Theme.Colors.background)
}

#Preview("100% Progress - Complete") {
    VStack(spacing: 40) {
        QuotaProgressRingView(
            progressFraction: 1.0,
            ringColor: Theme.Colors.efficiencyGreen,
            headline: "180.0 t saved",
            supportingText: "Quota achieved"
        )
        .frame(height: 220)
    }
    .padding()
    .background(Theme.Colors.background)
}
#endif
