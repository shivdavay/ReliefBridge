// ReliefBridge/ViewModels/CarbonEngineViewModel.swift

import Foundation
import SwiftUI
import Combine

enum AuditReportState: Equatable {
    case idle
    case compiling
    case complete
}

struct AuditReportPoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulativeCarbonSaved: Double
}

func progressRingColor(progressFraction: Double, daysRemaining: Int) -> Color {
    if progressFraction >= 1.0 {
        return Theme.Colors.efficiencyGreen
    } else if progressFraction < Thresholds.quotaWarningFraction && daysRemaining < Thresholds.quotaWarningDaysRemaining {
        return Theme.Colors.alertOrange
    } else {
        return Theme.Colors.aqua
    }
}

final class CarbonEngineViewModel: ObservableObject {

    @Published private(set) var selectedCarrier: CargoCarrier = .fedex
    @Published private(set) var ledgerBlocks: [LedgerBlock] = []
    @Published private(set) var progressFraction: Double = 0.0
    @Published private(set) var ringColor: Color = Theme.Colors.aqua
    @Published private(set) var totalCarbonSaved: Double = 0.0
    @Published private(set) var quotaRemaining: Double = 0.0
    @Published private(set) var daysRemaining: Int = 0
    @Published private(set) var verifiedFlightCount: Int = 0
    @Published private(set) var quarterlyTarget: Double = 0.0
    @Published private(set) var annualGoal: Double = 0.0
    @Published private(set) var retrofittedAircraftCount: Int = 0
    @Published private(set) var annualSavingsPerKitUSD: Double = 0.0
    @Published private(set) var annualFleetSavingsUSD: Double = 0.0
    @Published private(set) var annualFuelSavedFleetKg: Double = 0.0
    @Published private(set) var annualCarbonSavedPerKitTons: Double = 0.0
    @Published private(set) var averageCarbonPerFlight: Double = 0.0
    @Published private(set) var auditReportPoints: [AuditReportPoint] = []
    @Published var auditReportState: AuditReportState = .idle

    private let dataService: SimulatedDataService
    private var cancellables = Set<AnyCancellable>()
    private var auditReportTask: Task<Void, Never>?

    var totalCarbonSavedString: String {
        String(format: "%.1f t", totalCarbonSaved)
    }

    var quotaRemainingString: String {
        quotaRemaining > 0 ? String(format: "%.1f t to quarterly goal", quotaRemaining) : "Quarterly goal achieved"
    }

    var annualGoalString: String {
        String(format: "%.0f t annual company goal", annualGoal)
    }

    var daysRemainingString: String {
        "\(daysRemaining) days left in quarter"
    }

    var annualSavingsPerKitString: String {
        currencyString(for: annualSavingsPerKitUSD)
    }

    var annualFleetSavingsString: String {
        currencyString(for: annualFleetSavingsUSD)
    }

    var annualFuelSavedFleetString: String {
        String(format: "%.0f kg", annualFuelSavedFleetKg)
    }

    init(dataService: SimulatedDataService) {
        self.dataService = dataService
        bindToDataService()
    }

