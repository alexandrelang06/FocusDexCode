import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Bundle (widget accueil + Live Activity focus)

@main
struct FocusDexWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusDexWidget()
        FocusStartWidget()
        FocusLiveActivity()
    }
}

// MARK: - Live Activity de session focus

private enum LColor {
    static let bg = Color(.sRGB, red: 0.984, green: 0.953, blue: 0.933, opacity: 1)
    static let accent = Color(.sRGB, red: 0.937, green: 0.294, blue: 0.341, opacity: 1)
    static let text = Color(.sRGB, red: 0.231, green: 0.192, blue: 0.22, opacity: 1)
    static let sub = Color(.sRGB, red: 0.61, green: 0.55, blue: 0.54, opacity: 1)
}

private func companionImage() -> Image {
    if let u = FocusDexShared.spriteURL, let d = try? Data(contentsOf: u), let ui = UIImage(data: d) {
        return Image(uiImage: ui).interpolation(.none)
    }
    return Image(systemName: "leaf.fill")
}

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(LColor.bg)
                .activitySystemActionForegroundColor(LColor.accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    companionImage().resizable().aspectRatio(contentMode: .fit).frame(width: 42, height: 42)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                        .font(.system(size: 30, weight: .heavy, design: .rounded)).monospacedDigit()
                        .foregroundStyle(LColor.accent).frame(width: 96)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.companionName)
                        .font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(.primary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(timerInterval: context.state.startDate...context.state.endDate, countsDown: true) {
                        EmptyView()
                    } currentValueLabel: { EmptyView() }
                    .tint(LColor.accent)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(LColor.accent)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                    .font(.system(size: 13, weight: .bold, design: .rounded)).monospacedDigit()
                    .foregroundStyle(LColor.accent).frame(width: 44)
            } minimal: {
                Image(systemName: "timer").foregroundStyle(LColor.accent)
            }
        }
    }

    private func lockScreen(_ context: ActivityViewContext<FocusActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            companionImage().resizable().aspectRatio(contentMode: .fit).frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.companionName)
                    .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(LColor.text)
                Text("Focus \(context.attributes.totalMinutes) min")
                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(LColor.sub)
                ProgressView(timerInterval: context.state.startDate...context.state.endDate, countsDown: true) {
                    EmptyView()
                } currentValueLabel: { EmptyView() }
                .tint(LColor.accent)
            }
            Spacer(minLength: 4)
            Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                .font(.system(size: 30, weight: .heavy, design: .rounded)).monospacedDigit()
                .foregroundStyle(LColor.accent).frame(width: 92)
        }
        .padding(16)
    }
}
