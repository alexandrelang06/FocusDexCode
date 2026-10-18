import UIKit

/// Retours haptiques légers pour les moments clés (récompense, éclosion, échec).
enum Haptics {
    static func success() {
        let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success)
    }
    static func warning() {
        let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.warning)
    }
    static func light() {
        let g = UIImpactFeedbackGenerator(style: .light); g.impactOccurred()
    }
    static func heavy() {
        let g = UIImpactFeedbackGenerator(style: .heavy); g.impactOccurred()
    }
}
