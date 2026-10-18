import SwiftUI

struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let store: Store
    var hardMode: Bool = false          // fin d'onboarding : pas de sortie gratuite
    var source: String = "onboarding"
    @State private var plan = Store.proYearly
    @State private var busy = false

    private let benefits: [(String, String)] = [
        ("sparkles", "Chances de shiny ×2"),
        ("mountain.2.fill", "Habitats exclusifs (Néon, Espace…)"),
        ("paintpalette.fill", "Thèmes premium & personnalisation"),
        ("heart.fill", "Soutiens un studio indépendant 💜"),
    ]

    private var heroCreature: Creature? {
        model.companionCreature ?? CreatureDB.creature("cairfrey") ?? CreatureDB.bases.first
    }

    var body: some View {
        let t = model.theme
        ZStack {
            LinearGradient(colors: [t.accent.opacity(0.20), t.bg], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    closeRow
                    hero
                    plans
                    cta
                    benefitsList
                    trialTimeline
                    socialProof
                    legal
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
            .background(t.bg.ignoresSafeArea())
        }
        .onAppear { Analytics.capture("paywall_viewed", ["source": source, "hard": hardMode]) }
    }

    private var closeRow: some View {
        HStack {
            if !hardMode {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                        .foregroundStyle(model.theme.sub.opacity(0.7)).padding(9).background(model.theme.bg2, in: Circle())
                }
            }
            Spacer()
            Button { Task { busy = true; await store.restore(); busy = false; if model.proActive { dismiss() } } } label: {
                Text(model.t("Restaurer mes achats")).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(model.theme.sub)
            }
        }.padding(.top, 8)
    }

    private var hero: some View {
        let t = model.theme
        return VStack(spacing: 10) {
            ZStack {
                Circle().fill(t.accent.opacity(0.14)).frame(width: 150, height: 150)
                if let c = heroCreature {
                    CreatureImage(sprite: c.sprite).frame(width: 120, height: 120)
                }
                Image(systemName: "crown.fill").font(.system(size: 26)).foregroundStyle(t.coin)
                    .offset(y: -78)
            }
            Text(model.t("FocusDex Pro")).font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            Text(model.t("Investis sur toi-même.")).font(.system(size: 19, weight: .heavy, design: .rounded)).foregroundStyle(t.accent)
            Text(model.t("Ta concentration et tes habitudes, récompensées chaque jour."))
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var benefitsList: some View {
        let t = model.theme
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(benefits, id: \.0) { b in
                HStack(spacing: 12) {
                    Image(systemName: b.0).font(.system(size: 16, weight: .bold)).foregroundStyle(t.accent).frame(width: 24)
                    Text(model.t(b.1)).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(t.text)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(t.card, in: RoundedRectangle(cornerRadius: 18))
    }

    // Timeline d'essai gratuit — rassure et augmente la conversion (best practice Superwall).
    private var trialTimeline: some View {
        let t = model.theme
        return VStack(alignment: .leading, spacing: 0) {
            Text(model.t("Comment marche ton essai gratuit"))
                .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                .padding(.bottom, 14)
            timelineRow(icon: "lock.open.fill", color: t.accent, title: model.t("Aujourd'hui"),
                        sub: model.t("Débloque tout : shiny ×2, habitats exclusifs, thèmes premium."), line: true)
            timelineRow(icon: "bell.fill", color: t.coin, title: model.t("Jour 5"),
                        sub: model.t("On te prévient : ton essai gratuit se termine bientôt."), line: true)
            timelineRow(icon: "crown.fill", color: t.positive, title: model.t("Jour 7"),
                        sub: model.t("Ton abonnement démarre. Annulable avant, sans aucun frais."), line: false)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(t.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private func timelineRow(icon: String, color: Color, title: String, sub: String, line: Bool) -> some View {
        let t = model.theme
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Image(systemName: icon).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 32, height: 32).background(color, in: Circle())
                if line {
                    Rectangle().fill(color.opacity(0.35)).frame(width: 3, height: 34)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                Text(sub).font(.system(size: 12.5, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
            }
            .padding(.bottom, line ? 12 : 0)
            Spacer(minLength: 0)
        }
    }

    private var socialProof: some View {
        let t = model.theme
        return VStack(spacing: 6) {
            HStack(spacing: 3) { ForEach(0..<5, id: \.self) { _ in Image(systemName: "star.fill").font(.system(size: 13)).foregroundStyle(t.coin) } }
            Text(model.t("« Depuis FocusDex, je tiens mes sessions et j'adore compléter mon dex. »"))
                .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                .multilineTextAlignment(.center).italic()
                .fixedSize(horizontal: false, vertical: true)
        }.padding(.vertical, 4)
    }

    private var plans: some View {
        VStack(spacing: 10) {
            planCard(id: Store.proYearly, title: model.t("Annuel"), price: store.priceLabel(Store.proYearly, fallback: "19,99 €/an"),
                     sub: store.perMonthLabel(Store.proYearly) ?? model.t("Le plus avantageux"), badge: model.t("POPULAIRE · 7 jours offerts"))
            planCard(id: Store.proMonthly, title: model.t("Mensuel"), price: store.priceLabel(Store.proMonthly, fallback: "3,99 €/mois"),
                     sub: model.t("Sans engagement"), badge: nil)
            planCard(id: Store.proLifetime, title: model.t("À vie"), price: store.priceLabel(Store.proLifetime, fallback: "39,99 €"),
                     sub: model.t("Paiement unique, pour toujours"), badge: nil)
        }
    }

    private func planCard(id: String, title: String, price: String, sub: String, badge: String?) -> some View {
        let t = model.theme
        let selected = plan == id
        return Button { plan = id; Analytics.capture("plan_selected", ["plan": id]) } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22)).foregroundStyle(selected ? t.accent : t.sub.opacity(0.5))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                        if let badge {
                            Text(badge).font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundStyle(t.onAccent)
                                .padding(.horizontal, 7).padding(.vertical, 3).background(t.accentGradient, in: Capsule())
                        }
                    }
                    Text(sub).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                }
                Spacer()
                Text(price).font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
            }
            .padding(14)
            .background(t.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? t.accent : t.sub.opacity(0.12), lineWidth: selected ? 2 : 1))
        }
    }

    private var cta: some View {
        let t = model.theme
        return VStack(spacing: 10) {
            BigButton(title: model.t("J'investis sur moi"), enabled: !busy) { startPurchase(plan) }
            // Lien cliquable : sélectionne l'annuel et lance l'essai gratuit de 7 jours.
            Button { plan = Store.proYearly; startPurchase(Store.proYearly) } label: {
                Text(model.t("Ou profite d'un essai gratuit de 7 jours en cliquant ici"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(t.accent).underline()
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .disabled(busy)
        }
    }

    /// Achète le produit, et si c'est l'annuel (avec essai) non encore utilisé, démarre le suivi d'essai + rappels.
    private func startPurchase(_ id: String) {
        Analytics.capture("checkout_started", ["plan": id, "source": source])
        Task {
            busy = true
            let ok = await store.purchase(id)
            if ok { Analytics.capture("purchase_completed", ["plan": id]) }
            if ok, id == Store.proYearly, !model.trialUsed {
                model.beginTrial(days: 7)
                Notifications.scheduleTrialReminders(
                    trialEnd: Date(timeIntervalSince1970: model.trialEndTS),
                    title5: model.t("Ton essai se termine dans 2 jours ⏳"),
                    body5: model.t("Garde tes bonus Pro : shiny ×2, habitats exclusifs, thèmes premium."),
                    title7: model.t("Dernier jour d'essai gratuit"),
                    body7: model.t("Ton abonnement démarre aujourd'hui. Gère-le quand tu veux dans les réglages."))
            }
            busy = false
            if ok { dismiss() }
        }
    }

    // URLs légales : EULA standard d'Apple + page de confidentialité (GitHub Pages, dans la langue de l'app).
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private var privacyURL: URL {
        URL(string: "https://alexandrelang06.github.io/FocusDex/privacy.html?lang=\(model.language.rawValue)")
            ?? URL(string: "https://alexandrelang06.github.io/FocusDex/privacy.html")!
    }

    private var legal: some View {
        let t = model.theme
        return VStack(spacing: 6) {
            Text(model.t("Abonnement renouvelé automatiquement. Résiliable à tout moment."))
                .font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(t.sub.opacity(0.7))
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Link(model.t("Conditions d'utilisation"), destination: Self.termsURL)
                Text("·").foregroundStyle(t.sub.opacity(0.5))
                Link(model.t("Confidentialité"), destination: privacyURL)
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(t.accent)
        }
        .padding(.top, 4)
    }
}
