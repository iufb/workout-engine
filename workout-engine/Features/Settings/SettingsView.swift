import SwiftUI

struct SettingsView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Звук")) {
                    Toggle(String(localized: "Звуковые сигналы"), isOn: $settings.soundsEnabled)
                    if settings.soundsEnabled {
                        Toggle(String(localized: "Подготовка"), isOn: $settings.soundOnPrepare)
                        Toggle(String(localized: "Работа"), isOn: $settings.soundOnWork)
                        Toggle(String(localized: "Отдых"), isOn: $settings.soundOnRest)
                        Toggle(String(localized: "Завершение"), isOn: $settings.soundOnFinish)
                        Toggle(String(localized: "Отсчёт последних 3 секунд"), isOn: $settings.soundOnCountdown)
                    }
                }

                Section(String(localized: "Тактильная отдача")) {
                    Toggle(String(localized: "Вибрация"), isOn: $settings.hapticsEnabled)
                }

                Section(String(localized: "Экран")) {
                    Toggle(String(localized: "Не гасить экран во время тренировки"), isOn: $settings.keepScreenOnDuringWorkout)
                }

                Section {
                    Text(String(localized: "Таймер продолжает работу в фоне за счёт аудиосессии и коротких сигналов на смену фаз."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "Настройки"))
        }
    }
}

#Preview {
    SettingsView()
}
