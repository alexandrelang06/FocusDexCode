import SwiftUI

/// Une espèce de créature (données Tuxemon, CC-BY-SA — voir écran Crédits).
struct Creature: Codable, Identifiable, Hashable {
    let id: String            // slug (agnite…)
    let name: String
    let types: [String]
    let shape: String
    let stage: String         // basic / stage1 / stage2 / standalone
    let txmnId: Int
    let family: String        // slug de la forme de base
    let evolvesInto: String?  // slug de l'évolution suivante
    let evolveLevel: Int?     // niveau de déclenchement
    let sprite: String        // nom de fichier PNG

    var isBase: Bool { stage == "basic" || stage == "standalone" }
    var primaryType: String { types.first ?? "normal" }
}

enum Rarity: String, Codable, CaseIterable, Identifiable {
    case common, rare, epic, legendary
    var id: String { rawValue }
    var title: String {
        switch self { case .common: "Commune"; case .rare: "Rare"; case .epic: "Épique"; case .legendary: "Légendaire" }
    }
    var color: Color {
        switch self { case .common: .hex(0x9AA4B2); case .rare: .hex(0x4A9BE0); case .epic: .hex(0x9B6BD8); case .legendary: .hex(0xF0B54A) }
    }
    /// Poids de tirage (plus haut = plus fréquent).
    var weight: Double {
        switch self { case .common: 60; case .rare: 28; case .epic: 10; case .legendary: 2 }
    }
    /// Niveaux à atteindre pour « diplômer » la créature (plus rare = plus long).
    var graduateLevel: Int {
        switch self { case .common: 12; case .rare: 18; case .epic: 26; case .legendary: 36 }
    }
}

/// Base de données des créatures, chargée depuis `creatures.json` du bundle.
enum CreatureDB {
    static let all: [Creature] = load()
    static let byID: [String: Creature] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    static let bases: [Creature] = all.filter { $0.isBase }
    /// Whitelist des créatures de base « mignonnes » (revue visuelle), pour les tirages.
    static let cuteWhitelist: Set<String> = [
        "aardorn", "agnite", "agnsher", "altie", "ambuwl", "anoleaf", "anu", "axolightl", "babysnitch",
        "banling", "baoby", "boltnu", "brewdin", "budaye", "bumbulus", "burrlock", "cairfrey", "caper",
        "capiti", "cardiling", "cataspike", "cateye", "chibiro", "chickadee", "chloragon", "cochini",
        "cohldrabi", "conifrost", "conileaf", "cowpignon", "dandicub", "delfeco", "devidin", "dinoflop",
        "dollfin", "drashimi", "drokoro", "duggot", "elofly", "embra", "erythroskyte", "eskipup", "flacono",
        "flisces", "foofle", "fordin", "foxko", "frondly", "fruitera", "furnursus", "fuzzlet", "gliffary",
        "grumpi", "gupphish", "hatchling", "helipi", "howl", "ignibus", "jelillow", "jeluna", "joulraton",
        "konuit", "kroki", "lapinou", "lesmagu", "lunight", "medipup", "memnomnom", "mingdyn", "mystikapi",
        "nebufin", "nuenflu", "pairagrin", "pantherafira", "pawsand", "pearamanca", "pickoon", "pipis",
        "polyrock", "propellercat", "pyraminx", "rockitten", "rosarin", "sclairus", "seirein", "shybulb",
        "skwib", "slichen", "snaki", "snarlon", "snock", "solight", "sprightly", "spycozeus", "squabbit",
        "squink", "sumchon", "tadcool", "taupypus", "teddisun", "tetrchimp", "toucanary", "trapsnap",
        "tumblequill", "turnipper", "tux", "tweesher", "urcine", "vividactil", "vivisource", "wolffsky",
        "wrougon", "yamada", "zunna",
    ]
    /// Pool d'éclosion : bases mignonnes de la whitelist (repli sur les bases non-glitch si vide).
    static let hatchBases: [Creature] = {
        let cute = bases.filter { cuteWhitelist.contains($0.id) }
        if !cute.isEmpty { return cute }
        return bases.filter { !$0.id.contains(where: { $0.isNumber || $0 == "_" }) }
    }()

    static func creature(_ id: String) -> Creature? { byID[id] }

    /// Toute la lignée d'évolution d'une créature (de la base à la forme finale).
    static func line(for id: String) -> [Creature] {
        guard let c = byID[id] else { return [] }
        var chain: [Creature] = []
        var cur: Creature? = byID[c.family] ?? c
        var guardCount = 0
        while let node = cur, guardCount < 6 {
            chain.append(node)
            cur = node.evolvesInto.flatMap { byID[$0] }
            guardCount += 1
        }
        return chain
    }

    /// Rareté déterministe par famille (stable d'une session à l'autre).
    static func rarity(family: String) -> Rarity {
        var h: UInt64 = 1469598103934665603
        for b in family.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        switch Int(h % 100) {
        case 0..<2:   return .legendary
        case 2..<12:  return .epic
        case 12..<40: return .rare
        default:      return .common
        }
    }

    /// Tire une créature de base au hasard, pondérée par rareté (les rares plus… rares).
    static func randomBase() -> Creature {
        let pool = hatchBases
        guard !pool.isEmpty else {
            return Creature(id: "agnite", name: "Agnite", types: ["fire"], shape: "dragon", stage: "basic",
                            txmnId: 0, family: "agnite", evolvesInto: nil, evolveLevel: nil, sprite: "agnite.png")
        }
        let weights = pool.map { rarity(family: $0.family).weight }
        let total = weights.reduce(0, +)
        var r = Double.random(in: 0..<total)
        for (i, w) in weights.enumerated() {
            if r < w { return pool[i] }
            r -= w
        }
        return pool[0]
    }

    private static func load() -> [Creature] {
        guard let url = Bundle.main.url(forResource: "creatures", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Creature].self, from: data) else {
            return []
        }
        return list.sorted { $0.txmnId < $1.txmnId }
    }
}
