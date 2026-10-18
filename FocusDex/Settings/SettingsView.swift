import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let store: Store
    @State private var showPaywall = false
    @State private var confirmReset = false

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            List {
                Section(model.t("Profil")) {
                    NavigationLink { AccountView(store: store) } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.fill").font(.system(size: 26)).foregroundStyle(model.theme.accent)
                            VStack(alignment: .leading) {
                                Text(model.displayName.isEmpty ? model.t("Invité") : model.displayName).font(.headline)
                                Text(model.signedIn ? model.t("Compte connecté") : model.t("Non connecté")).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section(model.t("Langue")) {
                    NavigationLink { LanguagePickerView() } label: {
                        HStack {
                            Label(model.t("Langue"), systemImage: "globe")
                            Spacer()
                            Text("\(model.language.flag) \(model.language.name)").foregroundStyle(.secondary)
                        }
                    }
                }

                Section(model.t("Ambiance")) {
                    Picker(model.t("Ton"), selection: $model.tone) {
                        ForEach(Tone.allCases) { Text("\($0.emoji) \(model.toneTitle($0))").tag($0) }
                    }
                    Stepper("\(model.t("Focus par défaut")) : \(model.focusMinutesDefault) min",
                            value: $model.focusMinutesDefault, in: 5...90, step: 5)
                    NavigationLink { HabitatPickerView() } label: {
                        HStack { Text(model.t("Habitat")); Spacer(); Text(model.t(model.currentHabitat.name)).foregroundStyle(.secondary) }
                    }
                    NavigationLink { AppIconPickerView() } label: {
                        HStack {
                            Text(model.t("Icône de l'app")); Spacer()
                            Text(appIconName).foregroundStyle(.secondary)
                        }
                    }
                }

                Section(model.t("Abonnement")) {
                    if model.proActive {
                        HStack {
                            Label(model.inTrial ? model.t("Essai gratuit") : model.t("Pro actif"), systemImage: "crown.fill")
                                .foregroundStyle(model.theme.coin)
                            if let d = model.trialDaysLeft {
                                Spacer()
                                Text(d == 1 ? model.t("1 jour restant") : String(format: model.t("%d jours restants"), d))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Button { showPaywall = true } label: { Label(model.t("Passer en Pro"), systemImage: "crown.fill") }
                    }
                    Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                        Label(model.t("Gérer mon abonnement"), systemImage: "gearshape")
                    }
                    Button { Task { await store.restore() } } label: { Text(model.t("Restaurer mes achats")) }
                }

                Section(model.t("À propos")) {
                    NavigationLink { CreditsView() } label: { Label(model.t("Crédits & licences"), systemImage: "info.circle") }
                    HStack { Text(model.t("Version")); Spacer(); Text("1.0").foregroundStyle(.secondary) }
                }

                Section {
                    Button(role: .destructive) { confirmReset = true } label: { Text(model.t("Réinitialiser la progression")) }
                }
            }
            .navigationTitle(model.t("Réglages"))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } } }
            .sheet(isPresented: $showPaywall) { PaywallView(store: store, source: "settings") }
            .alert(model.t("Tout réinitialiser ?"), isPresented: $confirmReset) {
                Button(model.t("Annuler"), role: .cancel) {}
                Button(model.t("Réinitialiser"), role: .destructive) { model.resetProgress(); dismiss() }
            } message: { Text(model.t("Ton dex et ta progression seront effacés. Action irréversible.")) }
        }
    }

    private var appIconName: String {
        guard let slug = model.appIconSlug, let c = CreatureDB.creature(slug) else { return model.t("Défaut") }
        return c.name
    }
}

/// Sélecteur d'icône d'app : la créature affichée sur l'écran d'accueil, choisie parmi celles possédées.
struct AppIconPickerView: View {
    @Environment(AppModel.self) private var model

    private var owned: [Creature] {
        CreatureDB.all.filter { model.dexSpecies.contains($0.id) }
    }
    private let cols = [GridItem(.adaptive(minimum: 92), spacing: 12)]

    var body: some View {
        let t = model.theme
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(model.t("Choisis la créature affichée sur ton écran d'accueil."))
                    .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                Text(model.t("iOS te demandera de confirmer le changement."))
                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub.opacity(0.8))

                LazyVGrid(columns: cols, spacing: 12) {
                    tile(slug: nil, creature: CreatureDB.creature("cairfrey"), label: model.t("Défaut"))
                    ForEach(owned, id: \.id) { c in
                        tile(slug: c.id, creature: c, label: c.name)
                    }
                }

