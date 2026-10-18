import SwiftUI

// MARK: Boutons

struct BigButton: View {
    @Environment(AppModel.self) private var model
    let title: String
    var icon: String? = nil
    var filled: Bool = true
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        let t = model.theme
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(filled ? t.onAccent : t.text)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(filled ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.bg2), in: Capsule())
            .opacity(enabled ? 1 : 0.5)
        }
        .disabled(!enabled)
    }
}

struct CandyPill: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let t = model.theme
        HStack(spacing: 5) {
            Image(systemName: "circle.hexagongrid.fill").foregroundStyle(t.coin)
            Text("\(model.candy)").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(t.bg2, in: Capsule())
    }
}

struct StreakPill: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let t = model.theme
        HStack(spacing: 5) {
            Image(systemName: "flame.fill").foregroundStyle(t.danger)
            Text("\(model.currentStreak)").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(t.bg2, in: Capsule())
    }
}

struct SectionCard<Content: View>: View {
    @Environment(AppModel.self) private var model
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .background(model.theme.card, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(model.theme.sub.opacity(0.08), lineWidth: 1))
    }
}

// MARK: Célébration (éclosion / évolution / diplôme)

struct CelebrationView: View {
    @Environment(AppModel.self) private var model
    let event: CompanionEvent
    let onDismiss: () -> Void
    @State private var pop = false
    @State private var sparkle = false
    @State private var nameText = ""
    @FocusState private var nameFocused: Bool

    private var isHatch: Bool { if case .hatched = event { return true }; return false }
    private func finish() {
        if isHatch {
            let nm = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !nm.isEmpty { model.nameCompanion(nm) }
        }
        onDismiss()
    }

    var body: some View {
        let t = model.theme
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea().onTapGesture { if !isHatch { onDismiss() } }
            VStack(spacing: 18) {
                Text(title).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .opacity(pop ? 1 : 0)
                ZStack {
                    Circle().fill(t.accent.opacity(0.35)).frame(width: 240, height: 240)
                        .blur(radius: 40).scaleEffect(sparkle ? 1.15 : 0.7).opacity(pop ? 1 : 0)
                    ForEach(0..<10, id: \.self) { i in
                        Image(systemName: "sparkle").font(.system(size: 16))
                            .foregroundStyle(.white)
                            .offset(x: sparkle ? CGFloat(cos(Double(i)/10*2*Double.pi))*130 : 0,
                                    y: sparkle ? CGFloat(sin(Double(i)/10*2*Double.pi))*130 : 0)
                            .opacity(sparkle ? 0 : 0.9)
                            .animation(.easeOut(duration: 0.9).delay(Double(i)*0.02), value: sparkle)
                    }
                    if let sprite = spriteName {
                        CreatureImage(sprite: sprite, shiny: isShiny)
                            .frame(width: 170, height: 170)
                            .scaleEffect(pop ? 1 : 0.2)
                            .rotationEffect(.degrees(pop ? 0 : -12))
                    }
                }
                .frame(height: 240)
                if let name = creatureName {
                    HStack(spacing: 8) {
                        Text(name).font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        if isShiny { ShinyBadge() }
                    }.opacity(pop ? 1 : 0)
                }
                if isHatch {
                    // Nommage EN LIGNE, dans la célébration
                    TextField("", text: $nameText, prompt: Text(model.t("Donne-lui un nom")).foregroundColor(.white.opacity(0.6)))
                        .font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .multilineTextAlignment(.center).focused($nameFocused).submitLabel(.done)
                        .padding(12).background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                        .frame(maxWidth: 240).opacity(pop ? 1 : 0)
                } else {
                    Text(subtitle).font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .opacity(pop ? 1 : 0)
                }
                Button(action: finish) {
                    Text(model.t(isHatch ? "Valider" : "Génial !")).font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.onAccent).frame(maxWidth: 240).padding(.vertical, 14)
                        .background(t.accentGradient, in: Capsule())
                }.opacity(pop ? 1 : 0).padding(.top, 4)
            }
            .padding(28)
        }
        .onAppear {
            if case .graduated = event { Haptics.heavy() } else { Haptics.success() }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { pop = true }
            withAnimation(.easeOut(duration: 0.9).delay(0.2)) { sparkle = true }
            if isHatch { DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { nameFocused = true } }   // ouvre le clavier
        }
    }

    private var spriteName: String? {
        switch event {
        case .hatched(let s): CreatureDB.creature(s)?.sprite
        case .evolved(_, let to): CreatureDB.creature(to)?.sprite
        case .graduated(let s, _): CreatureDB.creature(s)?.sprite
        case .leveledUp: nil
        }
    }
    private var creatureName: String? {
        switch event {
        case .hatched(let s): CreatureDB.creature(s)?.name
        case .evolved(_, let to): CreatureDB.creature(to)?.name
        case .graduated(let s, _): CreatureDB.creature(s)?.name
        case .leveledUp: nil
        }
    }
    private var isShiny: Bool {
        if case .graduated(_, let shiny) = event { return shiny }
        return model.companion?.isShiny ?? false
    }
    private var title: String {
        switch event {
        case .hatched: model.t("Éclosion ! 🐣")
        case .evolved: model.t("Évolution ! ✨")
        case .graduated: model.t("Diplômé·e ! 🎓")
        case .leveledUp: "\(model.t("Niv"))"
        }
    }
    private var subtitle: String {
        switch event {
        case .hatched: model.t("Une nouvelle créature rejoint ton aventure.")
        case .evolved: model.t("Ta créature a évolué grâce à ta régularité.")
        case .graduated: model.t("Elle rejoint ton dex. Un nouvel œuf t'attend !")
        case .leveledUp(let l): "\(model.t("Niv")) \(l)"
        }
    }
}
