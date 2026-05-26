import SwiftUI

struct WorkoutFinishOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce)

                Text(L10n.t("Готово"))
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(32)
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.t("Тренировка завершена"))
    }
}

#Preview {
    WorkoutFinishOverlay()
}
