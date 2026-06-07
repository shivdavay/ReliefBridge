// ReliefBridge/App/ReliefBridgeApp.swift
// App entry point — creates SimulatedDataService and injects it into the environment.

import SwiftUI

@main
struct ReliefBridgeApp: App {

    /// Single source of truth for all simulated data across all modules.
    @StateObject private var dataService = SimulatedDataService()

    /// Live crisis data engine for the ReliefBridge globe (USGS + GDACS).
    @StateObject private var relief = ReliefService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .environmentObject(relief)
                // Apply Aviation Dark Mode globally: dark color scheme + #121212 background.
                .aviationDarkMode()
                // Set Efficiency Green as the global accent color.
                .tint(Theme.Colors.efficiencyGreen)
        }
    }
}

// MARK: - ContentView

/// Root view that guards on data service initialization state.
///
/// State machine:
/// - `isInitialized == true`  → show `MainTabView`
/// - `initializationError != nil` → show `DataUnavailableView` with the error message
/// - Neither (still loading)  → show a loading spinner
struct ContentView: View {
    @EnvironmentObject private var dataService: SimulatedDataService

    var body: some View {
        Group {
            if dataService.isInitialized {
                MainTabView()
            } else if let errorMessage = dataService.initializationError {
                DataUnavailableView(message: errorMessage)
            } else {
                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            .frame(width: 86, height: 86)

                        Circle()
                            .fill(Theme.Colors.aqua.opacity(0.16))
                            .frame(width: 74, height: 74)
                            .blur(radius: 16)

                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Theme.Colors.aqua)
                            .scaleEffect(1.45)
                    }

                    VStack(spacing: 10) {
                        GlowText(
                            text: "Preparing ReliefBridge",
                            font: Theme.Fonts.serifHero(size: 30, weight: .bold),
                            glowColor: Theme.Colors.aqua
                        )

                        Text("Pulling live humanitarian crises from USGS and GDACS so you can bridge real needs.")
                            .font(Theme.Fonts.sansSerif(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 10) {
                        bootPill(label: "Live Crises", icon: "globe.americas.fill")
                        bootPill(label: "Triage", icon: "gauge.with.dots.needle.67percent")
                        bootPill(label: "Surplus", icon: "shippingbox.fill")
                    }
                }
                .padding(28)
                .glassPanel(accent: Theme.Colors.electricBlue, cornerRadius: 32)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: dataService.isInitialized)
        .animation(.easeInOut(duration: 0.4), value: dataService.initializationError)
        .background(Theme.AppBackdrop().ignoresSafeArea())
    }

    private func bootPill(label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(Theme.Fonts.sansSerif(size: 11, weight: .semibold))
        }
        .foregroundColor(Theme.Colors.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.Colors.surface.opacity(0.9))
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.glassStroke.opacity(0.28), lineWidth: 1)
                )
        )
    }
}

// MARK: - MainTabView

/// Root tab navigation containing all five operational modules.
/// Defaults to the Fleet Command tab (tag 0) on launch, per Requirement 1.7.
struct MainTabView: View {
    @EnvironmentObject private var dataService: SimulatedDataService

    /// Tracks the selected tab. Defaults to the Bridge globe (tag 0); an optional
    /// RB_TAB launch env var lets QA open a specific tab on launch.
    @State private var selectedTab: Int = {
        if let raw = ProcessInfo.processInfo.environment["RB_TAB"], let i = Int(raw) { return i }
        return 0
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: ReliefBridge crisis globe (default tab) — live USGS + GDACS data
            Group {
                if #available(iOS 17.0, macOS 14.0, *) {
                    ReliefGlobeView()
                } else {
                    Text("ReliefBridge requires iOS 17+")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .tabItem {
                Label("Bridge", systemImage: "globe.americas.fill")
            }
            .tag(0)

            // Tab 2: Respond — urgency-ranked triage of every live crisis
            Group {
                if #available(iOS 17.0, macOS 14.0, *) {
                    RespondView()
                } else { Text("Requires iOS 17+") }
            }
            .tabItem {
                Label("Respond", systemImage: "list.bullet.rectangle.fill")
            }
            .tag(1)

            // Tab 3: Surplus Radar — match what you can give to nearby needs
            Group {
                if #available(iOS 17.0, macOS 14.0, *) {
                    SurplusRadarView()
                } else { Text("Requires iOS 17+") }
            }
            .tabItem {
                Label("Surplus", systemImage: "shippingbox.fill")
            }
            .tag(2)

            // Tab 4: Impact — your real bridges measured against live crises
            Group {
                if #available(iOS 17.0, macOS 14.0, *) {
                    ImpactView()
                } else { Text("Requires iOS 17+") }
            }
            .tabItem {
                Label("Impact", systemImage: "chart.bar.xaxis")
            }
            .tag(3)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .toolbarBackground(Theme.Colors.backgroundElevated.opacity(0.98), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

// MARK: - DataUnavailableView

/// Full-screen error view shown when `SimulatedDataService` fails to initialize.
struct DataUnavailableView: View {
    let message: String

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 58, weight: .semibold))
                .foregroundColor(Theme.Colors.alertOrange)
                .shadow(color: Theme.Colors.alertOrange.opacity(0.28), radius: 16, x: 0, y: 0)

            VStack(spacing: 10) {
                GlowText(
                    text: "Data Unavailable",
                    font: Theme.Fonts.serifHero(size: 30, weight: .bold),
                    glowColor: Theme.Colors.alertOrange
                )

                Text("ReliefBridge could not finish booting cleanly.")
                    .font(Theme.Fonts.sansSerif(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Text(message)
                .font(Theme.Fonts.sansSerif(size: 15))
                .foregroundColor(Theme.Colors.primaryText)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                faultPill(label: "Crisis feed offline", icon: "antenna.radiowaves.left.and.right.slash")
                faultPill(label: "Check connection", icon: "wifi.exclamationmark")
            }
        }
        .padding(28)
        .glassPanel(accent: Theme.Colors.alertOrange, cornerRadius: 32)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.AppBackdrop().ignoresSafeArea())
    }

    private func faultPill(label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(Theme.Fonts.sansSerif(size: 11, weight: .semibold))
        }
        .foregroundColor(Theme.Colors.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.Colors.surface.opacity(0.9))
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.alertOrange.opacity(0.26), lineWidth: 1)
                )
        )
    }
}

// SimulatedDataService is implemented in ReliefBridge/Services/SimulatedDataService.swift
