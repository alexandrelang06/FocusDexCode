import SwiftUI

struct MainTabView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    let store: Store
    @State private var tab = 0
    @State private var celebration: CompanionEvent?
    @State private var showPaywall = false
    @State private var showNaming = false
    @State private var showHatch = false
    @AppStorage("focusdex.paywallSeen") private var paywallSeen = false

    var body: some View {
        TabView(selection: $tab) {
            HomeView(store: store, goFocus: { tab = 1 }, goShop: { tab = 4 },
                     goPaywall: { showPaywall = true }, goHatch: { showHatch = true })
                .tabItem { Label(model.t("Accueil"), systemImage: "house.fill") }.tag(0)
            FocusView().tabItem { Label(model.t("Focus"), systemImage: "timer") }.tag(1)
            HabitsView().tabItem { Label(model.t("Habitudes"), systemImage: "checklist") }.tag(2)
            DexView().tabItem { Label(model.t("Dex"), systemImage: "square.grid.2x2.fill") }.tag(3)
            ShopView(store: store).tabItem { Label(model.t("Boutique"), systemImage: "bag.fill") }.tag(4)
        }
        .tint(model.theme.accent)
        .overlay {
            if let ev = celebration {
                CelebrationView(event: ev) { advanceCelebration() }
                    .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) { PaywallView(store: store, source: "app") }
        .sheet(isPresented: $showNaming) { NamingSheet() }
        .sheet(isPresented: $showHatch) { HatchEggView() }
        .onChange(of: model.pendingEvents.count) { _, _ in if celebration == nil { advanceCelebration() } }
        .onChange(of: model.namingRequested) { _, _ in maybeName() }
        .onChange(of: model.hasPendingEgg) { _, has in if has { maybePresentHatch() } }
        .onChange(of: scenePhase) { _, phase in
            // Session terminée pendant l'absence : on crédite même hors de l'onglet Focus.
            // Sur l'onglet Focus, on laisse FocusView résoudre (il affiche la récompense).
            if phase == .active { handleWidgetFocusStart(); if tab != 1 { model.finishFocusIfDue() } }
        }
        .onAppear {
            if celebration == nil { advanceCelebration() }; maybeName()
            handleWidgetFocusStart()
            if tab != 1 { model.finishFocusIfDue() }
        }
    }

    /// Démarre un focus demandé depuis le widget (via l'App Group), puis va sur l'onglet Focus.
    private func handleWidgetFocusStart() {
        guard let d = FocusDexShared.defaults else { return }
        let mins = d.integer(forKey: FocusDexShared.startFocusKey)
        guard mins > 0 else { return }
        d.set(0, forKey: FocusDexShared.startFocusKey)
        if !model.isFocusing {
            model.startFocus(minutes: mins)
            if let end = model.focusEndDate {
                let name = (model.companion?.hatched == true) ? model.companionDisplayName : "FocusDex"
                FocusLive.start(companionName: name, minutes: mins,
                                startAt: end.addingTimeInterval(-Double(mins * 60)), endAt: end)
            }
        }
        tab = 1
    }

    /// Présente le nommage quand une créature vient d'arriver et qu'aucune célébration n'est en cours.
    private func maybeName() {
        if model.namingRequested && celebration == nil && !showPaywall { showNaming = true }
    }

    /// Ouvre automatiquement l'écran d'éclosion dès qu'un œuf en attente existe (diplôme, achat boutique…).
    private func maybePresentHatch() {
        if model.hasPendingEgg && celebration == nil && !showPaywall && !showNaming && !showHatch {
            showHatch = true
        }
    }

    /// Affiche le prochain événement « célébrable » ; déclenche le paywall après le 1ᵉʳ diplôme.
    private func advanceCelebration() {
        // retire les événements non visuels (level up simple) sauf s'ils sont seuls
        while let first = model.pendingEvents.first {
            model.pendingEvents.removeFirst()
            switch first {
            case .hatched, .evolved, .graduated:
                withAnimation { celebration = first }
                if case .graduated = first, !model.proActive, !paywallSeen {
                    paywallSeen = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { showPaywall = true }
                }
                return
            case .leveledUp:
                continue
            }
        }
        withAnimation { celebration = nil }
        maybeName()
        maybePresentHatch()
    }
}
