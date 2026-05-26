import SwiftUI

struct WorkoutEmptyPresetsHint: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("Пока нет своих интервалов"))
                .font(.headline)
            Text(L10n.t("Создайте интервал во вкладке «Конструктор»"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .workoutCard()
    }
}

#Preview {
    WorkoutEmptyPresetsHint()
        .padding()
}
