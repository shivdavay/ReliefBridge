// ReliefBridge/Views/FleetCommand/FleetFilterView.swift
// Filter sheet for Fleet Command — aircraft type and region.
// Validates: Requirements 2.10, 2.11

import SwiftUI

/// A modal sheet that lets the user filter the fleet by aircraft type and region.
///
/// Bound to `viewModel.filterCriteria`. Changes are applied immediately on "Apply"
/// and cleared on "Clear".
struct FleetFilterView: View {

    @ObservedObject var viewModel: FleetCommandViewModel

    /// All distinct aircraft types present in the fleet (passed in from the parent view).
    let availableTypes: [String]

    /// All distinct regions present in the fleet (passed in from the parent view).
    let availableRegions: [String]

    @Environment(\.dismiss) private var dismiss

    // Local draft state — only committed on "Apply"
    @State private var draftType: String? = nil
    @State private var draftRegion: String? = nil
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Aircraft Type
                Section("Aircraft Type") {
                    Picker("Type", selection: $draftType) {
                        Text("All Types").tag(Optional<String>.none)
                        ForEach(availableTypes, id: \.self) { type in
                            Text(type).tag(Optional(type))
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: Region
                Section("Region") {
                    Picker("Region", selection: $draftRegion) {
                        Text("All Regions").tag(Optional<String>.none)
                        ForEach(availableRegions, id: \.self) { region in
                            Text(region).tag(Optional(region))
                        }
                    }
                    .pickerStyle(.menu)
                }

            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Filter Fleet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        viewModel.filterCriteria = FilterCriteria()
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.alertOrange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        viewModel.filterCriteria = FilterCriteria(
                            aircraftType: draftType,
                            region: draftRegion
                        )
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.efficiencyGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Populate draft from current criteria
            draftType   = viewModel.filterCriteria.aircraftType
            draftRegion = viewModel.filterCriteria.region
        }
    }
}
