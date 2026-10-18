import UserNotifications

/// Rappel quotidien doux pour entretenir la série et faire éclore les œufs.
enum Notifications {
    static let dailyID = "focusdex.daily"

    /// Demande l'autorisation (affiche la boîte système) et attend la réponse, puis planifie si accordé.
    @discardableResult
    static func requestAndScheduleAsync(title: String, body: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted { scheduleDaily(title: title, body: body) }
        return granted
    }

    static func scheduleDaily(hour: Int = 19, minute: Int = 0,
                              title: String = "Ton refuge t'attend 🌿",
                              body: String = "Une petite session de focus pour faire grandir ta créature ?") {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        var comps = DateComponents(); comps.hour = hour; comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyID])
    }

    // MARK: Rappels d'essai gratuit (J-2 puis fin)
    static let trial5ID = "focusdex.trial.d5"
    static let trial7ID = "focusdex.trial.d7"

    /// Programme deux rappels : 2 jours avant la fin de l'essai, puis le jour de la fin.
    static func scheduleTrialReminders(trialEnd: Date,
                                       title5: String, body5: String,
                                       title7: String, body7: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [trial5ID, trial7ID])
        func at(_ date: Date, id: String, title: String, body: String) {
            guard date > Date() else { return }
            let content = UNMutableNotificationContent()
            content.title = title; content.body = body; content.sound = .default
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
        at(trialEnd.addingTimeInterval(-2 * 86_400), id: trial5ID, title: title5, body: body5)   // J5
        at(trialEnd, id: trial7ID, title: title7, body: body7)                                    // J7
    }

    static func cancelTrialReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [trial5ID, trial7ID])
    }
}
