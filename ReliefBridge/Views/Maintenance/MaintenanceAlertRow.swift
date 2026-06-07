// ReliefBridge/Views/Maintenance/MaintenanceAlertRow.swift
// Individual maintenance alert row displaying description, affected component, recommended action, and severity badge.
// Validates: Requirements 6.5, 6.6

import SwiftUI

// MARK: - MaintenanceAlertRow

/// A row view displaying a single predictive maintenance alert.
///
/// Layout:
/// ```
/// ┌────────────────────────────────────────────────────────┐
/// │ ⚠️  CRITICAL                                           │
/// │     Micro-pore blockage detected in Zone A1           │
/// │     Component: Port Wing Lattice                      │
/// │     Action: Pneumatic purge at next C-Check           │
/// └────────────────────────────────────────────────────────┘
/// ```
///
/// Displays:
/// - A severity badge (CRITICAL / WARNING / INFO) with color-coded background
/// - Alert description
/// - Affected component name
/// - Recommended action string
struct MaintenanceAlertRow: View {

    let alert: MaintenanceAlert

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // MARK: Severity icon
            Image(systemName: severityIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(severityColor)
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            // MARK: Alert details
            VStack(alignment: .leading, spacing: 8) {
                // Severity badge
                HStack(spacing: 6) {
                    Text(severityLabel)
                        .font(Theme.Fonts.sansSerif(size: 11, weight: .bold))
                        .foregroundColor(Theme.Colors.background)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(severityColor)
                        )

                    Text("\(alert.flightIdentifier) • \(alert.tailNumber)")
                        .font(Theme.Fonts.monospacedDigit(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryText)

                    Spacer()

                    // Timestamp
                    Text(formattedTimestamp)
                        .font(Theme.Fonts.monospacedDigit(size: 11))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                // Description
                Text(alert.description)
                    .font(Theme.Fonts.sansSerif(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                // Affected component
                HStack(spacing: 4) {
                    Text("Component:")
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(alert.affectedComponent)
                        .font(Theme.Fonts.sansSerif(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.primaryText)
                }

                // Recommended action
                HStack(alignment: .top, spacing: 4) {
                    Text("Action:")
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(alert.recommendedAction)
                        .font(Theme.Fonts.sansSerif(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.efficiencyGreen)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .glassPanel(accent: severityColor, cornerRadius: 20)
    }

    // MARK: - Computed Properties

    /// Returns the SF Symbol icon name for the alert severity.
    private var severityIcon: String {
        switch alert.severity {
        case .critical:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    /// Returns the color for the alert severity.
    private var severityColor: Color {
        switch alert.severity {
        case .critical:
            return Theme.Colors.alertOrange
        case .warning:
            return Color.orange
        case .info:
            return Color.blue
        }
    }

    /// Returns the uppercase label for the alert severity.
    private var severityLabel: String {
        switch alert.severity {
        case .critical:
            return "CRITICAL"
        case .warning:
            return "WARNING"
        case .info:
            return "INFO"
        }
    }

    /// Formats the alert timestamp as a relative time string (e.g., "2m ago").
    private var formattedTimestamp: String {
        let interval = Date().timeIntervalSince(alert.generatedAt)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        MaintenanceAlertRow(
            alert: MaintenanceAlert(
                id: UUID(),
                carrier: .fedex,
                tailNumber: "N852FD",
                flightIdentifier: "FX38",
                affectedComponent: "Port Wing Lattice",
                description: "Micro-pore blockage detected in Zone A1",
                recommendedAction: "Pneumatic purge at next C-Check",
                severity: .critical,
                generatedAt: Date().addingTimeInterval(-120)
            )
        )

        MaintenanceAlertRow(
            alert: MaintenanceAlert(
                id: UUID(),
                carrier: .ups,
                tailNumber: "N570UP",
                flightIdentifier: "5X223",
                affectedComponent: "Starboard Flap Actuator",
                description: "Flow uniformity below optimal threshold",
                recommendedAction: "Monitor during next flight cycle",
                severity: .warning,
                generatedAt: Date().addingTimeInterval(-3600)
            )
        )

        MaintenanceAlertRow(
            alert: MaintenanceAlert(
                id: UUID(),
                carrier: .dhl,
                tailNumber: "D-AJFK",
                flightIdentifier: "QY364",
                affectedComponent: "Ram Air Intake Sensor",
                description: "Sensor calibration recommended",
                recommendedAction: "Schedule calibration at next maintenance window",
                severity: .info,
                generatedAt: Date().addingTimeInterval(-86400)
            )
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
#endif
