import SwiftUI
import UIKit

struct FocusView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @State private var minutes = 25
    @State private var ambient = false
    @State private var tickNow = Date()
    @State private var doneReward: RewardBox?
    @State private var showAbandonConfirm = false
    @FocusState private var minutesFocused: Bool
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let presets = [15, 25, 45, 60]

    // La session vit dans le modèle (persistante). On en dérive l'affichage.
    private var active: Bool { model.isFocusing }
    private var running: Bool { model.isFocusing && !model.isFocusPaused }
    private var paused: Bool { model.isFocusPaused }
    private var displayRemaining: Int { active ? model.focusRemaining(asOf: tickNow) : minutes * 60 }
    private var displayTotal: Int { active ? model.focusSessionMinutes * 60 : minutes * 60 }

    var body: some View {
        let t = model.theme
        NavigationStack {
            ZStack {
                t.bg.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text(paused ? model.t("En pause") : (running ? model.t("Reste concentré·e") : model.t("Prêt·e à te concentrer ?")))
                        .font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                        .padding(.top, 12)

                    timerRing

                    if active {
                        activeControls
                    } else {
                        durationPicker
                        customDuration
                        BigButton(title: model.t("Commencer"), icon: "play.fill") { start() }
                            .padding(.horizontal, 30)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
            }
            .navigationTitle(model.t("Focus")).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { ambient = true } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }
                }
            }
            .fullScreenCover(isPresented: $ambient) { ambientView }
            .onAppear {
                if !active { minutes = model.focusMinutesDefault }
                resolveIfDue()
                UIApplication.shared.isIdleTimerDisabled = running
            }
            .onReceive(ticker) { _ in tickNow = Date(); tick() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { resolveIfDue(); UIApplication.shared.isIdleTimerDisabled = running }
            }
            .sheet(item: $doneReward) { box in sessionDoneSheet(box) }
        }
    }

    private var activeControls: some View {
        let t = model.theme
        return VStack(spacing: 14) {
            Text(model.t("Ton chrono continue même si tu verrouilles ou changes d'app. Mets en pause pour t'arrêter."))
                .font(.system(size: 12.5, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
                .fixedSize(horizontal: false, vertical: true)
            BigButton(title: paused ? model.t("Reprendre") : model.t("Mettre en pause"),
                      icon: paused ? "play.fill" : "pause.fill") {
                paused ? resume() : pause()
            }
            .padding(.horizontal, 30)
            Button(role: .destructive) { showAbandonConfirm = true } label: {
                Text(model.t("Abandonner")).font(.system(size: 15, weight: .bold, design: .rounded))
            }
        }
        .confirmationDialog(model.t("Abandonner la session ?"), isPresented: $showAbandonConfirm, titleVisibility: .visible) {
            if !paused {
                Button(model.t("Mettre en pause plutôt")) { pause() }
            }
            Button(model.t("Abandonner"), role: .destructive) { abandon() }
            Button(model.t("Continuer la session"), role: .cancel) { }
        } message: {
            Text(model.t("Ton temps de focus sera perdu. Tu peux plutôt mettre en pause et reprendre plus tard."))
        }
    }

    private var timerRing: some View {
        let t = model.theme
        let frac = displayTotal > 0 ? Double(displayTotal - displayRemaining) / Double(displayTotal) : 0
        return ZStack {
            Circle().stroke(t.bg2, lineWidth: 16)
            Circle().trim(from: 0, to: frac)
                .stroke(t.accentGradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(paused ? 0.5 : 1)
            VStack(spacing: 10) {
                companion.frame(width: 120, height: 120)
                Text(timeString).font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                    .monospacedDigit()
            }
        }
        .frame(width: 280, height: 280)
        .animation(.linear(duration: 1), value: displayRemaining)
    }

    @ViewBuilder private var companion: some View {
        if let comp = model.companion {
            if comp.hatched, let c = model.companionCreature {
                CreatureImage(sprite: c.sprite, shiny: comp.isShiny)
            } else {
                EggView(progress: comp.hatchProgress, rarity: comp.rarity)
            }
        } else {
            Image(systemName: "leaf.fill").font(.system(size: 44)).foregroundStyle(model.theme.positive)
        }
    }

    private var durationPicker: some View {
        let t = model.theme
        return HStack(spacing: 10) {
            ForEach(presets, id: \.self) { m in
                let sel = minutes == m
                Button { minutes = m } label: {
                    Text("\(m) min").font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(sel ? t.onAccent : t.text)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(sel ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.bg2), in: Capsule())
                }
            }
        }
    }

    // Mode tente / ambiant : compagnon en grand + gros compte à rebours, UI minimale.
    private var ambientView: some View {
        let display = active ? timeString : String(format: "%02d:00", minutes)
        return ZStack {
            model.currentHabitat.gradient.ignoresSafeArea()
            Color.black.opacity(0.10).ignoresSafeArea()
            VStack(spacing: 26) {
                HStack {
                    Spacer()
                    Button { ambient = false } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                            .padding(12).background(.black.opacity(0.18), in: Circle())
                    }
                }
                Spacer()
                companion
                    .frame(width: 220, height: 220)
                    .phaseAnimator([false, true]) { content, up in
                        content.scaleEffect(up ? 1.03 : 1.0, anchor: .bottom).offset(y: up ? -7 : 0)
                    } animation: { _ in .easeInOut(duration: 1.9) }
                Text(display)
                    .font(.system(size: 88, weight: .heavy, design: .rounded)).monospacedDigit()
                    .foregroundStyle(.white).shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                    .opacity(paused ? 0.6 : 1)
                if active {
                    Button { paused ? resume() : pause() } label: {
                        Label(paused ? model.t("Reprendre") : model.t("Mettre en pause"),
                              systemImage: paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                            .padding(.horizontal, 22).padding(.vertical, 12)
                            .background(.white.opacity(0.18), in: Capsule())
                    }
                } else {
                    BigButton(title: model.t("Commencer"), icon: "play.fill") { start() }
                        .padding(.horizontal, 60)
                }
                Spacer()
                Text(paused ? model.t("En pause") : (active ? model.t("Reste concentré·e") : model.t("Mode tente : pose ton iPhone et concentre-toi.")))
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24).padding(.top, 12)
        }
        .persistentSystemOverlays(.hidden)
    }

    private var customDuration: some View {
        let t = model.theme
        return VStack(spacing: 8) {
            Text(model.t("Personnalisé")).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(t.sub)
            // Stepper centré (touche le nombre pour l'écrire) — sur une seule ligne stable.
            HStack(spacing: 14) {
                Button { minutes = max(5, minutes - 5); Haptics.light() } label: {
                    Image(systemName: "minus").font(.system(size: 15, weight: .bold)).foregroundStyle(t.accent)
                        .frame(width: 40, height: 40).background(t.bg2, in: Circle())
                }
                HStack(spacing: 4) {
                    TextField("", value: $minutes, format: .number)
                        .font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                        .keyboardType(.numberPad).multilineTextAlignment(.center)
                        .frame(width: 50).monospacedDigit().focused($minutesFocused)
                    Text(model.t("min")).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(t.sub)
                }
                .padding(.vertical, 8).padding(.horizontal, 12).background(t.bg2, in: RoundedRectangle(cornerRadius: 12))
                Button { minutes = min(120, minutes + 5); Haptics.light() } label: {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold)).foregroundStyle(t.accent)
                        .frame(width: 40, height: 40).background(t.bg2, in: Circle())
                }
            }
        }
        .padding(.horizontal, 30)
        .onChange(of: minutesFocused) { _, focused in
            if !focused { minutes = min(120, max(5, minutes)) }   // clamp à la fin de la saisie
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(model.t("OK")) { minutesFocused = false }
            }
        }
    }

    private func sessionDoneSheet(_ box: RewardBox) -> some View {
        let t = model.theme
        return VStack(spacing: 18) {
            Text(model.t("Session terminée ! 🎉")).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            HStack(spacing: 24) {
                reward(icon: "bolt.fill", value: "+\(box.xp)", label: model.t("XP"), tint: t.accent)
                reward(icon: "circle.hexagongrid.fill", value: "+\(box.candy)", label: model.t("bonbons"), tint: t.coin)
            }
            Text(model.t("Ta régularité fait grandir ta créature."))
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
            BigButton(title: model.t("Continuer")) { doneReward = nil }.padding(.horizontal, 24)
        }
        .padding(28).presentationDetents([.height(320)])
        .background(t.bg)
    }
    private func reward(icon: String, value: String, label: String, tint: Color) -> some View {
        let t = model.theme
        return VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(tint)
            Text(value).font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(label).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
        }
    }

    private var timeString: String {
        let r = displayRemaining
        return String(format: "%02d:%02d", r / 60, r % 60)
    }

    // MARK: Actions

    private func start() {
        model.startFocus(minutes: minutes); Haptics.light()
        UIApplication.shared.isIdleTimerDisabled = true
        startLive()
    }
    private func pause() {
        model.pauseFocus(); Haptics.light()
        UIApplication.shared.isIdleTimerDisabled = false
        FocusLive.end()
    }
    private func resume() {
        model.resumeFocus(); Haptics.light()
        UIApplication.shared.isIdleTimerDisabled = true
        startLive()
    }
    private func abandon() {
        model.cancelFocus(); Haptics.warning()
        UIApplication.shared.isIdleTimerDisabled = false
        FocusLive.end()
    }
    private func tick() {
        guard running else { return }
        if displayRemaining <= 0 { complete() }
    }
    private func complete() {
        guard let r = model.finishFocusIfDue() else { return }
        doneReward = RewardBox(candy: r.candy, xp: r.xp); Haptics.success()
        UIApplication.shared.isIdleTimerDisabled = false
        FocusLive.end()
    }
    /// Valide une session arrivée à terme pendant l'absence, et affiche la récompense.
    private func resolveIfDue() {
        if let r = model.finishFocusIfDue() { doneReward = RewardBox(candy: r.candy, xp: r.xp); FocusLive.end() }
    }
    private func startLive() {
        guard let end = model.focusEndDate else { return }
        let name = (model.companion?.hatched == true) ? model.companionDisplayName : "FocusDex"
        FocusLive.start(companionName: name, minutes: model.focusSessionMinutes,
                        startAt: end.addingTimeInterval(-Double(model.focusSessionMinutes * 60)), endAt: end)
    }
}

private struct RewardBox: Identifiable, Equatable { let id = UUID(); let candy: Int; let xp: Int }
