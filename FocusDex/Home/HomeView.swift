import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    let store: Store
    let goFocus: () -> Void
    let goShop: () -> Void
    var goPaywall: () -> Void = {}
    var goHatch: () -> Void = {}
    @State private var showSettings = false
    @State private var chestReward: Int?
    @State private var companionDetail: Creature?
    @State private var hearts: [FloatingHeart] = []
    @State private var renamingCompanion = false

    private func pet() {
        guard model.companion?.hatched == true else { return }
        let rewarded = model.petCompanion()
        Haptics.light()
        for _ in 0..<(rewarded ? 5 : 3) {
            let h = FloatingHeart(x: CGFloat.random(in: -46...46), delay: Double.random(in: 0...0.18))
            hearts.append(h)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { hearts.removeAll { $0.id == h.id } }
        }
    }

    var body: some View {
        let t = model.theme
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    if let d = model.trialDaysLeft { trialBanner(d) }
                    header
                    if model.hasPendingEgg { eggBanner }
                    terrarium
                    quickActions
                    if model.canClaimChest { chestCard }
                    questsCard
                    statsRow
                    if !model.proActive { proTeaser }
                }
                .padding(.horizontal, 18).padding(.bottom, 24)
            }
            .background(t.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView(store: store) }
            .sheet(isPresented: $renamingCompanion) { if let c = model.companionCreature { RenameSheet(creature: c) } }
            .sheet(item: $companionDetail) { c in DexDetailView(creature: c) }
            .alert(model.t("Coffre du jour") + " 🎁", isPresented: Binding(get: { chestReward != nil }, set: { if !$0 { chestReward = nil } })) {
                Button(model.t("Super !"), role: .cancel) {}
            } message: { Text(String(format: model.t("Tu gagnes %d bonbons. Reviens demain !"), chestReward ?? 0)) }
        }
        .onAppear { model.ensureQuestsFresh() }
    }

    // Compteur d'essai gratuit, tout en haut de l'Accueil. Tap → paywall.
    private func trialBanner(_ days: Int) -> some View {
        let t = model.theme
        let label = days == 1 ? model.t("Essai gratuit : 1 jour restant")
                              : String(format: model.t("Essai gratuit : %d jours restants"), days)
        return Button { goPaywall() } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(t.onAccent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.onAccent)
                    Text(model.t("Touche pour gérer ton abonnement"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(t.onAccent.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(t.onAccent.opacity(0.9))
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(t.accentGradient, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // Carte œuf offert après un diplôme : touche pour ouvrir l'écran d'éclosion.
    private var eggBanner: some View {
        let t = model.theme
        return Button { goHatch() } label: {
            HStack(spacing: 12) {
                EggView(progress: 1, rarity: model.pendingEggRarity).frame(width: 44, height: 52)
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.t("Un nouvel œuf t'attend !")).font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                    Text(model.t("Touche pour le faire éclore")).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(t.sub)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(t.accent)
            }
            .padding(12).background(t.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(t.accent.opacity(0.45), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        let t = model.theme
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                Text(model.displayName.isEmpty ? model.t("Ton refuge") : model.displayName)
                    .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                    .lineLimit(1).minimumScaleFactor(0.6).truncationMode(.tail)
            }
            Spacer()
            CandyPill(); StreakPill()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(t.text).padding(9).background(t.bg2, in: Circle())
            }
        }
        .padding(.top, 8)
    }

    // Terrarium : habitat + œuf/créature + progression
    private var terrarium: some View {
        let t = model.theme
        return SectionCard {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(model.currentHabitat.gradient)
                        .frame(height: 260)
                        .overlay(alignment: .bottom) {
                            Ellipse().fill(.black.opacity(0.16)).frame(width: 150, height: 26).offset(y: -26)
                        }
                    TimelineView(.animation) { ctx in
                        let s = 1.0 + 0.02 * sin(ctx.date.timeIntervalSinceReferenceDate * 1.5)
                        companionView.scaleEffect(s)   // respiration douce, centrée, sans translation
                    }
                    ForEach(hearts) { h in HeartView(x: h.x, delay: h.delay) }
                    VStack {
                        HStack {
                            rarityBadge
                            Spacer()
                            if model.companion?.isShiny == true { ShinyBadge() }
                        }.padding(12)
                        Spacer()
                        if model.companion?.hatched == true {
                            HStack {
                                Spacer()
                                Button { pet() } label: {
                                    Image(systemName: model.petBonusAvailable ? "heart.fill" : "heart")
                                        .font(.system(size: 18, weight: .bold)).foregroundStyle(.pink)
                                        .padding(11).background(.white.opacity(0.9), in: Circle())
                                        .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
                                }
                            }.padding(12)
                        }
                    }
                }
                progress
            }
        }
    }

    @ViewBuilder private var companionView: some View {
        if let comp = model.companion {
            if comp.hatched, let c = model.companionCreature {
                ZStack(alignment: .topTrailing) {
                    CreatureImage(sprite: c.sprite, shiny: comp.isShiny)
                        .frame(width: 170, height: 170)
                        .saturation(model.freshness)
                        .opacity(0.55 + 0.45 * model.freshness)
                    if model.companionNeedsAttention {
                        Text("💤").font(.system(size: 30))
                            .offset(x: 6, y: -6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { companionDetail = c }
                .contextMenu {
                    Button { companionDetail = c } label: {
                        Label(model.t("Voir la fiche"), systemImage: "info.circle")
                    }
                    Button { renamingCompanion = true } label: {
                        Label(model.t("Renommer"), systemImage: "pencil")
                    }
                    Button { model.setAppIcon(c.id) } label: {
                        Label(model.t("Mettre en icône"), systemImage: "app.badge")
                    }
                    Divider()
                    Button { Haptics.light(); model.hatchNewEgg() } label: {
                        Label(model.t("Faire éclore un nouvel œuf"), systemImage: "sparkles")
                    }
                }
            } else {
                EggView(progress: comp.hatchProgress, rarity: comp.rarity).frame(width: 130, height: 165)
            }
        } else {
            Image(systemName: "sparkles").font(.system(size: 60)).foregroundStyle(.white)
        }
    }

    private var rarityBadge: some View {
        Group {
            if let comp = model.companion {
                Text(model.rarityLabel(comp.rarity).uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(comp.rarity.color, in: Capsule())
            }
        }
    }

    private var progress: some View {
        let t = model.theme
        return Group {
            if let comp = model.companion {
                VStack(spacing: 6) {
                    HStack {
                        Text(comp.hatched ? model.companionDisplayName : model.t("Œuf mystère"))
                            .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                            .lineLimit(1).minimumScaleFactor(0.6).truncationMode(.tail)
                            .contentShape(Rectangle())
                            .onTapGesture { if comp.hatched { renamingCompanion = true } }
                        if comp.hatched {
                            Image(systemName: "pencil").font(.system(size: 11, weight: .bold)).foregroundStyle(t.sub)
                        }
                        if comp.hatched { Text("· \(model.t("Niv")) \(comp.level)").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(t.sub) }
                        Spacer()
                        if comp.hatched, let c = model.companionCreature {
                            HStack(spacing: 4) { ForEach(c.types, id: \.self) { TypeBadge(type: $0) } }
                        }
                    }
                    ProgressView(value: comp.hatched ? comp.levelProgress : comp.hatchProgress)
                        .tint(t.accent)
                    Text(comp.hatched ? model.t("Encore un peu de focus pour le niveau suivant")
                                      : model.t("Concentre-toi ou coche une habitude pour faire éclore l'œuf"))
                        .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            BigButton(title: model.t("Démarrer un focus"), icon: "timer") { goFocus() }
        }
    }

    private var chestCard: some View {
        let t = model.theme
        return Button {
            let r = model.claimChest(); if r > 0 { chestReward = r; Haptics.success() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill").font(.system(size: 22)).foregroundStyle(t.onAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.t("Coffre du jour")).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(t.onAccent)
                    Text(model.t("Ta récompense quotidienne t'attend")).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.onAccent.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(t.onAccent.opacity(0.8))
            }
            .padding(16).background(t.accentGradient, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var questsCard: some View {
        let t = model.theme
        return SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(model.t("Défis du jour")).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                    Spacer()
                    Text("\(model.questsDoneToday)/\(model.dailyQuests.count)")
                        .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(t.sub)
                }
                ForEach(model.dailyQuests) { q in questRow(q) }
            }
        }
    }
    private func questRow(_ q: Quest) -> some View {
        let t = model.theme
        return HStack(spacing: 10) {
            Image(systemName: q.done ? "checkmark.circle.fill" : q.icon)
                .font(.system(size: 15, weight: .bold)).foregroundStyle(q.done ? t.positive : t.accent).frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(model.questText(q)).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(t.text)
                ProgressView(value: Double(min(q.progress, q.target)), total: Double(q.target)).tint(q.done ? t.positive : t.accent)
            }
            Text("+\(q.reward)").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(t.coin)
            Image(systemName: "circle.hexagongrid.fill").font(.system(size: 12)).foregroundStyle(t.coin)
        }
    }

    private var statsRow: some View {
        let t = model.theme
        return HStack(spacing: 12) {
            miniStat(icon: "timer", value: "\(model.totalFocusMinutes)", label: model.t("min focus"), tint: t.accent)
            miniStat(icon: "checkmark.seal.fill", value: "\(model.habitsDoneToday)/\(model.habits.count)", label: model.t("habitudes"), tint: t.positive)
            miniStat(icon: "square.grid.2x2.fill", value: "\(model.dexCount)/\(model.dexTotal)", label: model.t("dex"), tint: t.coin)
        }
    }
    private func miniStat(icon: String, value: String, label: String, tint: Color) -> some View {
        let t = model.theme
        return VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(tint)
            Text(value).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(t.bg2, in: RoundedRectangle(cornerRadius: 16))
    }

    private var proTeaser: some View {
        let t = model.theme
        return Button { goShop() } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill").font(.system(size: 20)).foregroundStyle(t.coin)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.t("Passe en Pro")).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                    Text(model.t("Éclosion accélérée, shiny x2, habitats exclusifs")).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(t.sub)
            }
            .padding(14).background(t.card, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(t.coin.opacity(0.4), lineWidth: 1.5))
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        return model.t(h < 12 ? "Bonjour" : (h < 18 ? "Bon après-midi" : "Bonsoir"))
    }
}

/// Cœur qui s'envole lors d'un câlin.
struct FloatingHeart: Identifiable { let id = UUID(); let x: CGFloat; let delay: Double }

struct HeartView: View {
    let x: CGFloat
    let delay: Double
    @State private var up = false
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 20))
            .foregroundStyle(.pink)
            .offset(x: x, y: up ? -95 : 20)
            .opacity(up ? 0 : 1)
            .scaleEffect(up ? 1.3 : 0.5)
            .onAppear { withAnimation(.easeOut(duration: 1.2).delay(delay)) { up = true } }
    }
}

/// Petit badge de type coloré.
struct TypeBadge: View {
    let type: String
    var body: some View {
        Text(TypeColor.label(type))
            .font(.system(size: 10, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(TypeColor.color(type), in: Capsule())
    }
}

/// Œuf stylisé avec progression (fissures qui apparaissent).
struct EggView: View {
    let progress: Double
    let rarity: Rarity
    @State private var wobble = false
    var body: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: [.white, rarity.color.opacity(0.25)], startPoint: .top, endPoint: .bottom))
                .overlay(Ellipse().stroke(rarity.color.opacity(0.5), lineWidth: 3))
            // taches
            Circle().fill(rarity.color.opacity(0.35)).frame(width: 26, height: 26).offset(x: -18, y: 10)
            Circle().fill(rarity.color.opacity(0.25)).frame(width: 18, height: 18).offset(x: 20, y: -14)
            if progress > 0.5 {
                Image(systemName: "bolt.fill").font(.system(size: 22)).foregroundStyle(rarity.color).opacity(0.6)
            }
        }
        .rotationEffect(.degrees(wobble ? 3 : -3))
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: wobble)
        .onAppear { wobble = true }
    }
}

