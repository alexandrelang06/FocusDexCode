import SwiftUI

@main
struct FocusDexApp: App {
    @State private var model = AppModel()

    init() { Analytics.installCrashReporting() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(model.theme.accent)
                .preferredColorScheme(model.tone == .focus ? .dark : .light)
        }
    }
}

/// Décide entre onboarding et app principale ; crée le Store une fois.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var store: Store?
    @State private var splashDone = false

    var body: some View {
        ZStack {
            model.theme.bg.ignoresSafeArea()
            if let store, splashDone {
                if model.onboardingDone {
                    if model.proActive {
                        MainTabView(store: store)
                    } else {
                        // Essai ou abonnement expiré : re-blocage jusqu'au ré-abonnement.
                        PaywallView(store: store, hardMode: true, source: "re_block")
                    }
                } else {
                    OnboardingView(store: store)
                }
            }
            if !splashDone {
                SplashView().transition(.opacity)
            }
        }
        .task {
            if store == nil { store = Store(model: model) }
            Analytics.capture("app_opened", ["onboarded": model.onboardingDone])
            Analytics.setPerson(["plan": model.planTier])
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.easeInOut(duration: 0.45)) { splashDone = true }
        }
        .animation(.easeInOut(duration: 0.25), value: model.onboardingDone)
    }
}
