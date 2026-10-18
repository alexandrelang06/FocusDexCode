import SwiftUI

/// État global de l'app (persistant, local). Progression du compagnon, dex, habitudes, focus,
/// bonbons, cosmétiques, Pro, ton visuel. Tout hors-ligne (UserDefaults).
@MainActor
@Observable
final class AppModel {
    // Réglages / identité
    var tone: Tone { didSet { save() } }
    var onboardingDone: Bool { didSet { save() } }
    var notificationsAsked: Bool { didSet { save() } }
    var displayName: String { didSet { save() } }
    var signedIn: Bool { didSet { save() } }
    var focusMinutesDefault: Int { didSet { save() } }

    // Portefeuille & progression
    var candy: Int { didSet { save() } }
    var companion: ActiveCompanion? { didSet { save() } }
    var habits: [Habit] { didSet { save() } }
    var dexSpecies: Set<String> { didSet { save() } }
    var shinySpecies: Set<String> { didSet { save() } }
    var ownedHabitats: Set<String> { didSet { save() } }
    var equippedHabitat: String { didSet { save() } }
    var streak: Int { didSet { save() } }
    var lastActiveDay: String { didSet { save() } }
    var totalFocusMinutes: Int { didSet { save() } }
    var sessionsCompleted: Int { didSet { save() } }

    // Monétisation
    var proActive: Bool { didSet { save() } }

    // Défis quotidiens + coffre (persistance séparée pour ne pas casser l'ancien Save)
    var dailyQuests: [Quest] { didSet { if let x = try? JSONEncoder().encode(dailyQuests) { d.set(x, forKey: "focusdex.quests") } } }
    var questsDay: String { didSet { d.set(questsDay, forKey: "focusdex.questsDay") } }
    var lastChestDay: String { didSet { d.set(lastChestDay, forKey: "focusdex.chestDay") } }
    var lastPetDay: String { didSet { d.set(lastPetDay, forKey: "focusdex.petDay") } }
    // Œuf en attente offert après un diplôme (à faire éclore depuis l'accueil). "" = aucun.
    var pendingEggBase: String { didSet { d.set(pendingEggBase, forKey: "focusdex.eggBase") } }
    var pendingEggShiny: Bool { didSet { d.set(pendingEggShiny, forKey: "focusdex.eggShiny") } }
    // Boosts temporaires (timestamp de fin ; 0 = inactif) et cosmétiques du compagnon.
    var boostXPEndTS: Double { didSet { d.set(boostXPEndTS, forKey: "focusdex.boostXP") } }
    var boostShinyEndTS: Double { didSet { d.set(boostShinyEndTS, forKey: "focusdex.boostShiny") } }
    var ownedCosmetics: Set<String> { didSet { d.set(Array(ownedCosmetics), forKey: "focusdex.cosmetics") } }
    var equippedCosmetic: String { didSet { d.set(equippedCosmetic, forKey: "focusdex.cosmeticOn") } }
    // Personnalisation collectée à l'onboarding.
    var improveAreas: Set<String> { didSet { d.set(Array(improveAreas), forKey: "focusdex.areas") } }
    var obstacles: Set<String> { didSet { d.set(Array(obstacles), forKey: "focusdex.obstacles") } }
    var improveOther: String { didSet { d.set(improveOther, forKey: "focusdex.areasOther") } }
    var obstacleOther: String { didSet { d.set(obstacleOther, forKey: "focusdex.obstaclesOther") } }
    var dailyGoalMinutes: Int { didSet { d.set(dailyGoalMinutes, forKey: "focusdex.dailyGoal") } }
    // Session de focus persistante (date de fin absolue) : survit au verrouillage / changement d'app / fermeture.
    var focusEndTS: Double { didSet { d.set(focusEndTS, forKey: "focusdex.focusEnd") } }   // 0 = pas de session en cours
    var focusPausedRemaining: Int { didSet { d.set(focusPausedRemaining, forKey: "focusdex.focusPaused") } }  // >0 = en pause
    var focusSessionMinutes: Int { didSet { d.set(focusSessionMinutes, forKey: "focusdex.focusMin") } }
    // Fin de l'essai gratuit (timestamp absolu ; 0 = pas d'essai en cours).
    var trialEndTS: Double { didSet { d.set(trialEndTS, forKey: "focusdex.trialEnd") } }
    // L'essai gratuit a déjà été consommé (un seul par utilisateur, comme Apple).
    var trialUsed: Bool { didSet { d.set(trialUsed, forKey: "focusdex.trialUsed") } }
    var language: AppLanguage { didSet { d.set(language.rawValue, forKey: "focusdex.lang") } }
    /// Date de première obtention par espèce (yyyy-MM-dd). Clé séparée.
    var dexDates: [String: String] { didSet { if let x = try? JSONEncoder().encode(dexDates) { d.set(x, forKey: "focusdex.dexdates") } } }
    /// XP sauvegardé par espèce de base possédée (pour retrouver son niveau quand on change de compagnon principal).
    var dexXP: [String: Int] { didSet { if let x = try? JSONEncoder().encode(dexXP) { d.set(x, forKey: "focusdex.dexxp") } } }
    /// Espèces ayant déjà atteint leur forme finale (diplôme donné une seule fois).
    var graduatedSpecies: Set<String> { didSet { d.set(Array(graduatedSpecies), forKey: "focusdex.graduated") } }
    /// Surnoms par espèce (clé = famille/base), modifiables depuis la fiche du dex.
    var speciesNickname: [String: String] { didSet { if let x = try? JSONEncoder().encode(speciesNickname) { d.set(x, forKey: "focusdex.nicknames") } } }

