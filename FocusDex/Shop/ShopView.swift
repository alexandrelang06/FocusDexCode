import SwiftUI

struct ShopView: View {
    @Environment(AppModel.self) private var model
    let store: Store
    @State private var showPaywall = false
    @State private var feeding: FeedItem?

    struct FeedItem: Identifiable { let id = UUID(); let emoji: String; let text: String }

    var body: some View {
        let t = model.theme
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    if !model.proActive { proBanner } else { proActiveCard }
                    candySection
                    treatsSection
                    boostsSection
                    specialEggsSection
                    habitatsSection
                    creditsLink
                }
                .padding(.horizontal, 18).padding(.bottom, 24)
            }
            .background(t.bg.ignoresSafeArea())
            .navigationTitle(model.t("Boutique"))
            .toolbar { ToolbarItem(placement: .topBarTrailing) { CandyPill() } }
            .sheet(isPresented: $showPaywall) { PaywallView(store: store, source: "shop") }
        }
        .overlay { if let f = feeding { FeedingView(item: f) { feeding = nil } } }
    }

    private var proBanner: some View {
        let t = model.theme
        return Button { showPaywall = true } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "crown.fill").foregroundStyle(t.coin)
                    Text(model.t("FocusDex Pro")).font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                    Spacer()
                }
                Text(model.t("Éclosion accélérée · shiny ×2 · habitats exclusifs · thèmes"))
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                Text(model.t("Voir les offres"))
                    .font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.onAccent)
                    .padding(.horizontal, 16).padding(.vertical, 9).background(t.accentGradient, in: Capsule())
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(t.card, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(t.coin.opacity(0.4), lineWidth: 1.5))
        }
    }

    private var proActiveCard: some View {
        let t = model.theme
        let trial = model.trialDaysLeft
        let subtitle: String = {
            if let d = trial { return d == 1 ? model.t("1 jour restant") : String(format: model.t("%d jours restants"), d) }
            return model.t("Merci de soutenir FocusDex 💜")
        }()
        return HStack {
            Image(systemName: "crown.fill").font(.system(size: 22)).foregroundStyle(t.coin)
            VStack(alignment: .leading, spacing: 2) {
                Text(trial != nil ? model.t("Essai gratuit") : model.t("Pro actif"))
                    .font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                Text(subtitle).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
            }
            Spacer()
        }
        .padding(16).background(t.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var habitatsSection: some View {
        let t = model.theme
        return VStack(alignment: .leading, spacing: 10) {
            Text(model.t("Habitats")).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(Habitat.all) { h in habitatCell(h) }
            }
        }
    }

    private func habitatCell(_ h: Habitat) -> some View {
        let t = model.theme
        let unlocked = model.habitatUnlocked(h)
        let equipped = model.equippedHabitat == h.id
        return VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14).fill(h.gradient).frame(height: 84)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(equipped ? t.accent : .white.opacity(0.2), lineWidth: equipped ? 3 : 1))
                if h.proOnly { Image(systemName: "crown.fill").font(.system(size: 12)).foregroundStyle(.white).padding(6) }
            }
            Text(model.t(h.name)).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            action(h, unlocked: unlocked, equipped: equipped)
        }
        .padding(10).background(t.card, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder private func action(_ h: Habitat, unlocked: Bool, equipped: Bool) -> some View {
        let t = model.theme
        if equipped {
            pill(model.t("Équipé"), bg: t.bg2, fg: t.accent) {}
        } else if unlocked {
            pill(model.t("Choisir"), bg: t.accent, fg: t.onAccent) { model.equipHabitat(h) }
        } else if h.proOnly {
            pill(model.t("Pro"), bg: t.coin, fg: .white) { showPaywall = true }
        } else {
            let ok = h.price <= model.candy
            Button { model.buyHabitat(h) } label: {
                candyLabel(h.price, fg: ok ? t.onAccent : t.sub)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(ok ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.bg2), in: Capsule())
            }
        }
    }
    private func pill(_ txt: String, bg: Color, fg: Color, _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Text(txt).font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(fg)
                .frame(maxWidth: .infinity).padding(.vertical, 8).background(bg, in: Capsule())
        }
    }
    /// Prix en bonbons avec le logo « ruche » (uniforme dans toute l'app).
    private func candyLabel(_ price: Int, fg: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(price)")
            Image(systemName: "circle.hexagongrid.fill").font(.system(size: 12))
        }
        .font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(fg)
    }

    // Recharge de bonbons — achat en argent réel (StoreKit).
    private var candySection: some View {
        let t = model.theme
        return VStack(alignment: .leading, spacing: 10) {
            Text(model.t("Recharger des bonbons")).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            ForEach(Store.candyPacks) { pack in
                HStack {
                    Image(systemName: "circle.hexagongrid.fill").font(.system(size: 24)).foregroundStyle(t.coin).frame(width: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(pack.candy) \(model.t("bonbons"))").font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                        Text(model.t("Pour gâter ton compagnon et débloquer des habitats.")).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                    }
                    Spacer()
                    Button { Task { await store.purchase(pack.id) } } label: {
                        Text(store.priceLabel(pack.id, fallback: pack.fallback))
                            .font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.onAccent)
                            .padding(.horizontal, 16).padding(.vertical, 9).background(t.accentGradient, in: Capsule())
                    }
                }
                .padding(14).background(t.card, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // Friandises & soins — dépensés en bonbons, offerts au compagnon.
    private var treatsSection: some View {
        let t = model.theme
        return VStack(alignment: .leading, spacing: 10) {
            Text(model.t("Friandises & soins")).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("À offrir à ton compagnon pour le faire grandir ou le requinquer."))
                .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
            ForEach(TreatItem.all) { item in treatRow(item) }
        }
    }

    private func treatRow(_ item: TreatItem) -> some View {
        let t = model.theme
        let affordable = model.candy >= item.candyPrice && model.companion != nil
        return HStack(spacing: 12) {
            Text(item.emoji).font(.system(size: 30)).frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.t(item.nameKey)).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                Text(model.t(item.descKey)).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
            }
            Spacer()
            Button {
                if model.buyTreat(item) {
                    Haptics.success()
                    let reward: String
                    switch item.effect {
                    case .xp(let n): reward = "+\(n) XP"
                    case .care: reward = model.t("Tout requinqué !")
                    }
                    feeding = FeedItem(emoji: item.emoji, text: reward)
                }
            } label: {
                candyLabel(item.candyPrice, fg: affordable ? t.onAccent : t.sub)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(affordable ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.bg2), in: Capsule())
            }
            .disabled(!affordable)
        }
        .padding(14).background(t.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // Boosts temporaires (XP ×2 / shiny ×2)
    private var boostsSection: some View {
        let t = model.theme
        return VStack(alignment: .leading, spacing: 10) {
            Text(model.t("Boosts")).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            boostRow(icon: "bolt.fill", tint: t.accent, name: model.t("XP ×2 (2 h)"),
                     desc: model.t("Toutes tes sessions rapportent le double."),
                     active: model.xpBoostActive, left: model.boostMinutesLeft(model.boostXPEndTS), price: 150) {
                if model.buyBoost(xp: true, price: 150, hours: 2) { Haptics.success() }
            }
            boostRow(icon: "sparkles", tint: t.coin, name: model.t("Shiny ×2 (24 h)"),
                     desc: model.t("Double tes chances de shiny pendant 24 h."),
                     active: model.shinyBoostActive, left: model.boostMinutesLeft(model.boostShinyEndTS), price: 250) {
                if model.buyBoost(xp: false, price: 250, hours: 24) { Haptics.success() }
            }
        }
    }
    private func boostRow(icon: String, tint: Color, name: String, desc: String, active: Bool, left: Int, price: Int, _ act: @escaping () -> Void) -> some View {
        let t = model.theme
        return HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(tint).frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                Text(active ? String(format: model.t("Actif · %d min restantes"), left) : desc)
                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(active ? t.positive : t.sub)
            }
            Spacer()
            Button(action: act) {
                candyLabel(price, fg: model.candy >= price ? t.onAccent : t.sub)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(model.candy >= price ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.bg2), in: Capsule())
            }.disabled(model.candy < price)
        }
        .padding(14).background(t.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // Œufs spéciaux (type garanti / rareté)
    private var specialEggsSection: some View {
        let t = model.theme
        return VStack(alignment: .leading, spacing: 10) {
            Text(model.t("Œufs spéciaux")).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            if model.hasPendingEgg {
                Text(model.t("Un œuf t'attend déjà. Fais-le éclore depuis l'accueil avant d'en acheter un autre."))
                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(SpecialEgg.all) { egg in
                let ok = !model.hasPendingEgg && model.candy >= egg.price
                HStack(spacing: 12) {
                    Text(egg.emoji).font(.system(size: 26)).frame(width: 34)
                    Text(model.t(egg.nameKey)).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                    Spacer()
                    Button { if model.buySpecialEgg(egg) { Haptics.success() } } label: {
                        candyLabel(egg.price, fg: ok ? t.onAccent : t.sub)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(ok ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.bg2), in: Capsule())
                    }.disabled(!ok)
                }
                .padding(14).background(t.card, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var creditsLink: some View {
        NavigationLink { CreditsView() } label: {
            Text(model.t("Crédits & licences")).font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(model.theme.sub).padding(.top, 8)
        }
    }
}

/// Petite animation « nourrissage » : le compagnon reçoit la friandise (montre l'XP gagné).
private struct FeedingView: View {
    @Environment(AppModel.self) private var model
    let item: ShopView.FeedItem
    let onDone: () -> Void
    @State private var pop = false
    @State private var treatY: CGFloat = -70
    @State private var treatShown = true
    @State private var hearts = false

    var body: some View {
        let t = model.theme
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture(perform: onDone)
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(t.accent.opacity(0.22)).frame(width: 210, height: 210)
                    if let c = model.companionCreature {
                        CreatureImage(sprite: c.sprite, shiny: model.companion?.isShiny ?? false)
                            .frame(width: 150, height: 150)
                            .scaleEffect(pop ? 1.06 : 0.95, anchor: .bottom)
                    } else {
                        Image(systemName: "leaf.fill").font(.system(size: 60)).foregroundStyle(.white)
                    }
                    // cœurs qui montent
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "heart.fill").font(.system(size: 15)).foregroundStyle(.pink)
                            .offset(x: CGFloat(i * 22 - 44), y: hearts ? -90 : 10)
                            .opacity(hearts ? 0 : 1)
                            .animation(.easeOut(duration: 1.0).delay(Double(i) * 0.08), value: hearts)
                    }
                    // la friandise tombe dans la créature
                    Text(item.emoji).font(.system(size: 46)).offset(y: treatY).opacity(treatShown ? 1 : 0)
                }
                Text(item.text).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                Text(model.t("Miam ! 😋")).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { pop = true }
            withAnimation(.easeIn(duration: 0.45)) { treatY = 35 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.2)) { treatShown = false }
                hearts = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { onDone() }
        }
    }
}
