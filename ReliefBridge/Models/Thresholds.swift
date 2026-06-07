// ReliefBridge/Models/Thresholds.swift
// Warning threshold constants used across all modules.

import Foundation

/// Namespace for all warning threshold constants used in ReliefBridge Insight.
///
/// These values drive gauge color changes, progress ring colors, and
/// acoustic compliance indicators throughout the application.
enum Thresholds {
    /// Ram Air Intake Pressure warning threshold (hPa).
    /// Gauges exceed this value → Alert Orange.
    static let ramAirPressureWarning: Double = 1050.0

    /// Gyroid Internal Flow Uniformity warning threshold (0.0 – 1.0).
    /// Values below this → Alert Orange.
    static let gyroidFlowWarning: Double = 0.70

    /// Jet Sheet Velocity warning threshold (m/s).
    /// Values above this → Alert Orange.
    static let jetSheetVelocityWarning: Double = 280.0

    /// Micro-pore blockage risk warning threshold (0.0 – 1.0).
    /// Lattice zones above this → Alert Orange on heat map.
    static let latticeBlockageWarning: Double = 0.65

    /// Carbon quota fraction below which the progress ring turns Alert Orange
    /// (when combined with `quotaWarningDaysRemaining`).
    static let quotaWarningFraction: Double = 0.75

    /// Days remaining in the quarter below which the quota warning activates.
    static let quotaWarningDaysRemaining: Int = 30

    /// Heathrow Airport noise curfew threshold (dB).
    static let heathrowNoiseCurfewDB: Double = 87.0

    /// Frankfurt Airport noise curfew threshold (dB).
    static let frankfurtNoiseCurfewDB: Double = 85.0
}
