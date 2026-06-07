import SwiftUI

/// Reusable compact statistic card used across non-map modules.
struct InfoStatCard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    var accent: Color = Theme.Colors.aqua
    var usesMonospacedValue: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Gradients.accentGlow)

                Text(title.uppercased())
                    .font(Theme.Fonts.sansSerif(size: 10, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .tracking(1.1)
            }

            Text(value)
                .font(
                    usesMonospacedValue
                        ? Theme.Fonts.monospacedDigit(size: 24, weight: .bold)
                        : Theme.Fonts.sansSerif(size: 20, weight: .semibold)
                )
                .foregroundColor(Theme.Colors.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.65)

            Text(detail)
                .font(Theme.Fonts.sansSerif(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .padding(16)
        .glassPanel(accent: accent, cornerRadius: 20)
    }
}
