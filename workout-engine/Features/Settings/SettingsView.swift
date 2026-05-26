import SwiftUI

struct SettingsView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.t("Звук")) {
                    Toggle(L10n.t("Звуковые сигналы"), isOn: $settings.soundsEnabled)
                    if settings.soundsEnabled {
                        Toggle(L10n.t("Подготовка"), isOn: $settings.soundOnPrepare)
                        Toggle(L10n.t("Работа"), isOn: $settings.soundOnWork)
                        Toggle(L10n.t("Отдых"), isOn: $settings.soundOnRest)
                        Toggle(L10n.t("Завершение"), isOn: $settings.soundOnFinish)
                        Toggle(L10n.t("Отсчёт последних 3 секунд"), isOn: $settings.soundOnCountdown)
                    }
                }

                Section(L10n.t("Тактильная отдача")) {
                    Toggle(L10n.t("Вибрация"), isOn: $settings.hapticsEnabled)
                }

                Section(L10n.t("Экран")) {
                    Toggle(L10n.t("Не гасить экран во время тренировки"), isOn: $settings.keepScreenOnDuringWorkout)
                }

                Section {
                    Text(L10n.t("Таймер продолжает работу в фоне за счёт аудиосессии и коротких сигналов на смену фаз."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L10n.t("Настройки"))
        }
    }
}

#Preview {
    SettingsView()
}
