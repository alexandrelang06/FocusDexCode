import Foundation

/// Copie (module widget) des données partagées app ↔ widget via App Group.
enum FocusDexShared {
    static let appGroup = "group.com.focusdex.app"
    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }
    static var snapshotURL: URL? { container?.appendingPathComponent("widget.json") }
    static var spriteURL: URL? { container?.appendingPathComponent("companion.png") }
    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }
    static let startFocusKey = "focusdex.widgetStartFocus"
}

struct WidgetSnapshot: Codable {
    var name: String
    var level: Int
    var hatched: Bool
    var isShiny: Bool
    var freshness: Double
    var streak: Int
    var dexCount: Int
    var dexTotal: Int
    var hatchProgress: Double
    var levelProgress: Double
    var lang: String = "fr"

    static let preview = WidgetSnapshot(name: "Agnsher", level: 4, hatched: true, isShiny: false,
                                        freshness: 1.0, streak: 6, dexCount: 12, dexTotal: 411,
                                        hatchProgress: 1, levelProgress: 0.6, lang: "fr")
}

/// Micro-traduction pour les quelques libellés du widget (le widget n'a pas accès à l'app).
enum WLoc {
    static func t(_ key: String, _ lang: String) -> String {
        guard lang != "fr", let row = table[key] else { return key }
        let idx = ["en": 0, "es": 1, "it": 2, "de": 3][lang] ?? 0
        return idx < row.count ? row[idx] : key
    }
    static let table: [String: [String]] = [
        "Œuf mystère": ["Mystery egg", "Huevo misterioso", "Uovo misterioso", "Rätsel-Ei"],
        "Niveau": ["Level", "Nivel", "Livello", "Level"],
        "Niv": ["Lv", "Nv", "Liv", "Lv"],
        "Ouvre FocusDex pour commencer": ["Open FocusDex to start", "Abre FocusDex para empezar",
                                          "Apri FocusDex per iniziare", "Öffne FocusDex zum Starten"],
        "Focus": ["Focus", "Enfoque", "Focus", "Fokus"],
        "Fais grandir ta créature": ["Grow your creature", "Haz crecer a tu criatura",
                                     "Fai crescere la tua creatura", "Lass deine Kreatur wachsen"],
    ]
}
