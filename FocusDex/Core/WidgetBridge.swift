import Foundation
import WidgetKit

/// Données partagées app ↔ widget via App Group.
enum FocusDexShared {
    static let appGroup = "group.com.focusdex.app"
    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }
    static var snapshotURL: URL? { container?.appendingPathComponent("widget.json") }
    static var spriteURL: URL? { container?.appendingPathComponent("companion.png") }
    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }
    static let startFocusKey = "focusdex.widgetStartFocus"   // minutes demandées par le widget (0 = rien)
}

/// Instantané minimal du compagnon, lu par le widget.
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
}

extension AppModel {
    /// Écrit l'instantané + le sprite du compagnon dans l'App Group et recharge le widget.
    /// No-op silencieux si l'App Group n'est pas disponible.
    func refreshWidget() {
        guard let snapURL = FocusDexShared.snapshotURL else { return }
        let comp = companion
        let creature = companionCreature
        let snap = WidgetSnapshot(
            name: (comp?.hatched == true) ? companionDisplayName : "Egg",
            level: comp?.level ?? 0,
            hatched: comp?.hatched ?? false,
            isShiny: comp?.isShiny ?? false,
            freshness: freshness,
            streak: currentStreak,
            dexCount: dexCount,
            dexTotal: dexTotal,
            hatchProgress: comp?.hatchProgress ?? 0,
            levelProgress: comp?.levelProgress ?? 0,
            lang: language.rawValue)
        if let data = try? JSONEncoder().encode(snap) { try? data.write(to: snapURL) }

        // Sprite : réécrit seulement si l'espèce a changé.
        if let creature, creature.id != lastWidgetSpecies, let spriteURL = FocusDexShared.spriteURL {
            if let u = Bundle.main.url(forResource: creature.id, withExtension: "png", subdirectory: "creatures")
                ?? Bundle.main.url(forResource: creature.id, withExtension: "png"),
               let d = try? Data(contentsOf: u) {
                try? d.write(to: spriteURL)
                lastWidgetSpecies = creature.id
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
