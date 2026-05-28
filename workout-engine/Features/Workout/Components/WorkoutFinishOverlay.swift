import SwiftUI

struct WorkoutFinishOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var heroVisible = false

    var body: some View {
        ZStack {
            WorkoutFinishBackground()

            if !reduceMotion {
                ConfettiView()
            }

            heroContent
                .scaleEffect(heroVisible ? 1 : 0.88)
                .opacity(heroVisible ? 1 : 0)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.bouncy(duration: 0.55)) {
                heroVisible = true
            }
        }
    }

    private var heroContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, value: heroVisible)

            Text(L10n.t("Готово"))
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.t("Тренировка завершена"))
    }
}

#Preview {
    ZStack {
        Color.black
        WorkoutFinishOverlay()
    }
}
