import ActivityKit
import Foundation

/// Démarre / termine la Live Activity d'une session focus.
/// No-op silencieux si les Live Activities sont désactivées par l'utilisateur.
@MainActor
enum FocusLive {
    static func start(companionName: String, minutes: Int, startAt: Date, endAt: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()   // au cas où une activité traîne encore
        let attributes = FocusActivityAttributes(companionName: companionName, totalMinutes: minutes)
        let state = FocusActivityAttributes.ContentState(startDate: startAt, endDate: endAt)
        let content = ActivityContent(state: state, staleDate: endAt.addingTimeInterval(120))
        _ = try? Activity.request(attributes: attributes, content: content)
    }

    static func end() {
        for activity in Activity<FocusActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
