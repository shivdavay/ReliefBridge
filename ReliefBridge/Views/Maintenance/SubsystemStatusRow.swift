import SwiftUI

/// Simple readiness row for a maintenance subsystem or component group.
struct SubsystemStatusRow: View {
    let item: MaintenanceOverviewItem

    private var accentColor: Color {
        switch item.score {
        case 0.85...:
            return Theme.Colors.efficiencyGreen
        case 0.72...:
            return Theme.Colors.gold
        default:
            return Theme.Colors.alertOrange
        }
    }

    private var statusLabel: String {
        switch item.score {
        case 0.85...:
            return "Nominal"
        case 0.72...:
            return "Watch"
        default:
            return "Action"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.title)
                    .font(Theme.Fonts.sansSerif(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)

                Spacer()

                Text(statusLabel)
                    .font(Theme.Fonts.sansSerif(size: 11, weight: .bold))
                    .foregroundColor(Theme.Colors.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(accentColor)
                    )
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.85), accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * max(0.1, min(item.score, 1.0)))
                }
            }
            .frame(height: 8)

            Text(item.summary)
                .font(Theme.Fonts.sansSerif(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .glassPanel(accent: accentColor, cornerRadius: 20)
    }
}
