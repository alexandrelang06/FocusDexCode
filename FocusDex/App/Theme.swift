import SwiftUI

/// Deux « tons » d'identité visuelle, choisis à l'onboarding puis modifiables en réglages.
/// - `zen`   : self-care doux et chaleureux (façon Finch).
/// - `focus` : productivité, sombre et énergique (façon Forest / outil de dev).
enum Tone: String, Codable, CaseIterable, Identifiable {
    case zen, focus
    var id: String { rawValue }
    var title: String { self == .zen ? "Cocon" : "Focus" }
    var subtitle: String { self == .zen ? "Doux & bienveillant" : "Concentré & dynamique" }
    var emoji: String { self == .zen ? "🌿" : "⚡️" }
}

/// Palette complète dérivée du ton. Toutes les vues lisent leurs couleurs ici.
struct Theme {
    let tone: Tone
    let bg: Color
    let bg2: Color        // surfaces / cartes
    let card: Color       // cartes surélevées
    let text: Color
    let sub: Color        // texte secondaire
    let accent: Color     // CTA principal
    let accent2: Color    // accent secondaire
    let positive: Color   // succès / progression
    let coin: Color       // bonbons / monnaie
    let danger: Color
    let onAccent: Color    // texte sur accent
    let dark: Bool

    var bgGradient: LinearGradient {
        LinearGradient(colors: tone == .zen ? [bg, bg2] : [bg, bg.opacity(0.6)],
                       startPoint: .top, endPoint: .bottom)
    }
    var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func forTone(_ tone: Tone) -> Theme {
        switch tone {
        case .zen:
            return Theme(
                tone: .zen,
                bg: .hex(0xFBF3EE), bg2: .hex(0xFFF7F2), card: .white,
                text: .hex(0x3B3138), sub: .hex(0x9C8D8A),
                accent: .hex(0xEF4B57), accent2: .hex(0xFF7E6B),
                positive: .hex(0x53BE8A), coin: .hex(0xF3B23F), danger: .hex(0xE23B3B),
                onAccent: .white, dark: false)
        case .focus:
            return Theme(
                tone: .focus,
                bg: .hex(0x1A1216), bg2: .hex(0x281B20), card: .hex(0x33232A),
                text: .hex(0xF7EFEF), sub: .hex(0xB39B9E),
                accent: .hex(0xFF5A5F), accent2: .hex(0xFF8A5C),
                positive: .hex(0x5FD08A), coin: .hex(0xF4C430), danger: .hex(0xFF6B6B),
                onAccent: .white, dark: true)
        }
    }
}

/// Couleurs par type de créature (Tuxemon), pour les badges du dex.
enum TypeColor {
    static func color(_ type: String) -> Color {
        switch type.lowercased() {
        case "fire":      return .hex(0xF07945)
        case "water":     return .hex(0x4A9BE0)
        case "wood":      return .hex(0x5FB86A)
        case "earth":     return .hex(0xC0915A)
        case "metal":     return .hex(0x9AA4B2)
        case "lightning": return .hex(0xF2C33D)
        case "frost":     return .hex(0x7FC7E0)
        case "cosmic":    return .hex(0x9B6BD8)
        case "shadow":    return .hex(0x6A5B84)
        case "venom":     return .hex(0xA35FC0)
        case "heroic":    return .hex(0xE0A93D)
        case "sky":       return .hex(0x8FC7E8)
        case "normal":    return .hex(0xB7B0A6)
        default:          return .hex(0x9A93B4)
        }
    }
    static func label(_ type: String) -> String { type.isEmpty ? "?" : type.capitalized }
}

extension Color {
    static func hex(_ v: UInt32) -> Color {
        Color(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255,
              blue: Double(v & 0xFF) / 255, opacity: 1)
    }
}
