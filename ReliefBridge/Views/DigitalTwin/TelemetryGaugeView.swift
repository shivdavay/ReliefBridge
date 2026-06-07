// ReliefBridge/Views/DigitalTwin/TelemetryGaugeView.swift
// Reusable semicircular arc gauge component for telemetry values.
// Validates: Requirements 3.4, 3.5, 3.6, 3.7, 3.8

import SwiftUI

// MARK: - TelemetryGaugeView

/// A reusable semicircular arc gauge that visualises a single telemetry value.
///
/// The gauge draws a background arc and a filled arc proportional to the
/// normalised position of `value` within `[minValue, maxValue]`.  The fill
/// color is driven by the `gaugeColor` parameter so the caller can apply
/// threshold-based coloring (Efficiency Green / Alert Orange) without this
/// view needing to know about thresholds.
///
/// Layout:
/// ```
///   ┌──────────────────────────────┐
///   │       ╭──────────╮           │
///   │      ╱            ╲          │
///   │     │   1013.4 hPa │         │
///   │      ╲            ╱          │
///   │       ╰──────────╯           │
///   │    Ram Air Intake Pressure   │
///   └──────────────────────────────┘
/// ```
struct TelemetryGaugeView: View {

    // MARK: - Inputs

    let title: String
    let value: Double
    let unit: String
    let minValue: Double
    let maxValue: Double
    let gaugeColor: Color

    // MARK: - Private Helpers

    /// Normalised fill fraction in [0, 1].
    private var fraction: Double {
        guard maxValue > minValue else { return 0 }
        return max(0, min(1, (value - minValue) / (maxValue - minValue)))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {
            // Arc gauge drawn with Canvas
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.72)
                let radius = min(size.width, size.height) * 0.42

                // Semicircle spans from 180° to 360° (bottom half hidden)
                let startAngle = Angle.degrees(180)
                let endAngle   = Angle.degrees(360)

                // --- Background track ---
                var trackPath = Path()
                trackPath.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                context.stroke(
                    trackPath,
                    with: .color(Color.white.opacity(0.12)),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )

                // --- Filled arc ---
                let fillEnd = Angle.degrees(180 + fraction * 180)
                var fillPath = Path()
                fillPath.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: fillEnd,
                    clockwise: false
                )
                context.stroke(
                    fillPath,
                    with: .color(gaugeColor.opacity(0.18)),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                context.stroke(
                    fillPath,
                    with: .color(gaugeColor),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
            }
            .frame(height: 90)
            .overlay(alignment: .center) {
                // Value readout — positioned in the visual centre of the arc
                VStack(spacing: 2) {
                    Text(formattedValue)
                        .font(Theme.Fonts.monospacedDigit(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryText)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .shadow(color: gaugeColor.opacity(0.2), radius: 10, x: 0, y: 0)
                    Text(unit)
                        .font(Theme.Fonts.monospacedDigit(size: 11))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .offset(y: 14)
            }

            // Title label
            Text(title)
                .font(Theme.Fonts.sansSerif(size: 11))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .glassPanel(accent: gaugeColor, cornerRadius: 20)
        .animation(.easeInOut(duration: 0.55), value: value)
    }

    // MARK: - Formatting

    private var formattedValue: String {
        if unit == "%" {
            return String(format: "%.1f", value)
        }
        if value == value.rounded() && abs(value) < 10_000 {
            return String(format: "%.0f", value)
        }
        if abs(value) >= 10 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        TelemetryGaugeView(
            title: "Ram Air Intake Pressure",
            value: 1013.4,
            unit: "hPa",
            minValue: 950,
            maxValue: 1100,
            gaugeColor: Theme.Colors.efficiencyGreen
        )
        TelemetryGaugeView(
            title: "Gyroid Flow Uniformity",
            value: 0.65,
            unit: "%",
            minValue: 0,
            maxValue: 1,
            gaugeColor: Theme.Colors.alertOrange
        )
        TelemetryGaugeView(
            title: "Jet Sheet Velocity",
            value: 265.0,
            unit: "m/s",
            minValue: 200,
            maxValue: 320,
            gaugeColor: Theme.Colors.efficiencyGreen
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
#endif
