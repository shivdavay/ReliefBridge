// ReliefBridge/Views/ReliefBridge/SurplusRadarView.swift
// ReliefBridge — Surplus Radar.
//
// Register what you can give, then the app matches your surplus to live crises
// ranked by REAL distance (from your device location) + urgency. Tap a match to
// bridge it. Needs are live (USGS + GDACS); offers are your own data on device.

import SwiftUI
import MapKit

@available(iOS 17.0, macOS 14.0, *)
struct SurplusRadarView: View {

    @EnvironmentObject private var relief: ReliefService
    @State private var showAdd = false
    @State private var selectedNeed: Need? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    offersSection
                    matchesSection
                }
                .padding(20)
                .padding(.bottom, 30)
            }
            .background(Theme.AppBackdrop().ignoresSafeArea())
            .navigationTitle("Surplus Radar")
            #if os(iOS)
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .foregroundColor(Theme.Colors.efficiencyGreen)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddSurplusSheet().environmentObject(relief)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedNeed) { need in
                NeedDetailSheet(needID: need.id)
                    .environmentObject(relief)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Offers

    private var offersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("What you can give")
                    .font(Theme.Fonts.sansSerif(size: 15, weight: .bold))
                    .foregroundColor(Theme.Colors.primaryText)
                Spacer()
                if relief.userOrigin == nil {
                    Label("Locating…", systemImage: "location")
                        .font(Theme.Fonts.sansSerif(size: 11))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            if relief.surplusOffers.isEmpty {
                Text("Register supplies, skills, volunteer time, or blood you can offer. We'll match it to the nearest, most urgent live crises.")
                    .font(Theme.Fonts.sansSerif(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
                Button { showAdd = true } label: {
                    Label("Register your first offer", systemImage: "plus")
                        .font(Theme.Fonts.sansSerif(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.Colors.efficiencyGreen))
                }
                .buttonStyle(.plain)
            } else {
                ForEach(relief.surplusOffers) { offer in
                    HStack(spacing: 12) {
                        Image(systemName: offer.kind.symbolName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.Colors.background)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Theme.Colors.efficiencyGreen))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(offer.title)
                                .font(Theme.Fonts.sansSerif(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.primaryText)
                            Text(offer.detail.isEmpty ? offer.kind.label : offer.detail)
                                .font(Theme.Fonts.sansSerif(size: 12))
                                .foregroundColor(Theme.Colors.secondaryText)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button { relief.removeSurplus(offer) } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.Colors.surface))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(accent: Theme.Colors.efficiencyGreen, cornerRadius: 20)
    }

    // MARK: - Matches

    private var matchesSection: some View {
        let matches = relief.matchedNeeds(limit: 20)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.up.forward")
                    .foregroundColor(Theme.Colors.aqua)
                Text("Matches near you")
                    .font(Theme.Fonts.sansSerif(size: 15, weight: .bold))
                    .foregroundColor(Theme.Colors.primaryText)
                Spacer()
                Text("\(matches.count)")
                    .font(Theme.Fonts.monospacedDigit(size: 14, weight: .bold))
                    .foregroundColor(Theme.Colors.aqua)
            }

            if matches.isEmpty {
                Text("Waiting for live crisis data…")
                    .font(Theme.Fonts.sansSerif(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
            } else {
                ForEach(Array(matches.enumerated()), id: \.element.need.id) { _, match in
                    Button { selectedNeed = match.need } label: {
                        matchRow(need: match.need, distanceKm: match.distanceKm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 20)
    }

    private func matchRow(need: Need, distanceKm: Double?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: need.kind.symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.background)
                .frame(width: 38, height: 38)
                .background(Circle().fill(severityColor(need.severity)))
            VStack(alignment: .leading, spacing: 3) {
                Text(need.title)
                    .font(Theme.Fonts.sansSerif(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label(need.urgencyLabel, systemImage: "gauge.with.dots.needle.67percent")
                        .font(Theme.Fonts.sansSerif(size: 11, weight: .semibold))
                        .foregroundColor(severityColor(need.severity))
                    if let km = distanceKm {
                        Label(distanceText(km), systemImage: "location.fill")
                            .font(Theme.Fonts.sansSerif(size: 11))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            Spacer()
            if need.isBridged {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.Colors.efficiencyGreen)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.Colors.surface))
    }

    private func distanceText(_ km: Double) -> String {
        km < 1000 ? String(format: "%.0f km", km) : String(format: "%.1fk km", km / 1000)
    }

    private func severityColor(_ s: Severity) -> Color {
        switch s {
        case .red:    return Color(red: 1.0, green: 0.30, blue: 0.33)
        case .orange: return Theme.Colors.alertOrange
        case .green:  return Theme.Colors.efficiencyGreen
        }
    }
}

// MARK: - Add surplus sheet

@available(iOS 17.0, macOS 14.0, *)
struct AddSurplusSheet: View {
    @EnvironmentObject private var relief: ReliefService
    @Environment(\.dismiss) private var dismiss

    @State private var kind: ContributionKind = .supplies
    @State private var title: String = ""
    @State private var detail: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $kind) {
                        ForEach(ContributionKind.allCases) { k in
                            Label(k.label, systemImage: k.symbolName).tag(k)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("What you're offering") {
                    TextField("e.g. 200 water purification tablets", text: $title)
                    TextField("Details (optional)", text: $detail)
                }
            }
            .navigationTitle("Register Surplus")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let t = title.trimmingCharacters(in: .whitespaces)
                        relief.addSurplus(kind: kind, title: t.isEmpty ? kind.label : t, detail: detail)
                        dismiss()
                    }
                }
            }
        }
    }
}
