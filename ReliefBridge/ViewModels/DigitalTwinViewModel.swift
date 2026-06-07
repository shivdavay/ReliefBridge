// ReliefBridge/ViewModels/DigitalTwinViewModel.swift
// ViewModel for the Digital Twin and Telemetry module.
// Validates: Requirements 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10

import Foundation
import SwiftUI
import Combine

// MARK: - Gauge Color Logic

/// Pure function: returns the gauge color for a given value and threshold.
///
/// - Returns: `Theme.Colors.alertOrange` when the threshold is breached,
///            `Theme.Colors.efficiencyGreen` otherwise.
///
/// Extracted as a free function so it can be tested independently of the ViewModel.
func gaugeColor(value: Double, threshold: Double, alertsWhenBelow: Bool = false) -> Color {
    if alertsWhenBelow {
        return value < threshold ? Theme.Colors.alertOrange : Theme.Colors.efficiencyGreen
    }
    return value > threshold ? Theme.Colors.alertOrange : Theme.Colors.efficiencyGreen
}

// MARK: - DigitalTwinViewModel

/// ViewModel for the Digital Twin module.
///
/// Accepts a `tailNumber` and a `SimulatedDataService`, subscribes to live
/// telemetry updates, and exposes gauge values, drag coefficient history,
/// ReliefBridge engagement state, and computed gauge colors.
///
/// When no telemetry snapshot exists for the given tail number (e.g. the
/// aircraft is on the ground), all gauge values default to `0.0` and
/// `noTelemetryAvailable` is set to `true`.
final class DigitalTwinViewModel: ObservableObject {

    // MARK: - Published Outputs

    /// Current Ram Air Intake Pressure (hPa). `0.0` when no telemetry.
    @Published var ramAirIntakePressure: Double = 0.0

    /// Current Gyroid Internal Flow Uniformity (0.0 – 1.0). `0.0` when no telemetry.
    @Published var gyroidFlowUniformity: Double = 0.0

    /// Current Jet Sheet Velocity (m/s). `0.0` when no telemetry.
    @Published var jetSheetVelocity: Double = 0.0

    /// Current boundary-layer retention (0.0 – 1.0). `0.0` when no telemetry.
    @Published var boundaryLayerRetention: Double = 0.0

    /// Estimated drag reduction provided by the retrofit (0.0 – 1.0). `0.0` when no telemetry.
    @Published var dragReductionPercent: Double = 0.0

    /// Projected 1-year fuel gain for the selected aircraft.
    @Published var projectedAnnualFuelGainKg: Double = 0.0

    /// Drag coefficient reduction history for the current flight envelope.
    @Published var dragCoefficientHistory: [DragDataPoint] = []

    /// Whether the ReliefBridge system is engaged on this aircraft.
    @Published var isReliefBridgeEngaged: Bool = false

    /// `true` when no telemetry snapshot exists for the tail number.
    @Published var noTelemetryAvailable: Bool = true

    // MARK: - Computed Color Properties

    /// Gauge color for Ram Air Intake Pressure.
    /// Alert Orange if `ramAirIntakePressure > Thresholds.ramAirPressureWarning`.
    var ramAirPressureColor: Color {
        gaugeColor(value: ramAirIntakePressure, threshold: Thresholds.ramAirPressureWarning)
    }

    /// Gauge color for Gyroid Internal Flow Uniformity.
    /// Alert Orange if `gyroidFlowUniformity < Thresholds.gyroidFlowWarning`.
    var gyroidFlowColor: Color {
        gaugeColor(value: gyroidFlowUniformity, threshold: Thresholds.gyroidFlowWarning, alertsWhenBelow: true)
    }

    /// Gauge color for Jet Sheet Velocity.
    /// Alert Orange if `jetSheetVelocity > Thresholds.jetSheetVelocityWarning`.
    var jetSheetVelocityColor: Color {
        gaugeColor(value: jetSheetVelocity, threshold: Thresholds.jetSheetVelocityWarning)
    }

    // MARK: - Private State

    private let tailNumber: String
    private let dataService: SimulatedDataService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    /// Creates a new `DigitalTwinViewModel` for the given aircraft tail number.
    ///
    /// - Parameters:
    ///   - tailNumber: The unique tail number of the aircraft to observe.
    ///   - dataService: The shared `SimulatedDataService` instance.
    init(tailNumber: String, dataService: SimulatedDataService) {
        self.tailNumber = tailNumber
        self.dataService = dataService
        bindToDataService()
    }

    // MARK: - Binding

    private func bindToDataService() {
        // Observe telemetry dictionary changes and extract the snapshot for our tail number.
        dataService.$telemetry
            .combineLatest(dataService.$aircraft)
            .map { [tailNumber] telemetry, aircraft -> (TelemetrySnapshot?, Bool) in
                let snapshot = telemetry[tailNumber]
                let engaged = aircraft.first(where: { $0.tailNumber == tailNumber })?.isReliefBridgeEngaged ?? false
                return (snapshot, engaged)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot, engaged in
                guard let self else { return }
                if let snapshot {
                    self.ramAirIntakePressure   = snapshot.ramAirIntakePressure
                    self.gyroidFlowUniformity   = snapshot.gyroidFlowUniformity
                    self.jetSheetVelocity       = snapshot.jetSheetVelocity
                    self.boundaryLayerRetention = snapshot.boundaryLayerRetention
                    self.dragReductionPercent   = snapshot.dragReductionPercent
                    self.projectedAnnualFuelGainKg = snapshot.projectedAnnualFuelGainKg
                    self.dragCoefficientHistory = snapshot.dragCoefficientHistory
                    self.noTelemetryAvailable   = false
                } else {
                    self.ramAirIntakePressure   = 0.0
                    self.gyroidFlowUniformity   = 0.0
                    self.jetSheetVelocity       = 0.0
                    self.boundaryLayerRetention = 0.0
                    self.dragReductionPercent   = 0.0
                    self.projectedAnnualFuelGainKg = 0.0
                    self.dragCoefficientHistory = []
                    self.noTelemetryAvailable   = true
                }
                self.isReliefBridgeEngaged = engaged
            }
            .store(in: &cancellables)
    }
}
