// ReliefBridge/Views/FleetCommand/FleetCommandView.swift

import SwiftUI
import MapKit

@available(iOS 17.0, macOS 14.0, *)
struct FleetCommandView: View {

    @EnvironmentObject private var dataService: SimulatedDataService
    @StateObject private var viewModel: FleetCommandViewModel

    @State private var selectedTailNumber: String? = nil
    @State private var navigateToTwin: Bool = false
    @State private var showFilterSheet: Bool = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.0, longitude: 10.0),
            span: MKCoordinateSpan(latitudeDelta: 80, longitudeDelta: 120)
        )
    )

    init(dataService: SimulatedDataService) {
        _viewModel = StateObject(wrappedValue: FleetCommandViewModel(dataService: dataService))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    ForEach(viewModel.filteredAircraft.filter(\.isAirborne)) { aircraft in
                        Annotation(aircraft.flightIdentifier, coordinate: aircraft.coordinate) {
                            AircraftMapAnnotation(aircraft: aircraft)
                                .onTapGesture {
                                    dataService.selectAircraft(tailNumber: aircraft.tailNumber)
                                    selectedTailNumber = aircraft.tailNumber
                                    navigateToTwin = true
                                }
                        }
                    }
                }
                .mapStyle(.imagery(elevation: .realistic))
                .colorScheme(.dark)
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    if viewModel.filteredAircraft.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.Colors.secondaryText)
                            Text("No \(dataService.selectedCarrier.rawValue) flights match your criteria")
                                .font(Theme.Fonts.sansSerif(size: 14))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.surface.opacity(0.9))
                        )
                        .padding(.bottom, 8)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.kpiCards) { card in
                                KPICardView(card: card)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(
                        LinearGradient(
                            colors: [Theme.Colors.background.opacity(0), Theme.Colors.background],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .overlay(alignment: .top) {
                carrierHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 56)
            }
            .navigationTitle("Fleet Command")
            #if os(iOS)
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? Theme.Colors.efficiencyGreen : .white)
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search flight, route, or tail…")
            .sheet(isPresented: $showFilterSheet) {
                FleetFilterView(
                    viewModel: viewModel,
                    availableTypes: availableTypes,
                    availableRegions: availableRegions
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $navigateToTwin) {
                if let selectedTailNumber,
                   let selectedAircraft = dataService.aircraft(forTailNumber: selectedTailNumber) {
                    DigitalTwinView(aircraft: selectedAircraft, dataService: dataService)
                        .environmentObject(dataService)
                }
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    private var carrierHeader: some View {
        HStack(spacing: 12) {
            Menu {
                Picker("Carrier", selection: Binding(
                    get: { dataService.selectedCarrier },
                    set: { newCarrier in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            dataService.selectCarrier(newCarrier)
                        }
                    }
                )) {
                    ForEach(CargoCarrier.allCases) { carrier in
                        Text(carrier.rawValue).tag(carrier)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Carrier Scope")
                            .font(Theme.Fonts.sansSerif(size: 10, weight: .semibold))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .tracking(1.0)

                        Text(dataService.selectedCarrier.rawValue)
                            .font(Theme.Fonts.sansSerif(size: 17, weight: .semibold))
                            .foregroundColor(Theme.Colors.primaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(14)
                .glassPanel(accent: carrierAccent, cornerRadius: 22)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text("Mapped Flights")
                    .font(Theme.Fonts.sansSerif(size: 10, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .tracking(1.0)

                Text("\(viewModel.filteredAircraft.filter(\.isAirborne).count) live routes")
                    .font(Theme.Fonts.monospacedDigit(size: 17, weight: .bold))
                    .foregroundColor(Theme.Colors.primaryText)

                Text(dataService.selectedCarrier.operationsLabel)
                    .font(Theme.Fonts.sansSerif(size: 11))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassPanel(accent: Theme.Colors.electricBlue, cornerRadius: 22)
        }
    }

    private var hasActiveFilters: Bool {
        viewModel.filterCriteria.aircraftType != nil || viewModel.filterCriteria.region != nil
    }

    private var availableTypes: [String] {
        Array(Set(dataService.aircraft(for: dataService.selectedCarrier).map(\.aircraftType))).sorted()
    }

    private var availableRegions: [String] {
        Array(Set(dataService.aircraft(for: dataService.selectedCarrier).map(\.region))).sorted()
    }

    private var carrierAccent: Color {
        switch dataService.selectedCarrier {
        case .fedex:
            return Theme.Colors.aqua
        case .ups:
            return Theme.Colors.gold
        case .dhl:
            return Theme.Colors.efficiencyGreen
        }
    }
}
