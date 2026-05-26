import SwiftUI

struct WorkoutEmptyPresetsHint: View {
    var onCreatePreset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("Пока нет своих интервалов"))
                .font(.headline)
            Text(L10n.t("Создайте первый интервал в конструкторе"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onCreatePreset) {
                Label(L10n.t("Создать интервал"), systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .workoutCard()
    }
}

#Preview {
    WorkoutEmptyPresetsHint(onCreatePreset: {})
        .padding()
}