    // Icône de l'app (créature épinglée). Reflète UIApplication.alternateIconName.
    var appIconSlug: String?

    // Transient (UI)
    var pendingEvents: [CompanionEvent] = []
    /// Dernière espèce écrite dans l'App Group (évite de réécrire le sprite à chaque save).
    var lastWidgetSpecies: String?

    private let d = UserDefaults.standard
    private let key = "focusdex.save.v1"

    var theme: Theme { Theme.forTone(tone) }

    // MARK: Init / persistance

    init() {
        if let data = UserDefaults.standard.data(forKey: "focusdex.save.v1"),
           let s = try? JSONDecoder().decode(Save.self, from: data) {
            tone = Tone(rawValue: s.tone) ?? .zen
            onboardingDone = s.onboardingDone
            notificationsAsked = s.notificationsAsked
            displayName = s.displayName
            signedIn = s.signedIn
            focusMinutesDefault = s.focusMinutesDefault == 0 ? 25 : s.focusMinutesDefault
            candy = s.candy
            companion = s.companion
            habits = s.habits
            dexSpecies = Set(s.dexSpecies)
            shinySpecies = Set(s.shinySpecies)
            ownedHabitats = Set(s.ownedHabitats).union(["meadow"])
            equippedHabitat = s.equippedHabitat.isEmpty ? "meadow" : s.equippedHabitat
            streak = s.streak
            lastActiveDay = s.lastActiveDay
            totalFocusMinutes = s.totalFocusMinutes
            sessionsCompleted = s.sessionsCompleted
            proActive = s.proActive
        } else {
            tone = .zen; onboardingDone = false; notificationsAsked = false; displayName = ""; signedIn = false
            focusMinutesDefault = 25; candy = 0; companion = nil; habits = Self.defaultHabits()
            dexSpecies = []; shinySpecies = []; ownedHabitats = ["meadow"]; equippedHabitat = "meadow"
            streak = 0; lastActiveDay = ""; totalFocusMinutes = 0; sessionsCompleted = 0; proActive = false
        }
        // Défis + coffre (clés séparées)
        lastChestDay = d.string(forKey: "focusdex.chestDay") ?? ""
        lastPetDay = d.string(forKey: "focusdex.petDay") ?? ""
        pendingEggBase = d.string(forKey: "focusdex.eggBase") ?? ""
        pendingEggShiny = d.bool(forKey: "focusdex.eggShiny")
        boostXPEndTS = d.double(forKey: "focusdex.boostXP")
        boostShinyEndTS = d.double(forKey: "focusdex.boostShiny")
        ownedCosmetics = Set(d.stringArray(forKey: "focusdex.cosmetics") ?? [])
        equippedCosmetic = d.string(forKey: "focusdex.cosmeticOn") ?? ""
        improveAreas = Set(d.stringArray(forKey: "focusdex.areas") ?? [])
        obstacles = Set(d.stringArray(forKey: "focusdex.obstacles") ?? [])
        improveOther = d.string(forKey: "focusdex.areasOther") ?? ""
        obstacleOther = d.string(forKey: "focusdex.obstaclesOther") ?? ""
        dailyGoalMinutes = d.integer(forKey: "focusdex.dailyGoal")
        focusEndTS = d.double(forKey: "focusdex.focusEnd")
        focusPausedRemaining = d.integer(forKey: "focusdex.focusPaused")
        focusSessionMinutes = d.integer(forKey: "focusdex.focusMin")
        trialEndTS = d.double(forKey: "focusdex.trialEnd")
        trialUsed = d.bool(forKey: "focusdex.trialUsed")
        questsDay = d.string(forKey: "focusdex.questsDay") ?? ""
        if let qd = d.data(forKey: "focusdex.quests"), let q = try? JSONDecoder().decode([Quest].self, from: qd) {
            dailyQuests = q
        } else { dailyQuests = [] }
        language = AppLanguage(rawValue: d.string(forKey: "focusdex.lang") ?? "") ?? AppLanguage.systemDefault()
        if let dd = d.data(forKey: "focusdex.dexdates"), let m = try? JSONDecoder().decode([String: String].self, from: dd) {
            dexDates = m
        } else { dexDates = [:] }
        if let dx = d.data(forKey: "focusdex.dexxp"), let m = try? JSONDecoder().decode([String: Int].self, from: dx) {
            dexXP = m
        } else { dexXP = [:] }
        graduatedSpecies = Set(d.stringArray(forKey: "focusdex.graduated") ?? [])
        if let nd = d.data(forKey: "focusdex.nicknames"), let m = try? JSONDecoder().decode([String: String].self, from: nd) {
            speciesNickname = m
        } else { speciesNickname = [:] }
        appIconSlug = UIApplication.shared.alternateIconName
        ensureQuestsFresh()
    }

