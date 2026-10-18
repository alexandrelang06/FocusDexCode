import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Intent : lancer un focus depuis le widget (ouvre l'app, qui démarre et crédite l'XP)

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Démarrer un focus"
    static var description = IntentDescription("Lance une session de focus de 25 minutes.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        FocusDexShared.defaults?.set(25, forKey: FocusDexShared.startFocusKey)
        return .result()
    }
}

// MARK: - Timeline

struct CompanionEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let image: Image?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CompanionEntry {
        CompanionEntry(date: .now, snapshot: .preview, image: nil)
    }
    func getSnapshot(in context: Context, completion: @escaping (CompanionEntry) -> Void) {
        completion(load())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CompanionEntry>) -> Void) {
        let entry = load()
        // Recharge ~toutes les 30 min pour que la « fraîcheur » suive le temps.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func load() -> CompanionEntry {
        var snap: WidgetSnapshot?
        if let u = FocusDexShared.snapshotURL, let d = try? Data(contentsOf: u) {
            snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: d)
        }
        var image: Image?
        if let u = FocusDexShared.spriteURL, let d = try? Data(contentsOf: u), let ui = UIImage(data: d) {
            image = Image(uiImage: ui).interpolation(.none)
        }
        return CompanionEntry(date: .now, snapshot: snap, image: image)
    }
}

// MARK: - Couleurs (autonomes, alignées sur la marque)

private enum WColor {
    static let bg = Color(.sRGB, red: 0.984, green: 0.953, blue: 0.933, opacity: 1)
    static let bg2 = Color(.sRGB, red: 1.0, green: 0.90, blue: 0.86, opacity: 1)
    static let accent = Color(.sRGB, red: 0.937, green: 0.294, blue: 0.341, opacity: 1)
    static let coin = Color(.sRGB, red: 0.953, green: 0.70, blue: 0.25, opacity: 1)
    static let text = Color(.sRGB, red: 0.231, green: 0.192, blue: 0.22, opacity: 1)
    static let sub = Color(.sRGB, red: 0.61, green: 0.55, blue: 0.54, opacity: 1)
}

// MARK: - Vue

struct FocusDexWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CompanionEntry

    var body: some View {
        let snap = entry.snapshot
        Group {
            if family == .systemSmall { small(snap) } else { medium(snap) }
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [WColor.bg2, WColor.bg], startPoint: .top, endPoint: .bottom)
        }
    }

    private func creature(_ snap: WidgetSnapshot?) -> some View {
        let fresh = snap?.freshness ?? 1
        return ZStack {
            Circle().fill(WColor.accent.opacity(0.12))
            if let img = entry.image {
                img.resizable().aspectRatio(contentMode: .fit).padding(10)
                    .saturation(fresh).opacity(0.55 + 0.45 * fresh)
            } else {
                Image(systemName: "sparkles").font(.system(size: 26)).foregroundStyle(WColor.accent)
            }
            if (snap?.freshness ?? 1) < 0.7 {
                Text("💤").font(.system(size: 18)).offset(x: 22, y: -22)
            }
        }
    }

    private func small(_ snap: WidgetSnapshot?) -> some View {
        let lang = snap?.lang ?? "fr"
        return VStack(spacing: 6) {
            creature(snap).frame(height: 78)
            Text(snap?.name ?? "FocusDex")
                .font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(WColor.text)
                .lineLimit(1)
            if let snap, snap.hatched {
                Text("\(WLoc.t("Niv", lang)) \(snap.level)")
                    .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(WColor.sub)
            } else {
                Text(WLoc.t("Œuf mystère", lang))
                    .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(WColor.sub)
            }
        }
        .padding(4)
    }

    private func medium(_ snap: WidgetSnapshot?) -> some View {
        let lang = snap?.lang ?? "fr"
        return HStack(spacing: 16) {
            creature(snap).frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(snap?.name ?? "FocusDex")
                        .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(WColor.text)
                        .lineLimit(1)
                    if snap?.isShiny == true { Image(systemName: "sparkles").font(.system(size: 12)).foregroundStyle(WColor.coin) }
                }
                if let snap {
                    Text(snap.hatched ? "\(WLoc.t("Niveau", lang)) \(snap.level)" : WLoc.t("Œuf mystère", lang))
                        .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(WColor.sub)
                    ProgressView(value: snap.hatched ? snap.levelProgress : snap.hatchProgress)
                        .tint(WColor.accent)
                    HStack(spacing: 14) {
                        pill(icon: "flame.fill", value: "\(snap.streak)", color: WColor.accent)
                        pill(icon: "square.grid.2x2.fill", value: "\(snap.dexCount)/\(snap.dexTotal)", color: WColor.coin)
                    }
                } else {
                    Text(WLoc.t("Ouvre FocusDex pour commencer", lang))
                        .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(WColor.sub)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(4)
    }

    private func pill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(color)
            Text(value).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(WColor.text)
        }
    }
}

// MARK: - Widget

struct FocusDexWidget: Widget {
    let kind = "FocusDexWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FocusDexWidgetView(entry: entry)
        }
        .configurationDisplayName("FocusDex")
        .description("Ton compagnon, ta série et ta collection en un coup d'œil.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget « Focus express » : bouton pour lancer un chrono

struct FocusStartWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CompanionEntry

    var body: some View {
        let snap = entry.snapshot
        let lang = snap?.lang ?? "fr"
        Group {
            if family == .systemMedium {
                HStack(spacing: 14) {
                    creature.frame(width: 84, height: 84)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(snap?.name ?? "FocusDex")
                            .font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(WColor.text).lineLimit(1)
                        Text(WLoc.t("Fais grandir ta créature", lang))
                            .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(WColor.sub).lineLimit(2)
                        startButton(lang)
                    }
                    Spacer(minLength: 0)
                }.padding(4)
            } else {
                VStack(spacing: 8) {
                    creature.frame(height: 64)
                    startButton(lang)
                }.padding(4)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [WColor.bg2, WColor.bg], startPoint: .top, endPoint: .bottom)
        }
    }

    private var creature: some View {
        ZStack {
            Circle().fill(WColor.accent.opacity(0.12))
            if let img = entry.image {
                img.resizable().aspectRatio(contentMode: .fit).padding(8)
            } else {
                Image(systemName: "leaf.fill").font(.system(size: 24)).foregroundStyle(WColor.accent)
            }
        }
    }

    private func startButton(_ lang: String) -> some View {
        Button(intent: StartFocusIntent()) {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                Text("\(WLoc.t("Focus", lang)) 25 min")
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 9)
            .background(WColor.accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct FocusStartWidget: Widget {
    let kind = "FocusDexStartWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FocusStartWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus express")
        .description("Lance une session de focus depuis l'écran d'accueil.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
