import SwiftUI

/// Charge et met en cache les sprites de créatures depuis le bundle (dossier `creatures/` ou racine).
enum CreatureSprites {
    private static var cache: [String: UIImage] = [:]

    static func image(_ sprite: String) -> UIImage? {
        if let c = cache[sprite] { return c }
        let name = (sprite as NSString).deletingPathExtension
        let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "creatures")
            ?? Bundle.main.url(forResource: name, withExtension: "png")
        guard let u = url, let img = UIImage(contentsOfFile: u.path) else { return nil }
        cache[sprite] = img
        return img
    }
}

/// Affiche une créature. `shiny` applique une teinte alternative ; `silhouette` masque (dex non découvert).
struct CreatureImage: View {
    let sprite: String
    var shiny: Bool = false
    var silhouette: Bool = false

    var body: some View {
        if let ui = CreatureSprites.image(sprite) {
            let img = Image(uiImage: ui)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
            if silhouette {
                Rectangle().fill(Color.primary.opacity(0.72)).mask(img)
            } else if shiny {
                img.hueRotation(.degrees(150)).saturation(1.25).brightness(0.02)
                    .overlay(shineOverlay.mask(img))
            } else {
                img
            }
        } else {
            RoundedRectangle(cornerRadius: 12).fill(.gray.opacity(0.2))
                .overlay(Image(systemName: "questionmark").foregroundStyle(.gray))
        }
    }

    private var shineOverlay: some View {
        LinearGradient(colors: [.white.opacity(0.0), .white.opacity(0.28), .white.opacity(0.0)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Petite étoile « shiny » réutilisable.
struct ShinyBadge: View {
    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(5)
            .background(Circle().fill(Color.hex(0xF0B54A)))
    }
}