    // MARK: Localisation

    func t(_ key: String) -> String { Localization.tr(key, language) }
    func rarityLabel(_ r: Rarity) -> String { t(r.title) }
    func toneTitle(_ tone: Tone) -> String { t(tone.title) }
    func toneSubtitle(_ tone: Tone) -> String { t(tone.subtitle) }
    /// Texte localisé d'un défi (gère singulier/pluriel + nombre).
    func questText(_ q: Quest) -> String {
        if q.kind == .chest { return t("Ouvre le coffre du jour") }
        let plural = q.target > 1
        let key: String
        switch q.kind {
        case .focusMinutes: key = "Concentre-toi %d min"
        case .sessions:     key = plural ? "Termine %d sessions" : "Termine %d session"
        case .habits:       key = plural ? "Coche %d habitudes" : "Coche %d habitude"
        case .grow:         key = plural ? "Fais éclore ou évoluer %d créatures" : "Fais éclore ou évoluer %d créature"
        case .chest:        key = "Ouvre le coffre du jour"
        }
        return String(format: t(key), q.target)
    }

    struct Save: Codable {
        var tone: String; var onboardingDone: Bool; var notificationsAsked: Bool; var displayName: String
        var signedIn: Bool = false
        var focusMinutesDefault: Int; var candy: Int; var companion: ActiveCompanion?; var habits: [Habit]
        var dexSpecies: [String]; var shinySpecies: [String]; var ownedHabitats: [String]; var equippedHabitat: String
        var streak: Int; var lastActiveDay: String; var totalFocusMinutes: Int; var sessionsCompleted: Int
        var proActive: Bool
    }

    private func save() {
        let s = Save(tone: tone.rawValue, onboardingDone: onboardingDone, notificationsAsked: notificationsAsked,
                     displayName: displayName, signedIn: signedIn, focusMinutesDefault: focusMinutesDefault, candy: candy,
                     companion: companion, habits: habits, dexSpecies: Array(dexSpecies),
                     shinySpecies: Array(shinySpecies), ownedHabitats: Array(ownedHabitats),
                     equippedHabitat: equippedHabitat, streak: streak, lastActiveDay: lastActiveDay,
                     totalFocusMinutes: totalFocusMinutes, sessionsCompleted: sessionsCompleted, proActive: proActive)
        if let data = try? JSONEncoder().encode(s) { d.set(data, forKey: key) }
        refreshWidget()
    }

    static func defaultHabits() -> [Habit] {
        [Habit(name: "Boire de l'eau", icon: "drop.fill"),
         Habit(name: "Bouger 10 min", icon: "figure.walk"),
         Habit(name: "Lire", icon: "book.fill")]
    }

    // MARK: Dates / streak

