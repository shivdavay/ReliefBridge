// ReliefBridge/Theme/Theme.swift
// Aviation Dark Mode theme: colors, fonts, and global view modifiers.

import SwiftUI

// MARK: - Theme Namespace

/// Central namespace for all Aviation Dark Mode design tokens.
///
/// Usage:
/// ```swift
/// Text("Fuel Saved")
///     .foregroundColor(Theme.Colors.efficiencyGreen)
///     .background(Theme.Colors.background)
/// ```
enum Theme {

    // MARK: Colors

    /// Aviation Dark Mode color palette.
    enum Colors {
        /// Primary app background — deep midnight navy.
        static let background = Color(hex: "#09111D")

        /// Elevated background used for inset sections.
        static let backgroundElevated = Color(hex: "#111C2B")

        /// Efficiency Green `#00FF87` — used for positive metrics and active state highlights.
        static let efficiencyGreen = Color(hex: "#25D7A0")

        /// Alert Orange `#FF5722` — used for warnings, threshold breaches, and error states.
        static let alertOrange = Color(hex: "#FF8A5B")

        /// Branded gold highlight for hero text and premium chrome.
        static let gold = Color(hex: "#DCCF9E")

        /// Electric blue accent used in gradients and panel strokes.
        static let electricBlue = Color(hex: "#4A79C9")

        /// Aqua highlight used for telemetry and live states.
        static let aqua = Color(hex: "#23C9BE")

        /// Secondary surface for glass cards and panels.
        static let surface = Color(hex: "#152235")

        /// Elevated surface used inside charts and nested cards.
        static let surfaceElevated = Color(hex: "#21324A")

        /// Primary readable text color.
        static let primaryText = Color(hex: "#F4F2EA")

        /// Muted text color for secondary labels.
        static let secondaryText = Color(hex: "#95A7C6")

        /// Fine glass border color.
        static let glassStroke = Color(hex: "#87A8D7")

        /// Shadow color for floating panels.
        static let panelShadow = Color.black.opacity(0.38)
    }

    // MARK: Gradients

    /// Reusable gradients that establish the app's premium chrome.
    enum Gradients {
        static let appBackground = LinearGradient(
            colors: [
                Color(hex: "#0B1422"),
                Color(hex: "#08111D"),
                Color(hex: "#04070D")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let heroText = LinearGradient(
            colors: [
                Theme.Colors.gold,
                Color.white.opacity(0.92),
                Theme.Colors.aqua
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let accentGlow = LinearGradient(
            colors: [
                Theme.Colors.electricBlue,
                Theme.Colors.aqua,
                Theme.Colors.efficiencyGreen
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let glassFill = LinearGradient(
            colors: [
                Theme.Colors.surface.opacity(0.92),
                Theme.Colors.surfaceElevated.opacity(0.76)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Backgrounds

    /// Shared app backdrop with layered glow fields.
    struct AppBackdrop: View {
        var body: some View {
            ZStack {
                Theme.Gradients.appBackground

                Circle()
                    .fill(Theme.Colors.electricBlue.opacity(0.22))
                    .frame(width: 360, height: 360)
                    .blur(radius: 110)
                    .offset(x: -140, y: -250)

                Circle()
                    .fill(Theme.Colors.aqua.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 100)
                    .offset(x: 180, y: -120)

                Circle()
                    .fill(Theme.Colors.efficiencyGreen.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(x: 150, y: 260)
            }
        }
    }

    // MARK: Fonts

    /// Typography helpers for consistent font usage.
    enum Fonts {
        /// Monospaced font for all real-time numeric readouts.
        /// Ensures digit alignment stability during live updates.
        static func monospacedDigit(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        /// Modern sans-serif font for section headers and labels.
        static func sansSerif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .default)
        }

        /// Elegant serif display font used for hero headlines.
        static func serifHero(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .serif)
        }
    }
}

// MARK: - AviationDarkModeModifier

/// Applies the Aviation Dark Mode appearance globally:
/// - Forces dark color scheme
/// - Sets the root background to `#121212`
///
/// Apply once at the root view:
/// ```swift
/// ContentView()
///     .modifier(AviationDarkModeModifier())
/// ```
struct AviationDarkModeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .background(Theme.AppBackdrop().ignoresSafeArea())
    }
}

struct GlassPanelModifier: ViewModifier {
    let accent: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Theme.Gradients.glassFill)
                        .opacity(0.94)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accent.opacity(0.55),
                                    Theme.Colors.glassStroke.opacity(0.34),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Theme.Colors.panelShadow, radius: 22, x: 0, y: 14)
                .shadow(color: accent.opacity(0.16), radius: 26, x: 0, y: 0)
            }
    }
}

extension View {
    /// Applies the Aviation Dark Mode theme (dark color scheme + `#121212` background).
    func aviationDarkMode() -> some View {
        modifier(AviationDarkModeModifier())
    }

    /// Wraps content in a shared glassmorphism panel.
    func glassPanel(
        accent: Color = Theme.Colors.electricBlue,
        cornerRadius: CGFloat = 24
    ) -> some View {
        modifier(GlassPanelModifier(accent: accent, cornerRadius: cornerRadius))
    }
}

// MARK: - Color Hex Initializer

extension Color {
    /// Creates a `Color` from a CSS-style hex string (e.g. `"#00FF87"` or `"00FF87"`).
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB (no alpha)
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8: // RGBA
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
