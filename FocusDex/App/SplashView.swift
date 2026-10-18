import SwiftUI

/// Écran d'accueil animé pendant l'initialisation (créatures + wordmark).
/// Remplace le simple fond uni au lancement.
struct SplashView: View {
    @Environment(AppModel.self) private var model
    @State private var appear = false
    @State private var bounce = false
    @State private var halo = false

    var body: some View {
        let t = model.theme
        ZStack {
            LinearGradient(colors: [t.accent.opacity(0.18), t.bg, t.bg],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                heroCreatures
                VStack(spacing: 8) {
                    Text("FocusDex")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.text)
                    Text(model.t("Concentre-toi, prends soin de toi et fais éclore une collection de créatures."))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(t.sub)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 44)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
                Spacer()
                dots.padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { appear = true }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { bounce = true }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { halo = true }
        }
    }

    private var heroCreatures: some View {
        let t = model.theme
        return ZStack {
            Circle().fill(t.accent.opacity(0.12))
                .frame(width: 210, height: 210)
                .scaleEffect(halo ? 1.06 : 0.9)
                .opacity(halo ? 0.9 : 0.5)
            HStack(spacing: -20) {
                ForEach(Array(model.teaserCreatures().prefix(3)), id: \.id) { c in
                    CreatureImage(sprite: c.sprite)
                        .frame(width: 92, height: 92)
                        .background(Circle().fill(t.card))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(t.bg, lineWidth: 3))
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                }
            }
            .scaleEffect(bounce ? 1.03 : 0.97)
            .opacity(appear ? 1 : 0)
        }
    }

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(model.theme.accent.opacity(bounce ? 0.9 : 0.35))
                    .frame(width: 7, height: 7)
                    .scaleEffect(bounce ? 1 : 0.7)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(i) * 0.18), value: bounce)
            }
        }
    }
}
