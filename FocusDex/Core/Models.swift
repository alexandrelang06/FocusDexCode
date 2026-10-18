import SwiftUI

/// Le compagnon en cours : un œuf qui incube puis une créature qui monte en niveau et évolue.
struct ActiveCompanion: Codable {
    var baseSpeciesID: String     // l'espèce dans laquelle l'œuf va éclore
    var speciesID: String?        // espèce actuelle une fois éclos (nil = encore un œuf)
    var rarityRaw: String
    var isShiny: Bool
    var xp: Int                   // progression (avant éclosion = incubation ; après = montée de niveau)
    var hatched: Bool
    var nickname: String? = nil   // surnom donné par l'utilisateur à l'éclosion (optionnel)

    var rarity: Rarity { Rarity(rawValue: rarityRaw) ?? .common }
    static let hatchXP = 30

    var hatchProgress: Double { hatched ? 1 : min(1, Double(xp) / Double(Self.hatchXP)) }

    /// Niveau dérivé du xp post-éclosion (paliers croissants).
    var level: Int {
        guard hatched else { return 0 }
        var lvl = 1, need = 24, pool = xp
        while pool >= need && lvl < 99 { pool -= need; lvl += 1; need = 20 + lvl * 6 }
        return lvl
    }
    /// Progression (0..1) vers le prochain niveau.
    var levelProgress: Double {
        guard hatched else { return hatchProgress }
        var lvl = 1, need = 24, pool = xp
        while pool >= need && lvl < 99 { pool -= need; lvl += 1; need = 20 + lvl * 6 }
        return min(1, Double(pool) / Double(need))
    }

    /// Paliers d'évolution (1/3 et 2/3 du chemin) et de diplôme, selon la rareté.
    var graduateLevel: Int { rarity.graduateLevel }
    var evolveLevels: [Int] { [max(3, graduateLevel / 3), max(5, graduateLevel * 2 / 3)] }
}

/// Événements produits par un gain de xp (pour animer l'UI).
enum CompanionEvent: Equatable {
    case hatched(String)                    // speciesID
    case leveledUp(Int)                     // nouveau niveau
    case evolved(from: String, to: String)
    case graduated(String, shiny: Bool)     // speciesID diplômé
}

/// Une habitude, quotidienne ou sur certains jours.
struct Habit: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var streak: Int = 0
    var lastDoneDay: String = ""            // yyyy-MM-dd
    var days: Set<Int> = []                 // jours actifs (1=Dim … 7=Sam) ; vide = tous les jours
    func isDone(today: String) -> Bool { lastDoneDay == today }
    func isActive(weekday: Int) -> Bool { days.isEmpty || days.contains(weekday) }
    var isDaily: Bool { days.isEmpty || days.count == 7 }
}

/// Objet à offrir au compagnon, acheté en bonbons (bonbons rechargeables en argent réel).
struct TreatItem: Identifiable {
    let id: String
    let nameKey: String
    let emoji: String
    let descKey: String
    let candyPrice: Int
    let effect: Effect
    enum Effect { case xp(Int); case care }

    static let all: [TreatItem] = [
        .init(id: "treat", nameKey: "Friandise", emoji: "🍎",
              descKey: "Un petit plus pour ton compagnon (+40 XP).", candyPrice: 120, effect: .xp(40)),
        .init(id: "boost", nameKey: "Accélérateur", emoji: "⚡️",
              descKey: "Fait avancer l'éclosion ou le niveau (+70 XP).", candyPrice: 200, effect: .xp(70)),
        .init(id: "feast", nameKey: "Festin", emoji: "🍰",
              descKey: "Un grand repas (+120 XP d'un coup).", candyPrice: 300, effect: .xp(120)),
        .init(id: "care", nameKey: "Câlin", emoji: "💗",
              descKey: "Requinque un compagnon un peu négligé.", candyPrice: 80, effect: .care),
    ]
}

/// Accessoire cosmétique porté par le compagnon (acheté en bonbons).
struct CosmeticItem: Identifiable {
    let id: String
    let nameKey: String
    let emoji: String
    let price: Int
    static let all: [CosmeticItem] = [
        .init(id: "flower", nameKey: "Fleur", emoji: "🌸", price: 120),
        .init(id: "bow", nameKey: "Nœud", emoji: "🎀", price: 150),
        .init(id: "glasses", nameKey: "Lunettes", emoji: "🕶️", price: 180),
        .init(id: "party", nameKey: "Chapeau de fête", emoji: "🥳", price: 200),
        .init(id: "tophat", nameKey: "Haut-de-forme", emoji: "🎩", price: 260),
        .init(id: "crown", nameKey: "Couronne", emoji: "👑", price: 400),
    ]
}

/// Œuf spécial acheté en bonbons : garantit un type ou une rareté.
struct SpecialEgg: Identifiable {
    let id: String
    let nameKey: String
    let emoji: String
    let price: Int
    let kind: String   // "fire" / "water" / "wood" / "rare"
    static let all: [SpecialEgg] = [
        .init(id: "fire",  nameKey: "Œuf de feu",        emoji: "🔥", price: 350, kind: "fire"),
        .init(id: "water", nameKey: "Œuf d'eau",         emoji: "💧", price: 350, kind: "water"),
        .init(id: "wood",  nameKey: "Œuf plante",        emoji: "🌿", price: 350, kind: "wood"),
        .init(id: "rare",  nameKey: "Œuf rare garanti",  emoji: "✨", price: 650, kind: "rare"),
    ]
}

/// Habitat (fond du compagnon) — cosmétique achetable en bonbons ou réservé au Pro.
struct Habitat: Identifiable, Equatable {
    let id: String
    let name: String
    let colors: [UInt32]
    let price: Int          // en bonbons (0 = offert)
    let proOnly: Bool

    var gradient: LinearGradient {
        LinearGradient(colors: colors.map { Color.hex($0) }, startPoint: .top, endPoint: .bottom)
    }
    static let all: [Habitat] = [
        Habitat(id: "meadow", name: "Prairie",   colors: [0xBFE3B0, 0x8FCf9A], price: 0, proOnly: false),
        Habitat(id: "dawn",   name: "Aube",      colors: [0xF6D8B8, 0xE8A9B0], price: 300, proOnly: false),
        Habitat(id: "ocean",  name: "Océan",     colors: [0xA6D4E8, 0x6AA6D0], price: 500, proOnly: false),
        Habitat(id: "forest", name: "Forêt",     colors: [0x9AC5A0, 0x4E7E5E], price: 800, proOnly: false),
        Habitat(id: "dusk",   name: "Crépuscule",colors: [0xC7A6E0, 0x7A5AA6], price: 1200, proOnly: false),
        Habitat(id: "neon",   name: "Néon",      colors: [0x5FE0E8, 0x2A2060], price: 0, proOnly: true),
        Habitat(id: "space",  name: "Espace",    colors: [0x8FD0E8, 0x241E42], price: 0, proOnly: true),
    ]
    static func byID(_ id: String) -> Habitat { all.first { $0.id == id } ?? all[0] }
}