    private func bindToDataService() {
        Publishers.CombineLatest(dataService.$ledgerBlocks, dataService.$selectedCarrier)
            .map { [weak self] blocks, carrier -> CarbonSnapshot in
                guard let self else { return .empty(for: carrier) }

                let profile = self.dataService.profile(for: carrier)
                let filteredBlocks = blocks
                    .filter { $0.carrier == carrier }
                    .sorted { $0.timestamp > $1.timestamp }

                let totalCarbonSaved = filteredBlocks.reduce(0.0) { $0 + $1.carbonSavedMetricTons }
                let fraction = profile.quarterlyCarbonTargetTons == 0
                    ? 0.0
                    : totalCarbonSaved / profile.quarterlyCarbonTargetTons
                let daysRemaining = self.daysRemainingInQuarter()
                let points = self.buildAuditReportPoints(from: filteredBlocks)
                let annualFleetSavingsUSD = profile.annualSavingsPerKitUSD * Double(profile.retrofittedAircraftCount)
                let annualFuelSavedFleetKg = profile.annualFuelSavedPerKitKg * Double(profile.retrofittedAircraftCount)

                return CarbonSnapshot(
                    carrier: carrier,
                    blocks: filteredBlocks,
                    fraction: fraction,
                    ringColor: progressRingColor(progressFraction: fraction, daysRemaining: daysRemaining),
                    totalCarbonSaved: totalCarbonSaved,
                    quotaRemaining: max(profile.quarterlyCarbonTargetTons - totalCarbonSaved, 0),
                    daysRemaining: daysRemaining,
                    verifiedFlightCount: filteredBlocks.count,
                    quarterlyTarget: profile.quarterlyCarbonTargetTons,
                    annualGoal: profile.annualCarbonGoalTons,
                    retrofittedAircraftCount: profile.retrofittedAircraftCount,
                    annualSavingsPerKitUSD: profile.annualSavingsPerKitUSD,
                    annualFleetSavingsUSD: annualFleetSavingsUSD,
                    annualFuelSavedFleetKg: annualFuelSavedFleetKg,
                    annualCarbonSavedPerKitTons: profile.annualCarbonSavedPerKitTons,
                    averageCarbonPerFlight: filteredBlocks.isEmpty ? 0.0 : totalCarbonSaved / Double(filteredBlocks.count),
                    auditReportPoints: points
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.selectedCarrier = snapshot.carrier
                self?.ledgerBlocks = snapshot.blocks
                self?.progressFraction = snapshot.fraction
                self?.ringColor = snapshot.ringColor
                self?.totalCarbonSaved = snapshot.totalCarbonSaved
                self?.quotaRemaining = snapshot.quotaRemaining
                self?.daysRemaining = snapshot.daysRemaining
                self?.verifiedFlightCount = snapshot.verifiedFlightCount
                self?.quarterlyTarget = snapshot.quarterlyTarget
                self?.annualGoal = snapshot.annualGoal
                self?.retrofittedAircraftCount = snapshot.retrofittedAircraftCount
                self?.annualSavingsPerKitUSD = snapshot.annualSavingsPerKitUSD
                self?.annualFleetSavingsUSD = snapshot.annualFleetSavingsUSD
                self?.annualFuelSavedFleetKg = snapshot.annualFuelSavedFleetKg
                self?.annualCarbonSavedPerKitTons = snapshot.annualCarbonSavedPerKitTons
                self?.averageCarbonPerFlight = snapshot.averageCarbonPerFlight
                self?.auditReportPoints = snapshot.auditReportPoints
            }
            .store(in: &cancellables)
    }

    func generateAuditReport() {
        auditReportTask?.cancel()
        auditReportState = .compiling

        auditReportTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard let self, !Task.isCancelled else { return }
            await self.setAuditReportState(.complete)
        }
    }

    func resetAuditReport() {
        auditReportTask?.cancel()
        auditReportTask = nil
        auditReportState = .idle
    }

    private func buildAuditReportPoints(from blocks: [LedgerBlock]) -> [AuditReportPoint] {
        var runningTotal = 0.0

        return blocks
            .sorted { $0.timestamp < $1.timestamp }
            .map { block in
                runningTotal += block.carbonSavedMetricTons
                return AuditReportPoint(date: block.timestamp, cumulativeCarbonSaved: runningTotal)
            }
    }

    private func daysRemainingInQuarter() -> Int {
        let calendar = Calendar.current
        let now = Date()

        guard let currentQuarter = calendar.dateInterval(of: .quarter, for: now) else {
            return 0
        }

        let components = calendar.dateComponents([.day], from: now, to: currentQuarter.end)
        return max(components.day ?? 0, 0)
    }

    private func currencyString(for amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    @MainActor
    private func setAuditReportState(_ state: AuditReportState) {
        auditReportState = state
    }

    deinit {
        auditReportTask?.cancel()
    }
}

private struct CarbonSnapshot {
    let carrier: CargoCarrier
    let blocks: [LedgerBlock]
    let fraction: Double
    let ringColor: Color
    let totalCarbonSaved: Double
    let quotaRemaining: Double
    let daysRemaining: Int
    let verifiedFlightCount: Int
    let quarterlyTarget: Double
    let annualGoal: Double
    let retrofittedAircraftCount: Int
    let annualSavingsPerKitUSD: Double
    let annualFleetSavingsUSD: Double
    let annualFuelSavedFleetKg: Double
    let annualCarbonSavedPerKitTons: Double
    let averageCarbonPerFlight: Double
    let auditReportPoints: [AuditReportPoint]

    static func empty(for carrier: CargoCarrier) -> CarbonSnapshot {
        CarbonSnapshot(
            carrier: carrier,
            blocks: [],
            fraction: 0,
            ringColor: Theme.Colors.aqua,
            totalCarbonSaved: 0,
            quotaRemaining: 0,
            daysRemaining: 0,
            verifiedFlightCount: 0,
            quarterlyTarget: 0,
            annualGoal: 0,
            retrofittedAircraftCount: 0,
            annualSavingsPerKitUSD: 0,
            annualFleetSavingsUSD: 0,
            annualFuelSavedFleetKg: 0,
            annualCarbonSavedPerKitTons: 0,
            averageCarbonPerFlight: 0,
            auditReportPoints: []
        )
    }
}