                if owned.isEmpty {
                    Text(model.t("Attrape des créatures pour débloquer plus d'icônes."))
                        .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, 8)
                }
            }
            .padding(18)
        }
        .background(t.bg.ignoresSafeArea())
        .navigationTitle(model.t("Icône de l'app"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tile(slug: String?, creature: Creature?, label: String) -> some View {
        let t = model.theme
        let selected = model.appIconSlug == slug
        return Button { model.setAppIcon(slug) } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: [.hex(0xFFD9CB), .hex(0xFF9E8E)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 76, height: 76)
                    if let c = creature { CreatureImage(sprite: c.sprite).frame(width: 58, height: 58) }
                }
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? t.accent : .clear, lineWidth: 3))
                .overlay(alignment: .topTrailing) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 20))
                            .foregroundStyle(t.accent).background(Circle().fill(.white)).offset(x: 6, y: -6)
                    }
                }
                Text(label).font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(t.text).lineLimit(1)
            }
        }
    }
}

struct LanguagePickerView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let t = model.theme
        List {
            ForEach(AppLanguage.allCases) { l in
                Button { model.language = l } label: {
                    HStack(spacing: 12) {
                        Text(l.flag).font(.system(size: 24))
                        Text(l.name).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(t.text)
                        Spacer()
                        if model.language == l { Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(t.accent) }
                    }
                }
            }
        }
        .navigationTitle(model.t("Langue"))
    }
}

struct HabitatPickerView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        List {
            ForEach(Habitat.all) { h in
                Button { model.equipHabitat(h) } label: {
                    HStack {
                        RoundedRectangle(cornerRadius: 8).fill(h.gradient).frame(width: 48, height: 32)
                        Text(model.t(h.name))
                        Spacer()
                        if model.equippedHabitat == h.id { Image(systemName: "checkmark").foregroundStyle(model.theme.accent) }
                        else if !model.habitatUnlocked(h) { Image(systemName: "lock.fill").foregroundStyle(.secondary) }
                    }
                }.disabled(!model.habitatUnlocked(h))
            }
        }.navigationTitle(model.t("Habitat"))
    }
}

struct AccountView: View {
    @Environment(AppModel.self) private var model
    let store: Store
    var body: some View {
        let t = model.theme
        List {
            Section {
                HStack {
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 44)).foregroundStyle(t.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.displayName.isEmpty ? model.t("Invité") : model.displayName).font(.title3.bold())
                        Text(model.signedIn ? model.t("Connecté avec Apple") : model.t("Mode invité")).font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 6)
            }
            Section(model.t("Préférences")) {
                NavigationLink { LanguagePickerView() } label: {
                    HStack {
                        Label(model.t("Langue"), systemImage: "globe")
                        Spacer()
                        Text("\(model.language.flag) \(model.language.name)").foregroundStyle(.secondary)
                    }
                }
            }
            Section(model.t("Statistiques")) {
                stat(model.t("Minutes de focus"), "\(model.totalFocusMinutes)")
                stat(model.t("Sessions"), "\(model.sessionsCompleted)")
                stat(model.t("Série actuelle"), "\(model.currentStreak) \(model.t("j"))")
                stat(model.t("Créatures"), "\(model.dexCount)/\(model.dexTotal)")
                stat(model.t("Shiny"), "\(model.shinySpecies.count)")
            }
            Section(model.t("Abonnement")) {
                HStack { Text(model.t("Plan")); Spacer(); Text(model.proActive ? model.t("Pro") : model.t("Gratuit")).foregroundStyle(.secondary) }
                Button { Task { await store.restore() } } label: { Text(model.t("Restaurer mes achats")) }
            }
            Section {
                if model.signedIn {
                    Button(role: .destructive) { model.signOut() } label: { Text(model.t("Se déconnecter")) }
                }
            }
        }
        .navigationTitle(model.t("Compte"))
    }
    private func stat(_ k: String, _ v: String) -> some View {
        HStack { Text(k); Spacer(); Text(v).foregroundStyle(.secondary) }
    }
}

struct CreditsView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        List {
            Section(model.t("Créatures")) {
                Text(model.t("Les créatures, sprites et données d'évolution proviennent du projet open source **Tuxemon**, sous licence **CC-BY-SA 4.0**."))
                Link("Projet Tuxemon", destination: URL(string: "https://www.tuxemon.org")!)
                Link("Licence CC-BY-SA 4.0", destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!)
            }
            Section(model.t("À propos")) {
                Text(model.t("FocusDex. Concentre-toi, prends soin de toi, collectionne. Fait avec 💜."))
            }
        }
        .navigationTitle(model.t("Crédits"))
    }
}