// MARK: - Écran d'éclosion d'un œuf offert (après diplôme) : reveal + choix garder/adopter

struct HatchEggView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var revealed: Creature?
    @State private var newName = ""
    @FocusState private var nameFocused: Bool
    @State private var pop = false
    @State private var sparkle = false

    var body: some View {
        let t = model.theme
        NavigationStack {
            VStack(spacing: 22) {
                if let newC = revealed {
                    reveal(newC)
                } else {
                    preview
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .background(t.bg.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(model.t("Plus tard")) { dismiss() } } }
        }
    }

    // Avant éclosion : compagnon actuel + œuf mystère
    private var preview: some View {
        let t = model.theme
        return VStack(spacing: 22) {
            Spacer(minLength: 4)
            Text(model.t("Un nouvel œuf est arrivé !"))
                .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 24) {
                miniCompanion
                Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundStyle(t.sub)
                Button { hatch() } label: {
                    VStack(spacing: 6) {
                        EggView(progress: 1, rarity: model.pendingEggRarity).frame(width: 96, height: 112)
                            .scaleEffect(pop ? 1.05 : 1)
                        Text(model.t("Œuf mystère")).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(t.sub)
                    }
                }.buttonStyle(.plain)
            }
            Text(model.t("Touche l'œuf pour le faire éclore"))
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Spacer()
            BigButton(title: model.t("Faire éclore"), icon: "sparkles") { hatch() }
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pop = true } }
    }

    private var miniCompanion: some View {
        let t = model.theme
        return VStack(spacing: 6) {
            ZStack {
                Circle().fill(t.bg2).frame(width: 96, height: 96)
                if let c = model.companionCreature {
                    CreatureImage(sprite: c.sprite, shiny: model.companion?.isShiny ?? false).frame(width: 74, height: 74)
                }
            }
            Text(model.companionDisplayName).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(t.sub).lineLimit(1)
        }
    }

    // Après éclosion : reveal + choix
    private func reveal(_ newC: Creature) -> some View {
        let t = model.theme
        return VStack(spacing: 18) {
            Spacer(minLength: 4)
            Text(model.t("Éclosion ! 🎉")).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            ZStack {
                Circle().fill(t.accent.opacity(0.18)).frame(width: 220, height: 220)
                    .scaleEffect(sparkle ? 1.1 : 0.8)
                CreatureImage(sprite: newC.sprite, shiny: model.pendingEggShiny)
                    .frame(width: 160, height: 160).scaleEffect(pop ? 1 : 0.3)
            }
            Text(String(format: model.t("Un·e %@ est né·e !"), newC.name))
                .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            // Nommage EN LIGNE (pas d'écran séparé)
            TextField(newC.name, text: $newName)
                .font(.system(size: 18, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                .focused($nameFocused).submitLabel(.done)
                .padding(12).background(t.bg2, in: RoundedRectangle(cornerRadius: 14)).padding(.horizontal, 20)
            Spacer()
            VStack(spacing: 10) {
                // Option mise en avant : adopter le nouveau (garde le nom saisi)
                BigButton(title: String(format: model.t("Adopter %@"), adoptedName(newC))) {
                    model.adoptHatchedEgg(newC)
                    let nm = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    model.nameCompanion(nm.isEmpty ? newC.name : nm)
                    dismiss()
                }
                Button { model.keepCurrentCompanion(); dismiss() } label: {
                    Text(String(format: model.t("Garder %@ à l'accueil"), model.companionDisplayName))
                        .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(t.sub)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(t.bg2, in: Capsule())
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { pop = true }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { sparkle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { nameFocused = true }   // ouvre le clavier
        }
    }

    private func adoptedName(_ c: Creature) -> String {
        let nm = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        return nm.isEmpty ? c.name : nm
    }

    private func hatch() {
        guard let c = model.hatchPendingEgg() else { dismiss(); return }
        Haptics.success()
        pop = false
        withAnimation { revealed = c }
    }
}
