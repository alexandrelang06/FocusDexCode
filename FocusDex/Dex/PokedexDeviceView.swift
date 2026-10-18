import SwiftUI

/// Layout « Pokédex » pour grand écran (largeur régulière : iPad, iPhone Duo déplié).
/// Boîtier rouge, écran liste à gauche, écran créature à droite.
struct PokedexDeviceView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: Creature = CreatureDB.all.first ?? CreatureDB.bases.first!

    private var owned: Bool { model.owns(selected.id) }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 18) {
                leftScreen
                    .frame(width: max(240, geo.size.width * 0.36))
                hinge
                rightScreen
            }
            .padding(22)
            .background(deviceBody)
            .padding(16)
        }
        .background(Color.hex(0x2A1417).ignoresSafeArea())
    }

    // MARK: Boîtier

    private var deviceBody: some View {
        RoundedRectangle(cornerRadius: 34)
            .fill(LinearGradient(colors: [.hex(0xF0515B), .hex(0xD23A44)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 34).stroke(.white.opacity(0.15), lineWidth: 2))
            .overlay(alignment: .topLeading) { lights.padding(22) }
            .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
    }

    private var lights: some View {
        HStack(spacing: 10) {
            Circle().fill(LinearGradient(colors: [.hex(0xBFE6FF), .hex(0x4FA8E0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 3))
                .overlay(Circle().fill(.white.opacity(0.5)).frame(width: 8, height: 8).offset(x: -6, y: -6))
            Circle().fill(.red).frame(width: 11, height: 11)
            Circle().fill(.yellow).frame(width: 11, height: 11)
            Circle().fill(.green).frame(width: 11, height: 11)
            Spacer()
        }
    }

    // MARK: Écran gauche (liste)

    private var leftScreen: some View {
        VStack(spacing: 10) {
            HStack {
                Text(model.t("Dex")).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                Spacer()
                Text("\(model.dexCount)/\(model.dexTotal)").font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 4)
            screenFrame {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 4) {
                            ForEach(CreatureDB.all) { c in listRow(c) }
                        }
                        .padding(8)
                    }
                    .onAppear { proxy.scrollTo(selected.id, anchor: .center) }
                }
            }
        }
    }

    private func listRow(_ c: Creature) -> some View {
        let has = model.owns(c.id)
        let sel = selected.id == c.id
        return Button { selected = c } label: {
            HStack(spacing: 10) {
                Text(String(format: "%03d", c.txmnId)).font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45)).frame(width: 38, alignment: .leading)
                CreatureImage(sprite: c.sprite, shiny: model.isShiny(c.id), silhouette: !has).frame(width: 34, height: 34)
                Text(has ? c.name : "???").font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(has ? .white : .white.opacity(0.5)).lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(sel ? Color.white.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .id(c.id)
    }

    // MARK: Charnière

    private var hinge: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule().fill(.black.opacity(0.25)).frame(width: 5, height: 40)
            }
        }
    }

    // MARK: Écran droit (détail)

    private var rightScreen: some View {
        VStack(spacing: 10) {
            HStack {
                Text(owned ? selected.name : model.t("Créature inconnue"))
                    .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                if model.isShiny(selected.id) { ShinyBadge() }
                Spacer()
                Text("#\(String(format: "%03d", selected.txmnId))")
                    .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 4)
            screenFrame {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20).fill(model.currentHabitat.gradient).frame(height: 220)
                            CreatureImage(sprite: selected.sprite, shiny: model.isShiny(selected.id), silhouette: !owned)
                                .frame(width: 170, height: 170)
                        }
                        HStack(spacing: 8) {
                            ForEach(selected.types, id: \.self) { TypeBadge(type: $0) }
                            Text(model.rarityLabel(CreatureDB.rarity(family: selected.family)))
                                .font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(CreatureDB.rarity(family: selected.family).color, in: Capsule())
                            Spacer()
                        }
                        if owned { infoRows }
                        if owned { pinButton }
                        evolution
                    }
                    .padding(14)
                }
            }
        }
    }

    private var infoRows: some View {
        let line = CreatureDB.line(for: selected.id)
        let idx = line.firstIndex { $0.id == selected.id } ?? 0
        let stageKey: String = line.count <= 1 ? "Autonome" : (idx == 0 ? "Forme de base" : (idx == line.count - 1 ? "Forme finale" : "Évolution"))
        return VStack(spacing: 0) {
            row(model.t("Stade"), model.t(stageKey))
            if line.count > 1 { Divider().overlay(.white.opacity(0.15)); row(model.t("Formes"), "\(line.count)") }
            if let d = model.caughtDate(selected.id) { Divider().overlay(.white.opacity(0.15)); row(model.t("Obtenue le"), d) }
        }
        .padding(.horizontal, 14).padding(.vertical, 2)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(v).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(.white)
        }.padding(.vertical, 10)
    }

    private var pinButton: some View {
        let isCurrent = model.appIconSlug == selected.id
        return Button {
            Haptics.light(); model.setAppIcon(isCurrent ? nil : selected.id)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isCurrent ? "checkmark.seal.fill" : "app.badge").font(.system(size: 16, weight: .bold))
                Text(isCurrent ? model.t("Icône actuelle de l'app") : model.t("Épingler en icône d'app"))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var evolution: some View {
        let line = CreatureDB.line(for: selected.id)
        return Group {
            if line.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.t("Évolution")).font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(.white.opacity(0.7))
                    HStack(spacing: 6) {
                        ForEach(Array(line.enumerated()), id: \.element.id) { i, c in
                            if i > 0 { Image(systemName: "arrow.right").font(.system(size: 12)).foregroundStyle(.white.opacity(0.6)) }
                            Button { selected = c } label: {
                                CreatureImage(sprite: c.sprite, silhouette: !model.owns(c.id)).frame(width: 52, height: 52)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: Cadre d'écran commun

    private func screenFrame<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .background(Color.hex(0x24303A))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.black.opacity(0.4), lineWidth: 6))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08), lineWidth: 1))
    }
}
