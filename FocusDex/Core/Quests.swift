import SwiftUI

/// Défis quotidiens : 3 objectifs rafraîchis chaque jour, récompensés automatiquement en bonbons.
enum QuestKind: String, Codable, CaseIterable {
    case focusMinutes, sessions, habits, grow, chest

    var icon: String {
        switch self {
        case .focusMinutes: "timer"
        case .sessions: "checkmark.circle.fill"
        case .habits: "checklist"
        case .grow: "sparkles"
        case .chest: "gift.fill"
        }
    }
    func text(target: Int) -> String {
        switch self {
        case .focusMinutes: "Concentre-toi \(target) min"
        case .sessions: "Termine \(target) session\(target > 1 ? "s" : "")"
        case .habits: "Coche \(target) habitude\(target > 1 ? "s" : "")"
        case .grow: "Fais éclore ou évoluer \(target) créature\(target > 1 ? "s" : "")"
        case .chest: "Ouvre le coffre du jour"
        }
    }
}

struct Quest: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: QuestKind
    var target: Int
    var progress: Int = 0
    var reward: Int
    var claimed: Bool = false
    var done: Bool { progress >= target }
    var text: String { kind.text(target: target) }
    var icon: String { kind.icon }
}

/// Modèle de défi dans la base.
struct QuestTemplate {
    let kind: QuestKind
    let target: Int
    let reward: Int
}

enum Quests {
    /// Base de données de défis : de nombreux défis variés, de difficultés différentes.
    static let database: [QuestTemplate] = [
        // Focus (minutes cumulées)
        .init(kind: .focusMinutes, target: 15, reward: 25),
        .init(kind: .focusMinutes, target: 25, reward: 40),
        .init(kind: .focusMinutes, target: 40, reward: 60),
        .init(kind: .focusMinutes, target: 60, reward: 90),
        .init(kind: .focusMinutes, target: 90, reward: 140),
        .init(kind: .focusMinutes, target: 120, reward: 200),
        // Sessions terminées
        .init(kind: .sessions, target: 1, reward: 20),
        .init(kind: .sessions, target: 2, reward: 35),
        .init(kind: .sessions, target: 3, reward: 55),
        .init(kind: .sessions, target: 4, reward: 80),
        // Habitudes cochées
        .init(kind: .habits, target: 1, reward: 15),
        .init(kind: .habits, target: 2, reward: 30),
        .init(kind: .habits, target: 3, reward: 50),
        .init(kind: .habits, target: 5, reward: 85),
        // Faire grandir (éclosion / évolution / diplôme)
        .init(kind: .grow, target: 1, reward: 50),
        .init(kind: .grow, target: 2, reward: 110),
        // Coffre du jour
        .init(kind: .chest, target: 1, reward: 25),
    ]

    /// 3 défis du jour, de types DISTINCTS, tirés de la base.
    static func fresh() -> [Quest] {
        var byKind: [QuestKind: [QuestTemplate]] = [:]
        for tpl in database { byKind[tpl.kind, default: []].append(tpl) }
        let kinds = byKind.keys.shuffled().prefix(3)
        return kinds.compactMap { k in
            byKind[k]?.randomElement().map { Quest(kind: $0.kind, target: $0.target, reward: $0.reward) }
        }
    }
}
