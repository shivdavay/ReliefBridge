// ReliefBridge/Views/Maintenance/LatticeHeatMapView.swift
// Canvas-based cross-sectional lattice heat map with color-coded zones.
// Validates: Requirements 6.1, 6.2, 6.3

import SwiftUI

// MARK: - LatticeHeatMapView

/// A custom Canvas-based view rendering a cross-sectional diagram of the Gyroid Lattice
/// with color-coded zones indicating health status.
///
/// Each zone is colored based on its `microPoreBlockageRisk`:
/// - Alert Orange: risk > `Thresholds.latticeBlockageWarning` (0.65)
/// - Efficiency Green: risk ≤ `Thresholds.latticeBlockageWarning`
///
/// The diagram uses a hexagonal grid pattern to represent the lattice structure.
struct LatticeHeatMapView: View {

    let zones: [LatticeZone]

    // MARK: - Body

    var body: some View {
        Canvas { context, size in
            // Draw background
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 12),
                with: .color(Theme.Colors.backgroundElevated.opacity(0.5))
            )

            // Calculate grid layout
            let cols = 5
            let rows = 3
            let cellWidth = size.width / CGFloat(cols)
            let cellHeight = size.height / CGFloat(rows)

            // Draw each zone as a hexagonal cell
            for (index, zone) in zones.prefix(cols * rows).enumerated() {
                let col = index % cols
                let row = index / cols

                let x = CGFloat(col) * cellWidth + cellWidth / 2
                let y = CGFloat(row) * cellHeight + cellHeight / 2

                // Determine zone color based on blockage risk
                let zoneColor = zone.microPoreBlockageRisk > Thresholds.latticeBlockageWarning
                    ? Theme.Colors.alertOrange
                    : Theme.Colors.efficiencyGreen

                // Draw hexagon
                let hexPath = hexagonPath(center: CGPoint(x: x, y: y), radius: min(cellWidth, cellHeight) * 0.35)
                context.fill(hexPath, with: .color(zoneColor.opacity(0.3)))
                context.stroke(hexPath, with: .color(zoneColor), lineWidth: 2)

                // Draw zone label
                let labelText = Text(zone.zoneLabel)
                    .font(Theme.Fonts.monospacedDigit(size: 10, weight: .semibold))
                    .foregroundColor(.white)

                context.draw(labelText, at: CGPoint(x: x, y: y))
            }

            // Draw legend
            drawLegend(context: context, size: size)
        }
        .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 20)
    }

    // MARK: - Helpers

    /// Creates a hexagonal path centered at the given point with the specified radius.
    private func hexagonPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3.0
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }

    /// Draws a legend in the bottom-right corner of the canvas.
    private func drawLegend(context: GraphicsContext, size: CGSize) {
        let legendX = size.width - 120
        let legendY = size.height - 50

        // Green indicator
        let greenRect = CGRect(x: legendX, y: legendY, width: 12, height: 12)
        context.fill(Path(roundedRect: greenRect, cornerRadius: 2), with: .color(Theme.Colors.efficiencyGreen))

        let greenLabel = Text("Normal")
            .font(Theme.Fonts.sansSerif(size: 10))
            .foregroundColor(.white)
        context.draw(greenLabel, at: CGPoint(x: legendX + 20, y: legendY + 6))

        // Orange indicator
        let orangeRect = CGRect(x: legendX, y: legendY + 20, width: 12, height: 12)
        context.fill(Path(roundedRect: orangeRect, cornerRadius: 2), with: .color(Theme.Colors.alertOrange))

        let orangeLabel = Text("At Risk")
            .font(Theme.Fonts.sansSerif(size: 10))
            .foregroundColor(.white)
        context.draw(orangeLabel, at: CGPoint(x: legendX + 20, y: legendY + 26))
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        // All zones healthy
        LatticeHeatMapView(zones: [
            LatticeZone(id: UUID(), zoneLabel: "A1", microPoreBlockageRisk: 0.25),
            LatticeZone(id: UUID(), zoneLabel: "A2", microPoreBlockageRisk: 0.30),
            LatticeZone(id: UUID(), zoneLabel: "A3", microPoreBlockageRisk: 0.45),
            LatticeZone(id: UUID(), zoneLabel: "B1", microPoreBlockageRisk: 0.50),
            LatticeZone(id: UUID(), zoneLabel: "B2", microPoreBlockageRisk: 0.35),
            LatticeZone(id: UUID(), zoneLabel: "B3", microPoreBlockageRisk: 0.40),
            LatticeZone(id: UUID(), zoneLabel: "C1", microPoreBlockageRisk: 0.55),
            LatticeZone(id: UUID(), zoneLabel: "C2", microPoreBlockageRisk: 0.60),
            LatticeZone(id: UUID(), zoneLabel: "C3", microPoreBlockageRisk: 0.20),
        ])
        .frame(height: 200)

        // Some zones at risk
        LatticeHeatMapView(zones: [
            LatticeZone(id: UUID(), zoneLabel: "A1", microPoreBlockageRisk: 0.75),
            LatticeZone(id: UUID(), zoneLabel: "A2", microPoreBlockageRisk: 0.30),
            LatticeZone(id: UUID(), zoneLabel: "A3", microPoreBlockageRisk: 0.80),
            LatticeZone(id: UUID(), zoneLabel: "B1", microPoreBlockageRisk: 0.50),
            LatticeZone(id: UUID(), zoneLabel: "B2", microPoreBlockageRisk: 0.35),
            LatticeZone(id: UUID(), zoneLabel: "B3", microPoreBlockageRisk: 0.70),
            LatticeZone(id: UUID(), zoneLabel: "C1", microPoreBlockageRisk: 0.55),
            LatticeZone(id: UUID(), zoneLabel: "C2", microPoreBlockageRisk: 0.60),
            LatticeZone(id: UUID(), zoneLabel: "C3", microPoreBlockageRisk: 0.20),
        ])
        .frame(height: 200)
    }
    .padding()
    .background(Theme.Colors.background)
}
#endif
