import SwiftUI

// MARK: - Color Tokens

enum AppColors {
    // Green HUD / Mature palette
    static let background = Color(hex: "#132426")
    static let surface = Color(hex: "#08401B")
    static let surface2 = Color(hex: "#0A5926")
    static let strokeGlow = Color(red: 5 / 255, green: 242 / 255, blue: 108 / 255, opacity: 0.18)
    static let primary = Color(hex: "#05F26C")
    static let secondary = Color(hex: "#03A64A")
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.68)
    static let divider = Color.white.opacity(0.08)
}

// MARK: - Typography

enum AppTypography {
    static func title(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .semibold, design: .default) // SF Pro Display Semibold
    }

    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default) // SF Pro Text/Display
    }

    static func label(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func hudNumber(_ size: CGFloat = 40, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced) // SF Mono
    }
}

// MARK: - Layout tokens

enum AppLayout {
    static let grid: CGFloat = 8
    static let cardRadius: CGFloat = 18
    static let buttonRadius: CGFloat = 16
    static let chipRadius: CGFloat = 999
}

// MARK: - Common modifiers

private struct GlassCardModifier: ViewModifier {
    var useSecondarySurface: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(AppLayout.grid * 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                    .fill((useSecondarySurface ? AppColors.surface2 : AppColors.surface).opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                            .stroke(AppColors.strokeGlow, lineWidth: 1)
                    )
                    .shadow(color: AppColors.primary.opacity(0.16), radius: 16, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(0.28), radius: 14, x: 0, y: 8)
            )
    }
}

private struct HudFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, AppLayout.grid * 1.5)
            .padding(.horizontal, AppLayout.grid * 2)
            .background(AppColors.surface2.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous)
                    .stroke(AppColors.strokeGlow, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous))
            .foregroundColor(AppColors.textPrimary)
    }
}

private struct HudBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        AppColors.background,
                        AppColors.background.opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
    }
}

struct HudSectionCard<Content: View>: View {
    let title: String?
    let subtitle: String?
    let spacing: CGFloat
    let useSecondarySurface: Bool
    @ViewBuilder let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        spacing: CGFloat = AppLayout.grid * 1.5,
        useSecondarySurface: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.spacing = spacing
        self.useSecondarySurface = useSecondarySurface
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            if let title {
                Text(title)
                    .font(AppTypography.body(15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.label(12))
                    .foregroundColor(AppColors.textSecondary)
            }
            content
        }
        .modifier(GlassCardModifier(useSecondarySurface: useSecondarySurface))
    }
}

// MARK: - Helpers

extension View {
    func glassCardStyle(secondary: Bool = false) -> some View {
        modifier(GlassCardModifier(useSecondarySurface: secondary))
    }

    func hudFieldStyle() -> some View {
        modifier(HudFieldModifier())
    }

    func hudBackground() -> some View {
        modifier(HudBackgroundModifier())
    }
}

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: sanitized)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let r, g, b: Double
        if sanitized.count == 6 {
            r = Double((value & 0xFF0000) >> 16)
            g = Double((value & 0x00FF00) >> 8)
            b = Double(value & 0x0000FF)
        } else {
            r = 0; g = 0; b = 0
        }

        self.init(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: alpha)
    }
}
