import Foundation
import Darwin

/// Analytics produit via PostHog (API REST `/capture/`), sans SDK.
/// No-op tant qu'aucune clé `PostHogAPIKey` n'est configurée dans Info.plist.
/// Identité anonyme et stable par appareil (aucun compte requis).
enum Analytics {
    private static let d = UserDefaults.standard
    private static let idKey = "focusdex.analyticsID"

    private static var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "PostHogAPIKey") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    private static var host: String {
        let h = (Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return h.isEmpty ? "https://eu.i.posthog.com" : h
    }
    /// Actif seulement si une clé est fournie (sinon tout est no-op, aucune requête réseau).
    static var enabled: Bool { !apiKey.isEmpty }

    /// Identifiant anonyme persistant (par appareil/installation).
    private static var distinctId: String {
        if let s = d.string(forKey: idKey) { return s }
        let s = UUID().uuidString
        d.set(s, forKey: idKey)
        return s
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    /// Enregistre un événement produit.
    static func capture(_ event: String, _ props: [String: Any] = [:]) {
        guard enabled else { return }
        var properties = props
        properties["$lib"] = "focusdex-rest"
        properties["app_version"] = appVersion
        let body: [String: Any] = [
            "api_key": apiKey,
            "event": event,
            "distinct_id": distinctId,
            "properties": properties,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]
        send(body)
    }

    /// Met à jour des propriétés de la personne (ex. `plan`), pour segmenter les funnels.
    static func setPerson(_ props: [String: Any]) {
        capture("$identify", ["$set": props])
    }

    private static func send(_ body: [String: Any]) {
        guard let url = URL(string: host + "/capture/"),
              let data = try? JSONSerialization.data(withJSONObject: body) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = data
        URLSession.shared.dataTask(with: req).resume()   // fire-and-forget
    }

    // MARK: - Remontée d'erreurs / crashes

    /// Erreur gérée (à appeler dans les `catch`), envoyée comme `$exception` (Error Tracking PostHog).
    static func captureError(_ type: String, _ message: String, extra: [String: Any] = [:]) {
        var props: [String: Any] = [
            "$exception_list": [["type": type, "value": message, "mechanism": ["handled": true]]],
        ]
        for (k, v) in extra { props[k] = v }
        capture("$exception", props)
    }

    private static var crashPath: String {
        (NSTemporaryDirectory() as NSString).appendingPathComponent("focusdex_crash.txt")
    }
    private static var crashFD: Int32 = -1

    /// À appeler une fois au démarrage : envoie un éventuel crash précédent puis arme les handlers.
    static func installCrashReporting() {
        let path = crashPath
        // 1) Envoyer le crash de la session précédente s'il existe.
        if let content = try? String(contentsOfFile: path, encoding: .utf8),
           !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            capture("$exception", [
                "$exception_list": [["type": "AppCrash", "value": String(content.prefix(200)),
                                     "mechanism": ["handled": false]]],
                "crash_report": String(content.prefix(6000)),
            ])
        }
        // 2) Ouvrir un fichier neuf pour la session courante (tronqué).
        crashFD = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        // 3) Exceptions Objective-C.
        NSSetUncaughtExceptionHandler { exc in
            guard Analytics.crashFD >= 0 else { return }
            let text = "exception \(exc.name.rawValue): \(exc.reason ?? "")\n"
                + exc.callStackSymbols.joined(separator: "\n")
            text.withCString { _ = write(Analytics.crashFD, $0, strlen($0)) }
        }
        // 4) Signaux (crashes Swift : fatalError, unwrap nil, index hors limites…).
        for sig in [SIGABRT, SIGSEGV, SIGILL, SIGFPE, SIGBUS, SIGTRAP] {
            signal(sig, Analytics.signalHandler)
        }
    }

    /// Handler de signal minimal et async-signal-safe (backtrace vers le fichier, pré-ouvert).
    private static let signalHandler: @convention(c) (Int32) -> Void = { sig in
        let fd = Analytics.crashFD
        if fd >= 0 {
            withUnsafeTemporaryAllocation(of: UnsafeMutableRawPointer?.self, capacity: 64) { buf in
                let n = backtrace(buf.baseAddress, 64)
                backtrace_symbols_fd(buf.baseAddress, n, fd)
            }
        }
        signal(sig, SIG_DFL)
        raise(sig)
    }
}
