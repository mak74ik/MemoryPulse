import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case ru = "RU"
    case en = "EN"

    public var id: String { rawValue }

    public var isRussian: Bool {
        switch self {
        case .ru:
            return true
        case .en:
            return false
        case .auto:
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
            return preferred.starts(with: "ru")
        }
    }
}

@MainActor
public final class L10n: ObservableObject {
    public static let shared = L10n()

    @AppStorage("app_language_pref") public var currentLanguage: AppLanguage = .auto

    private init() {}

    public var isRu: Bool { currentLanguage.isRussian }

    // MARK: - Strings Dictionary
    public var appTitle: String { isRu ? "Монитор ресурсов" : "Resource Monitor" }
    public var appSubtitle: String { isRu ? "Студия производительности macOS" : "macOS Performance Studio" }
    
    // Sort labels
    public var sortMemory: String { isRu ? "Память (RAM)" : "Memory (RAM)" }
    public var sortCPU: String { isRu ? "Нагрузка CPU" : "CPU Load" }
    public var sortName: String { isRu ? "Имя (A-Z)" : "Name (A-Z)" }

    // Filter modes
    public var filterApps: String { isRu ? "Приложения" : "Apps" }
    public var filterAll: String { isRu ? "Все процессы" : "All Processes" }
    public var filterHeavy: String { isRu ? "Тяжелые (>300 MB)" : "Heavy (>300 MB)" }

    // Metric titles
    public var metricUsed: String { isRu ? "Используется" : "Used RAM" }
    public var metricUsedSub: String { isRu ? "от общего объема" : "of total capacity" }
    public var metricCache: String { isRu ? "Кэш ядра" : "Cache / Inactive" }
    public var metricCacheSub: String { isRu ? "Сбрасывается при нехватке" : "Reclaimed when needed" }
    public var metricWired: String { isRu ? "Wired (Ядро)" : "Wired Memory" }
    public var metricWiredSub: String { isRu ? "Заблокировано системой" : "Locked by Darwin OS" }
    public var metricFree: String { isRu ? "Свободно" : "Free RAM" }
    public var metricFreeSub: String { isRu ? "Чистый резерв памяти" : "Pure available buffer" }
    public var metricSwap: String { isRu ? "Файл подкачки (Swap)" : "Swap Storage" }

    // Actions
    public var purgeButton: String { isRu ? "Очистить память" : "Purge Memory" }
    public var purgingProgress: String { isRu ? "Очистка кэша..." : "Purging Cache..." }
    public var quitBackground: String { isRu ? "Закрыть все фоновые" : "Quit Background Apps" }
    public var quitGentle: String { isRu ? "Завершить" : "Quit" }
    public var forceQuit: String { isRu ? "Принудительно" : "Force Kill" }
    public var refreshTooltip: String { isRu ? "Обновить показатели (⌘R)" : "Refresh Statistics (⌘R)" }
    public var searchPlaceholder: String { isRu ? "Поиск по названию или PID (⌘F)..." : "Search by name or PID (⌘F)..." }
    
    // Process list headers
    public var headerProcess: String { isRu ? "ПРОЦЕСС" : "PROCESS" }
    public var headerLoad: String { isRu ? "НАГРУЗКА" : "LOAD" }
    public var headerActions: String { isRu ? "ДЕЙСТВИЯ" : "ACTIONS" }
    public var emptySearch: String { isRu ? "Процессы не найдены" : "No matching processes found" }

    // Context Menu
    public var ctxShowInFinder: String { isRu ? "Показать в Finder" : "Show in Finder" }
    public var ctxCopyPID: String { isRu ? "Скопировать PID" : "Copy PID" }
    public var ctxCopyPath: String { isRu ? "Скопировать путь" : "Copy App Path" }

    // Pressure
    public var pressureNormal: String { isRu ? "В норме" : "Nominal" }
    public var pressureWarn: String { isRu ? "Умеренная нагрузка" : "Moderate" }
    public var pressureCrit: String { isRu ? "Критическая" : "Critical" }
}
