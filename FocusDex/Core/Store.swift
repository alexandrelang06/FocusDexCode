import StoreKit

/// Achats intégrés (StoreKit 2). Abo Pro (mensuel/annuel), Pro à vie, et packs de bonbons.
/// NB : les vrais achats ne se testent que dans Xcode (config `FocusDex.storekit` via le scheme) ou sur
/// appareil. En DEBUG sans produits chargés, on simule l'achat pour tester le flux (paywall).
@MainActor
@Observable
final class Store {
    var products: [Product] = []
    var purchasing: String?

    static let proMonthly = "com.focusdex.pro.monthly"
    static let proYearly  = "com.focusdex.pro.yearly"
    static let proLifetime = "com.focusdex.pro.lifetime"
    static let candyS = "com.focusdex.candy.small"
    static let candyM = "com.focusdex.candy.medium"
    static let candyL = "com.focusdex.candy.large"
    static let ids = [proMonthly, proYearly, proLifetime, candyS, candyM, candyL]

    struct CandyPack: Identifiable { let id: String; let candy: Int; let fallback: String }
    static let candyPacks: [CandyPack] = [
        .init(id: candyS, candy: 500,  fallback: "0,99 €"),
        .init(id: candyM, candy: 1800, fallback: "2,99 €"),
        .init(id: candyL, candy: 5000, fallback: "6,99 €"),
    ]

    private let model: AppModel
    private var updates: Task<Void, Never>?

    init(model: AppModel) {
        self.model = model
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.handle(result) }
        }
        Task { await load(); await refreshEntitlements() }
    }

    func load() async { products = (try? await Product.products(for: Self.ids)) ?? [] }
    func product(_ id: String) -> Product? { products.first { $0.id == id } }
    func priceLabel(_ id: String, fallback: String) -> String { product(id)?.displayPrice ?? fallback }

    /// Libellé « par mois » pour l'annuel (aide à la comparaison).
    func perMonthLabel(_ id: String) -> String? {
        guard let p = product(id), let sub = p.subscription, sub.subscriptionPeriod.unit == .year else { return nil }
        let monthly = (NSDecimalNumber(decimal: p.price).doubleValue) / 12.0
        return String(format: "≈ %.2f €/mois", monthly)
    }

    static func candyGrant(_ id: String) -> Int {
        candyPacks.first { $0.id == id }?.candy ?? 0
    }
    static func grant(_ id: String, to model: AppModel) {
        switch id {
        case proMonthly, proYearly, proLifetime: model.grantPro()
        default:
            let n = candyGrant(id); if n > 0 { model.grantCandy(n) }
        }
    }

    @discardableResult
    func purchase(_ id: String) async -> Bool {
        guard let p = product(id) else {
            #if DEBUG
            Self.grant(id, to: model); return true      // simulateur sans StoreKit → on simule
            #else
            return false
            #endif
        }
        purchasing = id; defer { purchasing = nil }
        guard let result = try? await p.purchase() else { return false }
        if case .success(let verification) = result, case .verified(let t) = verification {
            Self.grant(t.productID, to: model)
            await t.finish()
            return true
        }
        return false
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let t) = result {
            Self.grant(t.productID, to: model)
            await t.finish()
        }
    }

    /// Recalcule l'accès Pro depuis les droits actuels (abo actif ou achat à vie).
    func refreshEntitlements() async {
        var pro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               [Self.proMonthly, Self.proYearly, Self.proLifetime].contains(t.productID) {
                pro = true
            }
        }
        if pro { model.grantPro() }
        else if !products.isEmpty { model.revokePro() }   // vrai StoreKit : accès expiré → retiré (re-blocage)
    }

    func restore() async {
        try? await AppStore.sync(); await refreshEntitlements()
        Analytics.capture("restore_completed", ["pro": model.proActive])
    }
}
