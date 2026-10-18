import SwiftUI

struct HabitsView: View {
    @Environment(AppModel.self) private var model
    @State private var editing: Habit?      // habitude en cours d'édition
    @State private var showAdd = false

    var body: some View {
        let t = model.theme
        NavigationStack {
            List {
                clearRow { header }
                Section {
                    ForEach(model.habits) { habit in
                        clearRow { habitRow(habit) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { model.deleteHabit(habit.id) } label: {
                                    Label(model.t("Supprimer"), systemImage: "trash")
                                }
                                Button { editing = habit } label: { Label(model.t("Modifier"), systemImage: "pencil") }.tint(t.accent)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if habit.isActive(weekday: AppModel.weekday()) && !habit.isDone(today: AppModel.today()) {
                                    Button { Haptics.light(); model.completeHabit(habit.id) } label: {
                                        Label(model.t("Fait"), systemImage: "checkmark")
                                    }.tint(t.positive)
                                }
                            }
                    }
                }
                clearRow { addButton }
                clearRow { note }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(t.bg.ignoresSafeArea())
            .navigationTitle(model.t("Habitudes"))
            .sheet(isPresented: $showAdd) { HabitEditView(habit: nil) }
            .sheet(item: $editing) { h in HabitEditView(habit: h) }
        }
    }

    // Ligne de List sans fond/séparateur, pour garder le style carte.
    private func clearRow<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    private var addButton: some View {
        let t = model.theme
        return Button { showAdd = true } label: {
            Label(model.t("Ajouter une habitude"), systemImage: "plus")
                .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(t.accent)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(t.bg2, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        let t = model.theme
        let done = model.habitsDoneToday
        let total = model.habitsToday.count
        return SectionCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.t("Aujourd'hui")).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                    Text("\(done)/\(total) \(model.t("faites"))")
                        .font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                }
                Spacer()
                Button {
                    Haptics.light(); model.completeAllHabitsToday()
                } label: {
                    ZStack {
                        Circle().stroke(t.bg2, lineWidth: 8).frame(width: 56, height: 56)
                        Circle().trim(from: 0, to: total == 0 ? 0 : Double(done)/Double(total))
                            .stroke(t.positive, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90)).frame(width: 56, height: 56)
                        Image(systemName: done >= total && total > 0 ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 16, weight: .bold)).foregroundStyle(t.positive)
                    }
                }
                .buttonStyle(.plain)
                .disabled(total == 0 || done >= total)
            }
        }
    }

    private func habitRow(_ habit: Habit) -> some View {
        let t = model.theme
        let today = habit.isActive(weekday: AppModel.weekday())
        let done = habit.isDone(today: AppModel.today())
        return HStack(spacing: 14) {
            Button { editing = habit } label: {
                HStack(spacing: 14) {
                    Image(systemName: habit.icon).font(.system(size: 18)).foregroundStyle(done ? t.positive : t.accent).frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(t.text)
                        HStack(spacing: 8) {
                            Text(frequencyLabel(habit)).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(t.sub)
                            if habit.streak > 0 {
                                Label("\(habit.streak) \(model.t("j"))", systemImage: "flame.fill")
                                    .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(t.danger)
                            }
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if today {
                Button { if !done { Haptics.light() }; model.completeHabit(habit.id) } label: {
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28)).foregroundStyle(done ? t.positive : t.sub.opacity(0.5))
                }
                .buttonStyle(.plain)
                .disabled(done)
            } else {
                Text(model.t("Pas aujourd'hui")).font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(t.sub.opacity(0.7))
            }
        }
        .padding(14).background(t.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(done ? t.positive.opacity(0.4) : .clear, lineWidth: 1.5))
        .opacity(today ? 1 : 0.6)
        .contextMenu {
            Button { editing = habit } label: { Label(model.t("Modifier"), systemImage: "pencil") }
            Button(role: .destructive) { model.deleteHabit(habit.id) } label: { Label(model.t("Supprimer"), systemImage: "trash") }
        }
    }

    private func frequencyLabel(_ h: Habit) -> String {
        if h.isDaily { return model.t("Tous les jours") }
        return h.days.sorted(by: weekOrder).map { HabitEditView.dayLabel($0, model) }.joined(separator: " ")
    }
    // Lun→Dim pour l'affichage
    private func weekOrder(_ a: Int, _ b: Int) -> Bool { (a == 1 ? 8 : a) < (b == 1 ? 8 : b) }

    private var note: some View {
        Text(model.t("Chaque habitude cochée nourrit ta créature (+8 XP, +3 bonbons)."))
            .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(model.theme.sub)
            .multilineTextAlignment(.center).padding(.top, 6)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Création OU édition d'une habitude (nom, icône, fréquence).
struct HabitEditView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let habit: Habit?          // nil = création
    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var everyDay = true
    @State private var days: Set<Int> = []
    let icons = ["star.fill","drop.fill","figure.walk","book.fill","dumbbell.fill","leaf.fill","cup.and.saucer.fill","bed.double.fill","pencil","heart.fill","brain.head.profile","fork.knife"]
    private let weekChips = [2,3,4,5,6,7,1]   // Lun..Dim

    static func dayLabel(_ w: Int, _ model: AppModel) -> String {
        let keys = [1: "Dim", 2: "Lun", 3: "Mar", 4: "Mer", 5: "Jeu", 6: "Ven", 7: "Sam"]
        return model.t(keys[w] ?? "")
    }

    var body: some View {
        let t = model.theme
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField(model.t("Nom de l'habitude"), text: $name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .padding(14).background(t.bg2, in: RoundedRectangle(cornerRadius: 14))

                    Text(model.t("Icône")).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.sub)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { ic in
                            Button { icon = ic } label: {
                                Image(systemName: ic).font(.system(size: 18))
                                    .foregroundStyle(icon == ic ? t.onAccent : t.text)
                                    .frame(width: 46, height: 46)
                                    .background(icon == ic ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.bg2), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    Text(model.t("Fréquence")).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(t.sub)
                    Toggle(isOn: $everyDay) {
                        Text(model.t("Tous les jours")).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(t.text)
                    }
                    .tint(t.accent)
                    .padding(14).background(t.card, in: RoundedRectangle(cornerRadius: 14))
                    if !everyDay {
                        HStack(spacing: 8) {
                            ForEach(weekChips, id: \.self) { w in
                                let on = days.contains(w)
                                Button {
                                    if on { days.remove(w) } else { days.insert(w) }
                                } label: {
                                    Text(Self.dayLabel(w, model))
                                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                                        .foregroundStyle(on ? t.onAccent : t.sub)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(on ? AnyShapeStyle(t.accentGradient) : AnyShapeStyle(t.bg2), in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }

                    BigButton(title: model.t(habit == nil ? "Ajouter" : "Enregistrer"), enabled: canSave) { save() }
                        .padding(.top, 4)
                    Spacer()
                }
                .padding(18)
            }
            .background(t.bg.ignoresSafeArea())
            .navigationTitle(model.t(habit == nil ? "Nouvelle habitude" : "Modifier l'habitude")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(model.t("Annuler")) { dismiss() } } }
        }
        .onAppear {
            if let h = habit {
                name = h.name; icon = h.icon
                everyDay = h.isDaily
                days = h.isDaily ? [] : h.days
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (everyDay || !days.isEmpty)
    }
    private func save() {
        let d = everyDay ? [] : days
        if let h = habit { model.updateHabit(h.id, name: name, icon: icon, days: d) }
        else { model.addHabit(name: name, icon: icon, days: d) }
        Haptics.light(); dismiss()
    }
}
