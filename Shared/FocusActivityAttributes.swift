import ActivityKit
import Foundation

/// Attributs de la Live Activity de session focus.
/// Ce fichier est compilé DANS LES DEUX targets (app + widget) : le type doit être identique
/// des deux côtés pour qu'ActivityKit relie l'activité démarrée par l'app à son rendu dans le widget.
struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startDate: Date
        var endDate: Date
    }
    var companionName: String
    var totalMinutes: Int
}
