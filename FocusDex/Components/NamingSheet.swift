import SwiftUI

/// Proposé à l'arrivée d'une créature (éclosion ou starter) pour lui donner un surnom.
struct NamingSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        let t = model.theme
        let c = model.companionCreature
        let shiny = model.companion?.isShiny ?? false
        NavigationStack {
            VStack(spacing: 18) {
                Spacer(minLength: 8)
                ZStack {
                    Circle().fill(t.accent.opacity(0.12)).frame(width: 190, height: 190)
                    if let c { CreatureImage(sprite: c.sprite, shiny: shiny).frame(width: 150, height: 150) }
                }
                VStack(spacing: 6) {
                    Text(model.t("Une nouvelle créature est arrivée !"))
                        .font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(String(format: model.t("Un·e %@ rejoint ton refuge. Donne-lui un petit nom."), c?.name ?? ""))
                        .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                TextField(c?.name ?? "", text: $name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .focused($focused)
                    .submitLabel(.done)
                    .padding(14).background(t.bg2, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 8)
                BigButton(title: model.t("Valider le nom"), enabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    model.nameCompanion(name); dismiss()
                }
                Button { model.nameCompanion(c?.name ?? ""); dismiss() } label: {
                    Text(model.t("Garder le nom d'origine"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(t.sub)
                }
                Spacer(minLength: 8)
            }
            .padding(20)
            .background(t.bg.ignoresSafeArea())
            .interactiveDismissDisabled(true)
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true } }
    }
}

/// Petit popup dédié pour renommer une créature (surnom par espèce). Réutilisé par le dex et l'accueil.
struct RenameSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let creature: Creature
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        let t = model.theme
        let empty = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        NavigationStack {
            VStack(spacing: 16) {
                Spacer(minLength: 6)
                CreatureImage(sprite: creature.sprite, shiny: model.isShiny(creature.id)).frame(width: 110, height: 110)
                Text(model.t("Choisis un surnom")).font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                TextField(creature.name, text: $name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                    .focused($focused).submitLabel(.done).onSubmit { if !empty { save() } }
                    .padding(14).background(t.bg2, in: RoundedRectangle(cornerRadius: 14)).padding(.horizontal, 8)
                BigButton(title: model.t("Enregistrer"), enabled: !empty) { save() }
                Button { model.setNickname("", forFamily: creature.family); dismiss() } label: {
                    Text(model.t("Nom d'origine")).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(t.sub)
                }
                Spacer(minLength: 6)
            }
            .padding(20).background(t.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(model.t("Annuler")) { dismiss() } } }
            .presentationDetents([.height(360)])
        }
        .onAppear {
            name = model.nickname(forFamily: creature.family) ?? ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { focused = true }
        }
    }
    private func save() { model.setNickname(name, forFamily: creature.family); dismiss() }
}
