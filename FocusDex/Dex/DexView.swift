import SwiftUI

struct DexView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var selected: Creature?
    @State private var filter: DexFilter = .all
    @State private var search = ""
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    enum DexFilter: CaseIterable { case all, owned, missing, shiny
        var key: String { switch self { case .all: "Tous"; case .owned: "Obtenus"; case .missing: "Manquants"; case .shiny: "Shiny" } }
    }

    private var filtered: [Creature] {
        let q = search.trimmingCharacters(in: .whitespaces)
        return CreatureDB.all.filter { c in
            let owned = model.owns(c.id)
            switch filter {
            case .all: break
            case .owned: if !owned { return false }
            case .missing: if owned { return false }
            case .shiny: if !model.isShiny(c.id) { return false }
            }
            if !q.isEmpty { return owned && c.name.localizedCaseInsensitiveContains(q) }
            return true
        }
    }

    var body: some View {
        if hSize == .regular {
            PokedexDeviceView()   // grand écran / iPhone Duo déplié
        } else {
            compactDex
        }
    }

    private var compactDex: some View {
        let t = model.theme
        return NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    searchField
                    filterBar
                    let list = filtered
                    if list.isEmpty {
                        Text(model.t("Aucune créature ici pour l'instant."))
                            .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                            .padding(.top, 30)
                    } else {
                        LazyVGrid(columns: cols, spacing: 12) {
                            ForEach(list) { c in cell(c) }
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.bottom, 24)
            }
            .background(t.bg.ignoresSafeArea())
            .navigationTitle(model.t("Dex"))
            .sheet(item: $selected) { c in DexDetailView(creature: c) }
        }
    }

    private var searchField: some View {
        let t = model.theme
        return HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .bold)).foregroundStyle(t.sub)
            TextField(model.t("Rechercher"), text: $search)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .autocorrectionDisabled().textInputAutocapitalization(.never)
            if !search.isEmpty {
                Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(t.sub) }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10).background(t.bg2, in: Capsule())
    }

    private var filterBar: some View {
        let t = model.theme
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DexFilter.allCases, id: \.self) { f in
                    let sel = filter == f
                    let count = countFor(f)
                    Button { filter = f } label: {
                        Text("\(model.t(f.key)) \(count)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(sel ? t.onAccent : t.text)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(sel ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.bg2), in: Capsule())
                    }
                }
            }
        }
    }

    private func countFor(_ f: DexFilter) -> Int {
        switch f {
        case .all: return model.dexTotal
        case .owned: return model.dexCount
        case .missing: return model.dexTotal - model.dexCount
        case .shiny: return model.shinySpecies.count
        }
    }

    private var header: some View {
        let t = model.theme
        return SectionCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.t("Collection")).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                    Text("\(model.dexCount) / \(model.dexTotal)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                }
                Spacer()
                Label("\(model.shinySpecies.count)", systemImage: "sparkles")
                    .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(t.coin)
                    .padding(.horizontal, 12).padding(.vertical, 8).background(t.bg2, in: Capsule())
            }
        }
    }

    private func cell(_ c: Creature) -> some View {
        let t = model.theme
        let owned = model.owns(c.id)
        let shiny = model.isShiny(c.id)
        return Button { selected = c } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    CreatureImage(sprite: c.sprite, shiny: shiny, silhouette: !owned)
                        .frame(height: 66)
                    if shiny { ShinyBadge().scaleEffect(0.8).offset(x: 6, y: -6) }
                }
                Text(owned ? model.displayName(for: c) : "???")
                    .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(owned ? t.text : t.sub)
                    .lineLimit(1).minimumScaleFactor(0.7).truncationMode(.tail).padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(t.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct DexDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let creature: Creature
    @State private var renaming = false

    var body: some View {
        let t = model.theme
        let owned = model.owns(creature.id)
        let shiny = model.isShiny(creature.id)
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22).fill(t.bg2).frame(height: 220)
                        CreatureImage(sprite: creature.sprite, shiny: shiny, silhouette: !owned)
                            .frame(width: 160, height: 160)
                    }
                    HStack(spacing: 8) {
                        Text(owned ? model.displayName(for: creature) : model.t("Créature inconnue"))
                            .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                            .lineLimit(1).minimumScaleFactor(0.6).truncationMode(.tail)
                            .contentShape(Rectangle())
                            .onTapGesture { if owned { renaming = true } }
                        if shiny { ShinyBadge() }
                        if owned {
                            Button { renaming = true } label: {
                                Image(systemName: "pencil").font(.system(size: 14, weight: .bold)).foregroundStyle(t.accent)
                                    .frame(width: 30, height: 30).background(t.bg2, in: Circle())
                            }
                        }
                        Spacer(minLength: 4)
                        Text("#\(String(format: "%03d", creature.txmnId))")
                            .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(t.sub)
                            .layoutPriority(1)
                    }
                    HStack(spacing: 8) {
                        ForEach(creature.types, id: \.self) { TypeBadge(type: $0) }
                        Text(model.rarityLabel(CreatureDB.rarity(family: creature.family)))
                            .font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(CreatureDB.rarity(family: creature.family).color, in: Capsule())
                        Spacer()
                    }
                    if owned { infoCard }
                    if owned { mainCompanionButton }
                    if owned { pinButton }
                    evolutionLine
                    Spacer(minLength: 20)
                }
                .padding(18)
            }
            .background(t.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(model.t("Fermer")) { dismiss() } } }
            .sheet(isPresented: $renaming) { RenameSheet(creature: creature) }
        }
    }

    private var infoCard: some View {
        let t = model.theme
        let line = CreatureDB.line(for: creature.id)
        let idx = line.firstIndex { $0.id == creature.id } ?? 0
        let stageKey: String = line.count <= 1 ? "Autonome" : (idx == 0 ? "Forme de base" : (idx == line.count - 1 ? "Forme finale" : "Évolution"))
        return VStack(spacing: 0) {
            infoRow(model.t("Stade"), model.t(stageKey))
            if line.count > 1 { Divider(); infoRow(model.t("Formes"), "\(line.count)") }
            if model.isShiny(creature.id) { Divider(); infoRow(model.t("Shiny"), model.t("Oui")) }
            if let d = model.caughtDate(creature.id) { Divider(); infoRow(model.t("Obtenue le"), d) }
        }
        .padding(.horizontal, 14).padding(.vertical, 4)
        .background(t.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(_ k: String, _ v: String) -> some View {
        let t = model.theme
        return HStack {
            Text(k).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(t.sub)
            Spacer()
            Text(v).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
        }.padding(.vertical, 11)
    }

    private var mainCompanionButton: some View {
        let t = model.theme
        let isMain = model.companion?.baseSpeciesID == (CreatureDB.creature(creature.id)?.family ?? creature.id)
        return Group {
            if isMain {
                HStack(spacing: 10) {
                    Image(systemName: "pawprint.fill").font(.system(size: 16, weight: .bold))
                    Text(model.t("C'est ton compagnon actuel")).font(.system(size: 16, weight: .heavy, design: .rounded))
                    Spacer()
                }
                .foregroundStyle(t.onAccent).padding(16)
                .background(t.accentGradient, in: RoundedRectangle(cornerRadius: 16))
            } else {
                Button {
                    Haptics.success(); model.setMainCompanion(creature); dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "pawprint.fill").font(.system(size: 16, weight: .bold))
                        Text(model.t("Définir comme compagnon")).font(.system(size: 16, weight: .heavy, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).opacity(0.6)
                    }
                    .foregroundStyle(t.accent).padding(16)
                    .background(t.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private var pinButton: some View {
        let t = model.theme
        let isCurrent = model.appIconSlug == creature.id
        return VStack(spacing: 6) {
            Button {
                Haptics.light()
                model.setAppIcon(isCurrent ? nil : creature.id)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isCurrent ? "checkmark.seal.fill" : "app.badge")
                        .font(.system(size: 18, weight: .bold))
                    Text(isCurrent ? model.t("Icône actuelle de l'app") : model.t("Épingler en icône d'app"))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    Spacer()
                    if !isCurrent { Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).opacity(0.6) }
                }
                .foregroundStyle(isCurrent ? t.onAccent : t.accent)
                .padding(16)
                .background(isCurrent ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.accent.opacity(0.12)),
                            in: RoundedRectangle(cornerRadius: 16))
            }
            Text(model.t("iOS te demandera de confirmer le changement."))
                .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var evolutionLine: some View {
        let t = model.theme
        let line = CreatureDB.line(for: creature.id)
        return Group {
            if line.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.t("Évolution")).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.sub)
                    HStack(spacing: 6) {
                        ForEach(Array(line.enumerated()), id: \.element.id) { i, c in
                            if i > 0 { Image(systemName: "arrow.right").font(.system(size: 12)).foregroundStyle(t.sub) }
                            VStack(spacing: 2) {
                                CreatureImage(sprite: c.sprite, silhouette: !model.owns(c.id)).frame(width: 54, height: 54)
                                Text(model.owns(c.id) ? c.name : "???")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundStyle(t.sub).lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(t.card, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
