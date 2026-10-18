import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    let store: Store
    @State private var step = 0
    @State private var chosenStarter: Creature?
    @State private var starters: [Creature] = []
    @State private var userName = ""
    @State private var areas: Set<String> = []
    @State private var obstacles: Set<String> = []
    @State private var improveOther = ""
    @State private var obstacleOther = ""
    @FocusState private var otherFocused: Bool
    @State private var goal = 30
    @State private var showStarterNaming = false
    @State private var showPaywall = false
    @FocusState private var nameFocused: Bool
    @AppStorage("focusdex.paywallSeen") private var paywallSeen = false

    private let stepCount = 11
    // Catalogues (id stable, icône SF, clé de texte localisée)
    private let areaOptions: [(String, String, String)] = [
        ("work", "briefcase.fill", "Travail & études"), ("sport", "figure.run", "Sport & forme"),
        ("reading", "book.fill", "Lecture"), ("sleep", "bed.double.fill", "Sommeil"),
        ("mindful", "leaf.fill", "Calme & méditation"), ("screen", "iphone", "Moins d'écrans"),
    ]
    private let obstacleOptions: [(String, String, String)] = [
        ("distractions", "bell.slash.fill", "Les distractions"), ("procrastination", "hourglass", "La procrastination"),
        ("energy", "bolt.slash.fill", "Le manque d'énergie"), ("motivation", "flame.fill", "Le manque de motivation"),
        ("time", "clock.fill", "Le manque de temps"),
    ]
    private let goalOptions = [15, 30, 45, 60]

    var body: some View {
        let t = model.theme
        VStack(spacing: 0) {
            // progression
            HStack(spacing: 5) {
                ForEach(0..<stepCount, id: \.self) { i in
                    Capsule().fill(i <= step ? t.accent : t.sub.opacity(0.2)).frame(height: 4)
                }
            }.padding(.horizontal, 24).padding(.top, 12)

            ScrollView(showsIndicators: false) {
                Group {
                    switch step {
                    case 0: welcome
                    case 1: improveStep
                    case 2: obstacleStep
                    case 3: goalStep
                    case 4: howItWorks
                    case 5: evidence
                    case 6: nameStep
                    case 7: starterPick
                    case 8: notificationsStep
                    case 9: testimonials
                    default: planStep
                    }
                }
                .padding(.horizontal, 24).padding(.top, 20)
            }

            bottomBar.padding(.horizontal, 24).padding(.bottom, 16)
        }
        .background(t.bg.ignoresSafeArea())
        .onAppear { if starters.isEmpty { starters = model.starterChoices() }; trackStep(step) }
        .onChange(of: step) { _, s in trackStep(s) }
        .sheet(isPresented: $showStarterNaming, onDismiss: { model.namingRequested = false; withAnimation { step += 1 } }) {
            NamingSheet()
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: { paywallSeen = true; model.onboardingDone = true }) {
            PaywallView(store: store, hardMode: true)
        }
    }

    // MARK: Steps

    private var welcome: some View {
        let t = model.theme
        return VStack(spacing: 20) {
            HStack { Spacer(); languagePicker }
            Spacer(minLength: 10)
            heroCreatures
            Text("FocusDex").font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("Concentre-toi, prends soin de toi et fais éclore une collection de créatures."))
                .font(.system(size: 17, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 20)
        }
    }

    private var languagePicker: some View {
        Menu {
            ForEach(AppLanguage.allCases) { l in
                Button { model.language = l } label: { Text("\(l.flag)  \(l.name)") }
            }
        } label: {
            HStack(spacing: 5) {
                Text(model.language.flag)
                Text(model.language.name).font(.system(size: 14, weight: .semibold, design: .rounded))
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(model.theme.sub)
            .padding(.horizontal, 12).padding(.vertical, 7).background(model.theme.bg2, in: Capsule())
        }
    }

    private var heroCreatures: some View {
        HStack(spacing: -14) {
            ForEach(Array(model.teaserCreatures().prefix(4)), id: \.id) { c in
                CreatureImage(sprite: c.sprite).frame(width: 76, height: 76)
                    .background(Circle().fill(model.theme.bg2)).clipShape(Circle())
            }
        }
    }

    private var howItWorks: some View {
        let t = model.theme
        let steps: [(Int, String, String)] = [
            (1, "Concentre-toi", "Lance une session de focus ou coche une habitude."),
            (2, "Fais grandir", "Chaque effort fait grandir ton œuf, qui éclot puis évolue."),
            (3, "Collectionne", "Chaque créature rejoint ton dex. Il y en a 411 à attraper !"),
        ]
        return VStack(spacing: 14) {
            Text(model.t("Comment ça marche")).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("Tes efforts nourrissent un œuf : il éclot, évolue, et rejoint ta collection."))
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center).padding(.bottom, 2)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(steps, id: \.0) { s in
                HStack(spacing: 14) {
                    stepIllustration(s.0).frame(width: 84, height: 66)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 7) {
                            Text("\(s.0)").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(t.onAccent)
                                .frame(width: 22, height: 22).background(t.accentGradient, in: Circle())
                            Text(model.t(s.1)).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                        }
                        Text(model.t(s.2)).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14).background(t.card, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    @ViewBuilder private func stepIllustration(_ n: Int) -> some View {
        let t = model.theme
        switch n {
        case 1:
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(t.accent.opacity(0.12))
                Image(systemName: "timer").font(.system(size: 28, weight: .bold)).foregroundStyle(t.accent)
                Image(systemName: "checkmark.circle.fill").font(.system(size: 18)).foregroundStyle(t.positive)
                    .background(Circle().fill(t.card)).offset(x: 20, y: 18)
            }
        case 2:
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(t.accent.opacity(0.12))
                HStack(spacing: 2) {
                    EggView(progress: 0.45, rarity: .common).frame(width: 26, height: 34)
                    Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold)).foregroundStyle(t.sub)
                    if let c = CreatureDB.creature("agnite") { CreatureImage(sprite: c.sprite).frame(width: 38, height: 38) }
                }
            }
        default:
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(t.accent.opacity(0.12))
                HStack(spacing: -14) {
                    ForEach(Array(model.teaserCreatures().prefix(3)), id: \.id) { c in
                        CreatureImage(sprite: c.sprite).frame(width: 40, height: 40)
                            .background(Circle().fill(t.card)).clipShape(Circle())
                            .overlay(Circle().stroke(t.card, lineWidth: 2))
                    }
                }
            }
        }
    }

    // Écran preuves : bénéfices démontrés par la recherche, chiffres sourcés.
    private var evidence: some View {
        let t = model.theme
        let stats: [(String, String, String)] = [
            ("66 jours", "En moyenne pour qu'une nouvelle habitude devienne automatique.", "Lally et al., University College London (2010)"),
            ("23 min", "Pour retrouver toute sa concentration après une interruption.", "Gloria Mark, University of California, Irvine"),
            ("≈ 40 %", "De nos journées sont faites d'habitudes, pas de décisions.", "Duke University (2002)"),
            ("×2 à ×3", "Plus de chances de tenir un objectif quand on planifie quand et où agir.", "Gollwitzer & Sheeran, méta-analyse (2006)"),
        ]
        return VStack(spacing: 16) {
            Text(model.t("Pourquoi ça marche")).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("FocusDex s'appuie sur des principes validés par la recherche."))
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center).padding(.bottom, 2)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(stats, id: \.0) { s in
                HStack(alignment: .center, spacing: 14) {
                    Text(model.t(s.0)).font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.accent).frame(width: 96, alignment: .leading)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.t(s.1)).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(t.text)
                        Text(s.2).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(t.sub.opacity(0.85))
                    }
                    Spacer(minLength: 0)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(t.card, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // Écran témoignages. PLACEHOLDER : à remplacer par de vrais avis avant publication.
    private var testimonials: some View {
        let t = model.theme
        let items: [(String, String)] = [
            ("Je n'avais jamais tenu une routine aussi longtemps. Voir ma créature grandir me motive chaque jour.", "Camille"),
            ("L'appli qui a rendu mes sessions de travail addictives, dans le bon sens.", "Yanis"),
            ("Douce, mignonne et efficace. Ma collection me suit partout.", "Léa"),
        ]
        return VStack(spacing: 16) {
            Text(model.t("Ils adorent FocusDex")).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("Des personnes qui suivaient le projet avant sa sortie."))
                .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(items, id: \.1) { it in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { _ in Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(t.coin) }
                    }
                    Text(model.t(it.0)).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.text).italic()
                    HStack(spacing: 6) {
                        Circle().fill(t.accent.opacity(0.18)).frame(width: 22, height: 22)
                            .overlay(Text(String(it.1.prefix(1))).font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(t.accent))
                        Text(it.1).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(t.sub)
                    }
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(t.card, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var tonePick: some View {
        let t = model.theme
        return VStack(spacing: 16) {
            Text(model.t("Choisis ton ambiance")).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("Ça change les couleurs de l'app et le ton des messages. Modifiable à tout moment."))
                .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Tone.allCases) { tone in
                let sel = model.tone == tone
                let th = Theme.forTone(tone)
                Button { model.tone = tone } label: {
                    HStack(spacing: 14) {
                        toneSwatch(th)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(tone.emoji).font(.system(size: 20))
                                Text(model.toneTitle(tone)).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                            }
                            Text(model.t(tone == .zen ? "Couleurs claires et chaleureuses, messages doux et bienveillants."
                                                       : "Couleurs sombres et énergiques, ton plus direct et motivant."))
                                .font(.system(size: 12.5, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: sel ? "checkmark.circle.fill" : "circle").font(.system(size: 22)).foregroundStyle(sel ? t.accent : t.sub.opacity(0.4))
                    }
                    .padding(16).background(t.card, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(sel ? t.accent : .clear, lineWidth: 2))
                }
            }
        }
    }

    /// Mini aperçu du thème (fond, carte, accent) pour montrer ce que change l'ambiance.
    private func toneSwatch(_ th: Theme) -> some View {
        RoundedRectangle(cornerRadius: 14).fill(th.bg)
            .frame(width: 60, height: 60)
            .overlay {
                VStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 5).fill(th.card).frame(width: 36, height: 13)
                    Capsule().fill(th.accentGradient).frame(width: 36, height: 11)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.10), lineWidth: 1))
    }

    private var starterPick: some View {
        let t = model.theme
        return VStack(spacing: 16) {
            Text(model.t("Choisis ton starter")).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("Ta première créature. Les autres écloront de tes efforts.")).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                ForEach(starters, id: \.id) { c in
                    let sel = chosenStarter?.id == c.id
                    Button { chosenStarter = c } label: {
                        VStack(spacing: 8) {
                            CreatureImage(sprite: c.sprite).frame(height: 72)
                            Text(c.name).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.text).lineLimit(1)
                            HStack(spacing: 3) { ForEach(c.types, id: \.self) { TypeBadge(type: $0) } }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(t.card, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(sel ? t.accent : .clear, lineWidth: 2.5))
                    }
                }
            }
            if let c = chosenStarter {
                Text(starterBlurb(c))
                    .font(.system(size: 13.5, weight: .medium, design: .rounded)).foregroundStyle(t.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(t.bg2, in: RoundedRectangle(cornerRadius: 14))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            teaserGrid
        }
        .animation(.easeInOut(duration: 0.2), value: chosenStarter?.id)
    }

    private func starterBlurb(_ c: Creature) -> String {
        switch c.id {
        case "agnite": return model.t("Petit lézard de feu, curieux et courageux. Sa flamme grandit avec toi.")
        case "kroki":  return model.t("Croco d'eau joueur et malicieux. Il adore barboter et relever des défis.")
        case "budaye": return model.t("Doux compagnon plante. Il s'épanouit au rythme de tes efforts.")
        default:       return model.t("Ta première créature. Elle grandira avec tes efforts.")
        }
    }

    // Comble l'espace et montre l'ampleur de la collection : exemples de créatures + compteur.
    private var teaserGrid: some View {
        let t = model.theme
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return VStack(spacing: 12) {
            Text(String(format: model.t("Et %d créatures à attraper"), model.dexTotal))
                .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(model.teaserCreatures(), id: \.id) { c in
                    VStack(spacing: 4) {
                        CreatureImage(sprite: c.sprite).frame(height: 46)
                        Text(c.name).font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(t.sub).lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity)
        .background(t.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private var nameStep: some View {
        let t = model.theme
        return VStack(spacing: 16) {
            Spacer(minLength: 10)
            Image(systemName: "person.text.rectangle.fill").font(.system(size: 46)).foregroundStyle(t.accent)
            Text(model.t("Quel est ton prénom ?")).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("Pour personnaliser ton refuge."))
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            TextField(model.t("Ton prénom"), text: $userName)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($nameFocused)
                .padding(14).background(t.bg2, in: RoundedRectangle(cornerRadius: 14))
                .padding(.top, 6).padding(.horizontal, 8)
                .onChange(of: userName) { _, v in model.displayName = String(v.prefix(20)) }
            Spacer(minLength: 10)
        }
        .onAppear {
            if userName.isEmpty { userName = model.displayName }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nameFocused = true }
        }
    }

    private var notificationsStep: some View {
        let t = model.theme
        return VStack(spacing: 16) {
            Spacer(minLength: 10)
            Image(systemName: "bell.badge.fill").font(.system(size: 46)).foregroundStyle(t.accent)
            Text(model.t("Reste régulier·e")).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("Un petit rappel doux par jour pour ne pas casser ta série et faire éclore tes œufs."))
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 10)
        }
    }

    // MARK: Écrans de personnalisation

    private var improveStep: some View {
        VStack(spacing: 14) {
            stepHead(icon: "target", title: model.t("Que veux-tu améliorer ?"),
                     sub: model.t("Choisis un ou plusieurs domaines. On adapte ton refuge."))
            ForEach(areaOptions, id: \.0) { o in
                optionCard(icon: o.1, label: model.t(o.2), selected: areas.contains(o.0)) {
                    if areas.contains(o.0) { areas.remove(o.0) } else { areas.insert(o.0) }
                    Haptics.light()
                }
            }
            optionCard(icon: "ellipsis.circle.fill", label: model.t("Autres"), selected: areas.contains("other")) {
                if areas.contains("other") { areas.remove("other") } else { areas.insert("other"); otherFocused = true }
                Haptics.light()
            }
            if areas.contains("other") { otherField($improveOther) }
        }
    }

    private var obstacleStep: some View {
        VStack(spacing: 14) {
            stepHead(icon: "exclamationmark.triangle.fill", title: model.t("Qu'est-ce qui te freine ?"),
                     sub: model.t("Choisis tout ce qui te correspond."))
            ForEach(obstacleOptions, id: \.0) { o in
                optionCard(icon: o.1, label: model.t(o.2), selected: obstacles.contains(o.0)) {
                    if obstacles.contains(o.0) { obstacles.remove(o.0) } else { obstacles.insert(o.0) }
                    Haptics.light()
                }
            }
            optionCard(icon: "ellipsis.circle.fill", label: model.t("Autres"), selected: obstacles.contains("other")) {
                if obstacles.contains("other") { obstacles.remove("other") } else { obstacles.insert("other"); otherFocused = true }
                Haptics.light()
            }
            if obstacles.contains("other") { otherField($obstacleOther) }
        }
    }

    private func otherField(_ text: Binding<String>) -> some View {
        let t = model.theme
        return TextField(model.t("Précise…"), text: text)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .focused($otherFocused).submitLabel(.done)
            .padding(14).background(t.bg2, in: RoundedRectangle(cornerRadius: 14))
    }

    private var goalStep: some View {
        let t = model.theme
        return VStack(spacing: 14) {
            stepHead(icon: "timer", title: model.t("Ton objectif de focus par jour"),
                     sub: model.t("Tu pourras l'ajuster quand tu veux."))
            ForEach(goalOptions, id: \.self) { m in
                let sel = goal == m
                Button { goal = m; Haptics.light() } label: {
                    HStack(spacing: 14) {
                        Text("\(m)").font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(sel ? t.onAccent : t.accent).frame(width: 54)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(model.t("min par jour")).font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(sel ? t.onAccent : t.text)
                            Text(goalHint(m)).font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(sel ? t.onAccent.opacity(0.9) : t.sub)
                        }
                        Spacer()
                        Image(systemName: sel ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(sel ? t.onAccent : t.sub.opacity(0.4))
                    }
                    .padding(16)
                    .background(sel ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.card), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .onAppear { if model.dailyGoalMinutes > 0 { goal = model.dailyGoalMinutes } }
    }

    private var planStep: some View {
        let t = model.theme
        let name = !userName.isEmpty ? userName : (model.displayName.isEmpty ? model.t("toi") : model.displayName)
        let planAreas = areas.isEmpty ? model.improveAreas : areas
        let planObstacles = obstacles.isEmpty ? model.obstacles : obstacles
        let planAreaOther = improveOther.isEmpty ? model.improveOther : improveOther
        let planObstacleOther = obstacleOther.isEmpty ? model.obstacleOther : obstacleOther
        let planGoal = model.dailyGoalMinutes > 0 ? model.dailyGoalMinutes : goal
        let planStarter = chosenStarter ?? model.companionCreature
        return VStack(spacing: 16) {
            Spacer(minLength: 6)
            ZStack {
                Circle().fill(t.accent.opacity(0.14)).frame(width: 96, height: 96)
                Image(systemName: "checkmark.seal.fill").font(.system(size: 44)).foregroundStyle(t.accent)
            }
            Text(String(format: model.t("Ton plan est prêt, %@ !"), name))
                .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text(model.t("On va faire grandir tout ça, un jour à la fois."))
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 12) {
                planRow(icon: "timer", label: model.t("Focus par jour"), value: "\(planGoal) \(model.t("min"))")
                planRow(icon: "target", label: model.t("Objectifs"),
                        value: planAreas.isEmpty ? "—" : labelList(planAreas, areaOptions, other: planAreaOther))
                if !planObstacles.isEmpty {
                    planRow(icon: "shield.lefthalf.filled", label: model.t("On t'aide contre"),
                            value: labelList(planObstacles, obstacleOptions, other: planObstacleOther))
                }
                if let c = planStarter {
                    planRow(icon: "pawprint.fill", label: model.t("Ton starter"), value: c.name)
                }
            }
            .padding(16).background(t.card, in: RoundedRectangle(cornerRadius: 20))
            Spacer(minLength: 6)
        }
    }

    // Convertit un ensemble d'ids en libellés lisibles, "other" remplacé par le texte saisi.
    private func labelList(_ ids: Set<String>, _ options: [(String, String, String)], other: String) -> String {
        ids.compactMap { id -> String? in
            if id == "other" { let o = other.trimmingCharacters(in: .whitespaces); return o.isEmpty ? nil : o }
            return options.first { $0.0 == id }.map { model.t($0.2) }
        }.joined(separator: ", ")
    }

    private func planRow(icon: String, label: String, value: String) -> some View {
        let t = model.theme
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(t.accent).frame(width: 24)
            Text(label).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(t.sub)
            Spacer(minLength: 8)
            Text(value).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                .multilineTextAlignment(.trailing).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func goalHint(_ m: Int) -> String {
        switch m {
        case 15: return model.t("En douceur")
        case 30: return model.t("Bon rythme")
        case 45: return model.t("Ambitieux")
        default: return model.t("Intense")
        }
    }

    private func stepHead(icon: String, title: String, sub: String) -> some View {
        let t = model.theme
        return VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 40)).foregroundStyle(t.accent).padding(.top, 4)
            Text(title).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text(sub).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)
        }
    }

    private func optionCard(icon: String, label: String, selected: Bool, _ act: @escaping () -> Void) -> some View {
        let t = model.theme
        return Button(action: act) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(selected ? t.onAccent : t.accent).frame(width: 30)
                Text(label).font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(selected ? t.onAccent : t.text)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20)).foregroundStyle(selected ? t.onAccent : t.sub.opacity(0.4))
            }
            .padding(16)
            .background(selected ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.card), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: Barre du bas

    private var bottomBar: some View {
        VStack(spacing: 8) {
            BigButton(title: buttonTitle, enabled: canContinue) { advance() }
            if step > 0 && step < 10 {
                Button { withAnimation { step -= 1 } } label: {
                    Text(model.t("Retour")).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(model.theme.sub)
                }
            }
        }
    }

    private var buttonTitle: String {
        switch step {
        case 7: model.t("Choisir cette créature")
        case 10: model.t("C'est parti !")
        default: model.t("Continuer")
        }
    }
    private var canContinue: Bool {
        switch step {
        case 1: return !areas.isEmpty && (!areas.contains("other") || !improveOther.trimmingCharacters(in: .whitespaces).isEmpty)
        case 2: return !obstacles.isEmpty && (!obstacles.contains("other") || !obstacleOther.trimmingCharacters(in: .whitespaces).isEmpty)
        case 6: return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty   // prénom obligatoire
        case 7: return chosenStarter != nil
        default: return true
        }
    }

    private let stepNames = ["welcome", "improve", "obstacle", "goal", "how_it_works", "evidence",
                             "name", "starter", "notifications", "testimonials", "plan"]
    private func trackStep(_ s: Int) {
        guard s >= 0 && s < stepNames.count else { return }
        Analytics.capture("onboarding_step_viewed", ["index": s, "name": stepNames[s]])
    }

    private func advance() {
        switch step {
        case 1: model.improveAreas = areas; model.improveOther = improveOther; otherFocused = false; withAnimation { step += 1 }
        case 2: model.obstacles = obstacles; model.obstacleOther = obstacleOther; otherFocused = false; withAnimation { step += 1 }
        case 3:
            model.dailyGoalMinutes = goal; model.focusMinutesDefault = min(60, goal)
            withAnimation { step += 1 }
        case 7:
            if let s = chosenStarter { model.setStarter(s); showStarterNaming = true }   // nomme le starter tout de suite
            else { withAnimation { step += 1 } }
        case 8:
            model.notificationsAsked = true
            // Demande l'autorisation (boîte système), attend la réponse, puis continue.
            Task {
                await Notifications.requestAndScheduleAsync(
                    title: model.t("Ton refuge t'attend 🌿"),
                    body: model.t("Une petite session de focus pour faire grandir ta créature ?"))
                withAnimation { step += 1 }
            }
        case 10:
            Analytics.capture("onboarding_completed")
            showPaywall = true
        default:
            withAnimation { step += 1 }
        }
    }
}