    static func today() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }
    static func yesterday() -> String {
        // Recul d'un jour calendaire (robuste aux changements d'heure, contrairement à -86400 s).
        let cal = Calendar.current
        let y = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date())) ?? Date()
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: y)
    }
    private func bumpStreak() {
        let t = Self.today()
        if lastActiveDay == t { return }
        streak = (lastActiveDay == Self.yesterday()) ? streak + 1 : 1
        lastActiveDay = t
    }
    /// Série réellement en cours (0 si rompue : dernière activité ni aujourd'hui ni hier).
    /// L'affichage doit utiliser ceci, pas `streak` brut (qui reste figé jusqu'à la prochaine action).
    var currentStreak: Int {
        guard !lastActiveDay.isEmpty else { return 0 }
        return (lastActiveDay == Self.today() || lastActiveDay == Self.yesterday()) ? streak : 0
    }

    static func daysBetween(_ from: String, _ to: String) -> Int {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        guard let a = f.date(from: from), let b = f.date(from: to) else { return 0 }
        return max(0, Int((b.timeIntervalSince(a) / 86400).rounded()))
    }

    // MARK: Fraîcheur du compagnon (négligence douce — jamais de perte de progression)

    /// Dernier contact (activité de série OU soin/câlin), pour la fraîcheur.
    /// Les chaînes "yyyy-MM-dd" se comparent chronologiquement ; "" est antérieur à toute date.
    private var lastSeenDay: String { max(lastActiveDay, lastPetDay) }
    /// Jours écoulés depuis le dernier contact (activité ou soin).
    var daysAway: Int { lastSeenDay.isEmpty ? 0 : Self.daysBetween(lastSeenDay, Self.today()) }
    /// 1.0 = pimpant. Se ternit doucement après 1 jour d'absence, plancher 0.4.
    /// Purement cosmétique : redevient 1.0 dès la 1ʳᵉ action (bumpStreak met lastActiveDay = aujourd'hui).
    var freshness: Double { max(0.4, 1.0 - Double(max(0, daysAway - 1)) * 0.15) }
    /// La créature « réclame » un peu d'attention (assez d'absence + éclose).
    var companionNeedsAttention: Bool { daysAway >= 2 && (companion?.hatched ?? false) }

    /// Câlin : restaure la fraîcheur et donne un petit bonus une fois par jour. Retourne true si récompensé.
    @discardableResult
    func petCompanion() -> Bool {
        guard companion?.hatched == true else { return false }
        let firstToday = lastPetDay != Self.today()
        lastPetDay = Self.today()                 // fraîcheur restaurée (n'affecte PAS la série)
        if firstToday {
            candy += 2
            addXP(5)
            return true
        }
        return false
    }
    /// Vrai si le câlin du jour n'a pas encore été donné (petit bonus dispo).
    var petBonusAvailable: Bool { (companion?.hatched ?? false) && lastPetDay != Self.today() }

    // MARK: Icône de l'app (créature épinglée)

    /// Change l'icône de l'app pour la créature `slug` (nil = icône par défaut).
    /// iOS affiche une alerte système à chaque changement — donc déclenché seulement sur action volontaire.
    func setAppIcon(_ slug: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(slug) { [weak self] error in
            Task { @MainActor in if error == nil { self?.appIconSlug = slug } }
        }
    }

    // MARK: Compagnon

    var companionCreature: Creature? {
        guard let c = companion, let sid = c.speciesID else { return nil }
        return CreatureDB.creature(sid)
    }
    var companionBase: Creature? { companion.flatMap { CreatureDB.creature($0.baseSpeciesID) } }

    static let maxNameLength = 18
    /// Surnom d'une espèce (par famille), nil si aucun.
    func nickname(forFamily family: String) -> String? {
        let n = speciesNickname[family]?.trimmingCharacters(in: .whitespaces)
        return (n?.isEmpty ?? true) ? nil : n
    }
    /// Définit (ou retire) le surnom d'une espèce ; longueur bornée.
    func setNickname(_ name: String, forFamily family: String) {
        let t = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxNameLength))
        if t.isEmpty { speciesNickname[family] = nil } else { speciesNickname[family] = t }
        if let comp = companion, comp.baseSpeciesID == family { companion?.nickname = t.isEmpty ? nil : t }
    }
    /// Nom d'affichage d'une créature (surnom par espèce, sinon nom d'espèce).
    func displayName(for c: Creature) -> String { nickname(forFamily: c.family) ?? c.name }

    /// Nom affiché du compagnon : surnom s'il existe, sinon nom d'espèce.
    var companionDisplayName: String {
        if let comp = companion, let n = nickname(forFamily: comp.baseSpeciesID) { return n }
        if let n = companion?.nickname, !n.trimmingCharacters(in: .whitespaces).isEmpty { return n }
        return companionCreature?.name ?? "…"
    }
    /// Vrai quand une créature vient d'éclore et attend un surnom.
    var namingRequested = false
    /// Donne (ou retire) un surnom au compagnon actuel.
    func nameCompanion(_ name: String) {
        guard let comp = companion else { return }
        let trimmed = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxNameLength))
        companion?.nickname = trimmed.isEmpty ? nil : trimmed
        setNickname(trimmed, forFamily: comp.baseSpeciesID)
        namingRequested = false
    }

    // MARK: Compagnon principal (changeable depuis le dex)

    /// Forme correspondant à un xp donné pour une base (calcule le stade d'évolution).
    private func speciesFor(base: String, xp: Int) -> String {
        let rarity = CreatureDB.rarity(family: base)
        let comp = ActiveCompanion(baseSpeciesID: base, speciesID: base, rarityRaw: rarity.rawValue, isShiny: false, xp: xp, hatched: true)
        let line = CreatureDB.line(for: base)
        guard !line.isEmpty else { return base }
        let evoIndex = min(line.count - 1, comp.evolveLevels.filter { comp.level >= $0 }.count)
        return line[evoIndex].id
    }

    /// Définit le compagnon principal actif à partir d'une créature POSSÉDÉE. Son niveau est conservé.
    func setMainCompanion(_ creature: Creature) {
        guard owns(creature.id) else { return }
        if let c = companion, c.hatched { dexXP[c.baseSpeciesID] = c.xp }   // sauvegarde l'actuel
        let baseID = CreatureDB.creature(creature.id)?.family ?? creature.id
        if baseID == companion?.baseSpeciesID { return }
        let savedXP = dexXP[baseID] ?? 0
        let rarity = CreatureDB.rarity(family: baseID)
        var comp = ActiveCompanion(baseSpeciesID: baseID, speciesID: speciesFor(base: baseID, xp: savedXP),
                                   rarityRaw: rarity.rawValue, isShiny: shinySpecies.contains(baseID), xp: savedXP, hatched: true)
        comp.nickname = nil
        companion = comp
        namingRequested = false
    }

    /// Range le compagnon actuel (niveau conservé) et démarre un nouvel œuf mystère à découvrir.
    func hatchNewEgg() {
        if let c = companion, c.hatched { dexXP[c.baseSpeciesID] = c.xp }
        startNewEgg()
    }

    /// Vrai si on peut proposer « faire éclore un nouvel œuf » (compagnon actuel éclos).
    var canHatchNewEgg: Bool { companion?.hatched ?? false }

    // MARK: Œuf en attente (offert après un diplôme)

    var hasPendingEgg: Bool { !pendingEggBase.isEmpty }
    var pendingEggRarity: Rarity { CreatureDB.rarity(family: pendingEggBase) }
    /// Fait éclore l'œuf en attente : la créature rejoint le dex et est retournée (le compagnon ne change pas encore).
    @discardableResult
    func hatchPendingEgg() -> Creature? {
        guard !pendingEggBase.isEmpty, let c = CreatureDB.creature(pendingEggBase) else { return nil }
        dexSpecies.insert(c.id); recordCatch(c.id)
        if pendingEggShiny { shinySpecies.insert(c.id) }
        return c
    }
    /// Garde le compagnon actuel ; l'œuf éclos reste simplement dans le dex.
    func keepCurrentCompanion() { pendingEggBase = ""; pendingEggShiny = false }
    /// Adopte la créature fraîchement éclose comme nouveau compagnon principal (niveau 1).
    func adoptHatchedEgg(_ creature: Creature) {
        let baseID = creature.id
        dexSpecies.insert(baseID); recordCatch(baseID)
        if let cur = companion, cur.hatched { dexXP[cur.baseSpeciesID] = cur.xp }   // sauvegarde l'actuel
        let rarity = CreatureDB.rarity(family: baseID)
        var comp = ActiveCompanion(baseSpeciesID: baseID, speciesID: baseID, rarityRaw: rarity.rawValue,
                                   isShiny: pendingEggShiny, xp: 0, hatched: true)
        comp.nickname = nil
        companion = comp
        dexXP[baseID] = 0
        pendingEggBase = ""; pendingEggShiny = false
        // le nommage se fait en ligne dans l'écran d'éclosion (pas de sheet séparée)
    }

    /// Onboarding : le starter choisi arrive déjà éclos (attachement immédiat).
    func setStarter(_ base: Creature) {
        let rarity = CreatureDB.rarity(family: base.family)
        var comp = ActiveCompanion(baseSpeciesID: base.id, speciesID: base.id, rarityRaw: rarity.rawValue,
                                   isShiny: false, xp: 0, hatched: true)
        comp.xp = 0
        companion = comp
        dexSpecies.insert(base.id); recordCatch(base.id)
        dexXP[base.id] = 0
        namingRequested = true
    }

    /// Nouvel œuf mystère (après un diplôme).
    func startNewEgg() {
        let base = CreatureDB.randomBase()
        let rarity = CreatureDB.rarity(family: base.family)
        let shiny = Double.random(in: 0..<1) < shinyChance
        companion = ActiveCompanion(baseSpeciesID: base.id, speciesID: nil, rarityRaw: rarity.rawValue,
                                    isShiny: shiny, xp: 0, hatched: false)
    }

    var shinyChance: Double {
        let base = proActive ? 1.0 / 20.0 : 1.0 / 45.0
        return shinyBoostActive ? min(1, base * 2) : base
    }

    // MARK: Boosts / cosmétiques / œufs spéciaux (boutique)

    var xpBoostActive: Bool { boostXPEndTS > Date().timeIntervalSince1970 }
    var shinyBoostActive: Bool { boostShinyEndTS > Date().timeIntervalSince1970 }
    /// Minutes restantes d'un boost (0 si inactif).
    func boostMinutesLeft(_ end: Double) -> Int { max(0, Int((end - Date().timeIntervalSince1970) / 60)) }
    @discardableResult
    func buyBoost(xp: Bool, price: Int, hours: Double) -> Bool {
        guard candy >= price else { return false }
        candy -= price
        let now = Date().timeIntervalSince1970
        if xp { boostXPEndTS = max(boostXPEndTS, now) + hours * 3600 }
        else { boostShinyEndTS = max(boostShinyEndTS, now) + hours * 3600 }
        return true
    }

    @discardableResult
    func buyCosmetic(_ c: CosmeticItem) -> Bool {
        guard !ownedCosmetics.contains(c.id), candy >= c.price else { return false }
        candy -= c.price; ownedCosmetics.insert(c.id); return true
    }
    func toggleCosmetic(_ id: String) { equippedCosmetic = (equippedCosmetic == id) ? "" : id }
    var equippedCosmeticEmoji: String? {
        equippedCosmetic.isEmpty ? nil : CosmeticItem.all.first { $0.id == equippedCosmetic }?.emoji
    }

    /// Achète un œuf spécial : place un œuf en attente d'un type donné (ou rareté garantie).
    @discardableResult
    func buySpecialEgg(_ egg: SpecialEgg) -> Bool {
        guard !hasPendingEgg, candy >= egg.price else { return false }
        candy -= egg.price
        let pool: [Creature]
        if egg.kind == "rare" {
            pool = CreatureDB.hatchBases.filter { CreatureDB.rarity(family: $0.id) != .common }
        } else {
            pool = CreatureDB.hatchBases.filter { $0.types.contains(egg.kind) }
        }
        let base = pool.randomElement() ?? CreatureDB.randomBase()
        pendingEggBase = base.id
        pendingEggShiny = Double.random(in: 0..<1) < shinyChance
        return true
    }

    /// Cœur de la progression : ajoute du xp et traite éclosion / niveau / évolution / diplôme.
    @discardableResult
    func addXP(_ amount: Int) -> [CompanionEvent] {
        guard amount > 0 else { return [] }
        if companion == nil { startNewEgg() }
        guard var c = companion else { return [] }
        var events: [CompanionEvent] = []
        let oldLevel = c.level
        c.xp += xpBoostActive ? amount * 2 : amount   // boost XP ×2 si actif

        // Éclosion
        if !c.hatched && c.xp >= ActiveCompanion.hatchXP {
            c.xp -= ActiveCompanion.hatchXP
            c.hatched = true
            c.speciesID = c.baseSpeciesID
            dexSpecies.insert(c.baseSpeciesID); recordCatch(c.baseSpeciesID)
            if c.isShiny { shinySpecies.insert(c.baseSpeciesID) }
            events.append(.hatched(c.baseSpeciesID))
            Analytics.capture("egg_hatched", ["species": c.baseSpeciesID, "shiny": c.isShiny])
            // le nommage se fait en ligne dans la célébration d'éclosion (pas de sheet séparée)
        }

        if c.hatched {
            let newLevel = c.level
            if newLevel > oldLevel && oldLevel > 0 { events.append(.leveledUp(newLevel)) }

            // Évolution selon les paliers
            let line = CreatureDB.line(for: c.baseSpeciesID)
            if !line.isEmpty {
                let evoIndex = min(line.count - 1, c.evolveLevels.filter { newLevel >= $0 }.count)
                let target = line[evoIndex].id
                if c.speciesID != target {
                    let from = c.speciesID ?? c.baseSpeciesID
                    c.speciesID = target
                    dexSpecies.insert(target); recordCatch(target)
                    if c.isShiny { shinySpecies.insert(target) }
                    events.append(.evolved(from: from, to: target))
                }
            }

            // Forme finale atteinte : diplôme donné UNE SEULE fois. Le compagnon reste (pas de remplacement auto).
            if newLevel >= c.graduateLevel {
                let finalID = c.speciesID ?? c.baseSpeciesID
                dexSpecies.insert(finalID); recordCatch(finalID)
                if c.isShiny { shinySpecies.insert(finalID) }
                if !graduatedSpecies.contains(c.baseSpeciesID) {
                    graduatedSpecies.insert(c.baseSpeciesID)
                    candy += graduateReward(c.rarity)
                    events.append(.graduated(finalID, shiny: c.isShiny))
                    Analytics.capture("creature_graduated", ["species": finalID])
                    if pendingEggBase.isEmpty {                     // offre un vrai nouvel œuf mystère
                        pendingEggBase = CreatureDB.randomBase().id
                        pendingEggShiny = Double.random(in: 0..<1) < shinyChance
                    }
                }
            }
        }

        companion = c
        if c.hatched { dexXP[c.baseSpeciesID] = c.xp }   // niveau persistant par espèce
        pendingEvents += events
        return events
    }

    private func graduateReward(_ r: Rarity) -> Int {
        switch r { case .common: 40; case .rare: 70; case .epic: 120; case .legendary: 220 }
    }

    // MARK: Session de focus persistante

    var isFocusing: Bool { focusEndTS > 0 || focusPausedRemaining > 0 }
    var isFocusPaused: Bool { focusPausedRemaining > 0 }
    var focusEndDate: Date? { focusEndTS > 0 ? Date(timeIntervalSince1970: focusEndTS) : nil }
    /// Secondes restantes (en pause = gelé ; en cours = calculé sur la date de fin).
    func focusRemaining(asOf now: Date = Date()) -> Int {
        if focusPausedRemaining > 0 { return focusPausedRemaining }
        guard let e = focusEndDate else { return 0 }
        return max(0, Int(e.timeIntervalSince(now).rounded()))
    }

    func startFocus(minutes: Int) {
        focusSessionMinutes = minutes
        focusPausedRemaining = 0
        focusEndTS = Date().addingTimeInterval(Double(minutes * 60)).timeIntervalSince1970
    }
    func pauseFocus() {
        guard focusEndTS > 0 else { return }
        focusPausedRemaining = max(1, focusRemaining())
        focusEndTS = 0
    }
    func resumeFocus() {
        guard focusPausedRemaining > 0 else { return }
        focusEndTS = Date().addingTimeInterval(Double(focusPausedRemaining)).timeIntervalSince1970
        focusPausedRemaining = 0
    }
    func cancelFocus() { focusEndTS = 0; focusPausedRemaining = 0 }

    /// Si une session en cours est arrivée à terme, la valide (récompense + croissance) et la nettoie.
    @discardableResult
    func finishFocusIfDue() -> (candy: Int, xp: Int)? {
        guard focusEndTS > 0, focusRemaining() == 0 else { return nil }
        let minutes = focusSessionMinutes
        cancelFocus()
        let candyBefore = candy
        completeFocus(minutes: minutes)
        let xp = Int(Double(minutes) * 1.3) + 10 + min(20, streak * 2)
        return (candy: candy - candyBefore, xp: xp)
    }

    // MARK: Focus

    /// Fin d'une session de focus réussie.
    @discardableResult
    func completeFocus(minutes: Int) -> [CompanionEvent] {
        ensureQuestsFresh()
        bumpStreak()
        totalFocusMinutes += minutes
        sessionsCompleted += 1
        candy += max(3, minutes / 4)
        let streakBonus = min(20, streak * 2)
        let events = addXP(Int(Double(minutes) * 1.3) + 10 + streakBonus)
        advanceQuest(.focusMinutes, minutes)
        advanceQuest(.sessions, 1)
        advanceQuest(.grow, growCount(events))
        Analytics.capture("focus_session_completed", ["minutes": minutes, "streak": currentStreak])
        return events
    }

    // MARK: Habitudes

    @discardableResult
    func completeHabit(_ id: UUID) -> [CompanionEvent] {
        guard let i = habits.firstIndex(where: { $0.id == id }) else { return [] }
        let t = Self.today()
        guard !habits[i].isDone(today: t) else { return [] }
        habits[i].streak = (habits[i].lastDoneDay == Self.yesterday()) ? habits[i].streak + 1 : 1
        habits[i].lastDoneDay = t
        ensureQuestsFresh()
        bumpStreak()
        candy += 4
        let events = addXP(14)
        advanceQuest(.habits, 1)
        advanceQuest(.grow, growCount(events))
        return events
    }
    /// Coche d'un coup toutes les habitudes prévues aujourd'hui et non encore faites.
    @discardableResult
    func completeAllHabitsToday() -> [CompanionEvent] {
        var events: [CompanionEvent] = []
        let t = Self.today()
        for h in habitsToday where !h.isDone(today: t) {
            events += completeHabit(h.id)
        }
        return events
    }
    func addHabit(name: String, icon: String, days: Set<Int> = []) {
        habits.append(Habit(name: name, icon: icon, days: days))
    }
    func updateHabit(_ id: UUID, name: String, icon: String, days: Set<Int>) {
        guard let i = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[i].name = name; habits[i].icon = icon; habits[i].days = days
    }
    func deleteHabit(_ id: UUID) { habits.removeAll { $0.id == id } }

    static func weekday(_ date: Date = Date()) -> Int { Calendar.current.component(.weekday, from: date) }
    /// Habitudes prévues aujourd'hui (selon leur fréquence).
    var habitsToday: [Habit] { let w = Self.weekday(); return habits.filter { $0.isActive(weekday: w) } }
    var habitsDoneToday: Int {
        let t = Self.today(), w = Self.weekday()
        return habits.filter { $0.isActive(weekday: w) && $0.isDone(today: t) }.count
    }

    // MARK: Dex

    var dexCount: Int { dexSpecies.count }
    var dexTotal: Int { CreatureDB.all.count }
    func owns(_ speciesID: String) -> Bool { dexSpecies.contains(speciesID) }
    func isShiny(_ speciesID: String) -> Bool { shinySpecies.contains(speciesID) }
    func recordCatch(_ id: String) { if dexDates[id] == nil { dexDates[id] = Self.today() } }
    /// Date d'obtention formatée selon la langue, ou nil si inconnue.
    func caughtDate(_ id: String) -> String? {
        guard let s = dexDates[id] else { return nil }
        let iso = DateFormatter(); iso.dateFormat = "yyyy-MM-dd"; iso.locale = Locale(identifier: "en_US_POSIX")
        guard let date = iso.date(from: s) else { return nil }
        let out = DateFormatter(); out.dateStyle = .long; out.locale = Locale(identifier: language.rawValue)
        return out.string(from: date)
    }

    /// Trio de starters à l'onboarding, façon Pokémon : feu, eau, plante (créatures mignonnes de base).
    func starterChoices() -> [Creature] {
        let trio = ["agnite", "kroki", "budaye"].compactMap { CreatureDB.creature($0) }
        if trio.count == 3 { return trio }
        let pool = CreatureDB.bases.filter { CreatureDB.rarity(family: $0.family) == .common || CreatureDB.rarity(family: $0.family) == .rare }
        return Array((pool.isEmpty ? CreatureDB.bases : pool).shuffled().prefix(3))
    }

    /// Petit échantillon de créatures mignonnes pour illustrer « et des centaines à attraper ».
    func teaserCreatures() -> [Creature] {
        let slugs = ["dandicub", "anoleaf", "jelillow", "shybulb", "embra", "dollfin",
                     "conileaf", "cairfrey", "axolightl", "dinoflop", "medipup", "foxko"]
        let picked = slugs.compactMap { CreatureDB.creature($0) }
        return picked.count >= 6 ? picked : Array(CreatureDB.bases.prefix(12))
    }

    // MARK: Cosmétiques / boutique

    /// Pro payant (hors période d'essai) : réservé aux vrais abonnés.
    var hasPaidPro: Bool { proActive && !inTrial }
    func habitatUnlocked(_ h: Habitat) -> Bool {
        if h.proOnly { return hasPaidPro }   // habitats exclusifs : abonnés payants seulement, pas pendant l'essai
        return h.price == 0 || ownedHabitats.contains(h.id)
    }
    @discardableResult
    func buyHabitat(_ h: Habitat) -> Bool {
        guard !habitatUnlocked(h), !h.proOnly, candy >= h.price else { return false }
        candy -= h.price; ownedHabitats.insert(h.id); return true
    }
    func equipHabitat(_ h: Habitat) {
        guard habitatUnlocked(h) else { return }
        equippedHabitat = h.id
    }
    var currentHabitat: Habitat {
        let h = Habitat.byID(equippedHabitat)
        return habitatUnlocked(h) ? h : Habitat.byID("meadow")   // évite d'afficher un habitat redevenu verrouillé
    }

    func grantCandy(_ n: Int) { candy += n }

    /// Achète une friandise/soin en bonbons et l'applique au compagnon.
    @discardableResult
    func buyTreat(_ item: TreatItem) -> Bool {
        guard let comp = companion, candy >= item.candyPrice else { return false }
        _ = comp
        candy -= item.candyPrice
        switch item.effect {
        case .xp(let n): addXP(n)
        case .care: lastPetDay = Self.today()       // fraîcheur restaurée, sans toucher la série
        }
        return true
    }

    // MARK: Pro / essai gratuit

    /// Statut d'abonnement pour l'analytics.
    var planTier: String { inTrial ? "essai" : (proActive ? "payant" : "gratuit") }

    func grantPro() { proActive = true; Analytics.setPerson(["plan": planTier]) }
    func revokePro() {
        proActive = false; trialEndTS = 0
        Analytics.capture("subscription_expired")
        Analytics.setPerson(["plan": "gratuit"])
    }

    /// Essai en cours (Pro actif ET dans la fenêtre d'essai).
    var inTrial: Bool { proActive && trialEndTS > Date().timeIntervalSince1970 }
    /// Jours restants d'essai (au moins 1 tant que l'essai court), sinon nil.
    var trialDaysLeft: Int? {
        guard inTrial else { return nil }
        return max(1, Int(ceil((trialEndTS - Date().timeIntervalSince1970) / 86_400)))
    }
    /// Démarre le suivi de l'essai gratuit (compteur + rappels), fin dans `days` jours.
    func beginTrial(days: Int = 7) { beginTrial(endingAt: Date().addingTimeInterval(Double(days) * 86_400)) }
    func beginTrial(endingAt end: Date) {
        trialEndTS = end.timeIntervalSince1970; trialUsed = true
        Analytics.capture("trial_started")
        Analytics.setPerson(["plan": "essai"])
    }

    // MARK: Défis quotidiens

    func ensureQuestsFresh() {
        if questsDay != Self.today() || dailyQuests.count != 3 {
            dailyQuests = Quests.fresh()
            questsDay = Self.today()
        }
    }
    /// Fait progresser les défis du type donné ; récompense automatiquement à la complétion.
    func advanceQuest(_ kind: QuestKind, _ amount: Int) {
        guard amount > 0 else { return }
        for i in dailyQuests.indices where dailyQuests[i].kind == kind && !dailyQuests[i].done {
            dailyQuests[i].progress += amount
            if dailyQuests[i].done && !dailyQuests[i].claimed {
                dailyQuests[i].claimed = true
                candy += dailyQuests[i].reward
            }
        }
    }
    private func growCount(_ events: [CompanionEvent]) -> Int {
        events.reduce(0) { acc, e in
            switch e { case .hatched, .evolved, .graduated: acc + 1; case .leveledUp: acc }
        }
    }
    var questsDoneToday: Int { dailyQuests.filter { $0.done }.count }

    // MARK: Coffre du jour

    var canClaimChest: Bool { lastChestDay != Self.today() }
    @discardableResult
    func claimChest() -> Int {
        guard canClaimChest else { return 0 }
        lastChestDay = Self.today()
        let r = Int.random(in: 120...320)
        candy += r
        ensureQuestsFresh()
        advanceQuest(.chest, 1)
        return r
    }

    // MARK: Compte / reset

    func signOut() { signedIn = false; displayName = "" }

    /// Réinitialise toute la progression (garde le compte connecté).
    func resetProgress() {
        candy = 0; companion = nil; habits = Self.defaultHabits()
        dexSpecies = []; shinySpecies = []; dexDates = [:]; dexXP = [:]; graduatedSpecies = []
        ownedHabitats = ["meadow"]; equippedHabitat = "meadow"
        streak = 0; lastActiveDay = ""; totalFocusMinutes = 0; sessionsCompleted = 0
        pendingEvents = []
        onboardingDone = false
    }
}
