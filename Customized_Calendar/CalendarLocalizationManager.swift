import SwiftUI
import Foundation

// MARK: - Localization Data Model
struct CalendarLocalization: Codable {
    let months: MonthsLocalization
    let days: DaysLocalization
    
    struct MonthsLocalization: Codable {
        let full: [String]
        let short: [String]
    }
    
    struct DaysLocalization: Codable {
        let full: [String]
        let short: [String]
        let min: [String]
    }
}

// Language option model for the picker
struct LanguageOption: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
}

// MARK: - Localization Manager
class CalendarLocalizationManager: ObservableObject {
    @Published var currentLanguage: String = "English" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "CalendarSelectedLanguage")
        }
    }
    
    private var localizations: [String: CalendarLocalization] = [:]
    private(set) var availableLanguages: [LanguageOption] = []
    
    init() {
        // Load saved language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "CalendarSelectedLanguage") {
            currentLanguage = savedLanguage
        } else {
            // Default to system language if available, otherwise English
            let preferredLanguages = Locale.preferredLanguages
            let languageCode = Locale(identifier: preferredLanguages.first ?? "en").languageCode ?? "en"
            
            // Try to find a matching language
            if let matchedLanguage = mapSystemLanguageToSupported(languageCode) {
                currentLanguage = matchedLanguage
            }
        }
        
        // Load localization data
        loadLocalizations()
    }
    
    // Maps system language codes to our supported languages
    private func mapSystemLanguageToSupported(_ code: String) -> String? {
        let mappings = [
            "en": "English",
            "de": "Deutsch",
            "nl": "Nederlands",
            "es": "Español",
            "fr": "Français",
            "cs": "Čeština",
            "it": "Italiano",
            "pt": "Português",
            "pt-BR": "Português Brasileiro",
            "no": "Norsk",
            "sv": "Svenska",
            "da": "Dansk",
            "hr": "Hrvatski",
            "ro": "Română",
            "ar": "العربية",
            "ko": "한국어",
            "he": "עברית",
            "el": "Ελληνικά",
            "pl": "Polski",
            "ru": "Русский",
            "tr": "Türkçe",
            "bg": "Български",
            "ja": "日本語",
            "zh-Hans": "简体中文",
            "zh-HK": "繁體中文(香港)",
            "zh-Hant": "繁體中文(台灣)",
            "ca": "Català",
            "sl": "Slovenščina",
            "hu": "Magyar",
            "et": "Eesti",
            "lv": "Latviski",
            "uk": "Українська",
            "lt": "Lietuvių",
            "id": "Bahasa Indonesia",
            "th": "ภาษาไทย",
            "ms": "Bahasa Malaysia",
            "vi": "Tiếng Việt",
            "is": "Íslenska",
            "sk": "Slovenčina",
            "sr": "Srpski",
            "fil": "Filipino",
            "fi": "Suomi",
            "hi": "Hindi"
        ]
        
        return mappings[code]
    }
    
    // Load all localizations from the JSON file
    private func loadLocalizations() {
        guard let url = Bundle.main.url(forResource: "calendar_localizations", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load localization file")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            localizations = try decoder.decode([String: CalendarLocalization].self, from: data)
            
            // Create language options for the picker
            availableLanguages = localizations.keys.map { LanguageOption(code: $0, name: $0) }
                .sorted { $0.name < $1.name }
            
            print("Loaded \(localizations.count) languages")
        } catch {
            print("Error decoding localizations: \(error)")
        }
    }
    
    // MARK: - Public API
    
    /// Get the full month name for the current language
    func monthName(_ month: Int) -> String {
        guard let localization = localizations[currentLanguage],
              month >= 0 && month < localization.months.full.count else {
            return "Month \(month + 1)"
        }
        return localization.months.full[month]
    }
    
    /// Get the abbreviated month name for the current language
    func shortMonthName(_ month: Int) -> String {
        guard let localization = localizations[currentLanguage],
              month >= 0 && month < localization.months.short.count else {
            return "M\(month + 1)"
        }
        return localization.months.short[month]
    }
    
    /// Get the full day name for the current language
    func dayName(_ day: Int) -> String {
        guard let localization = localizations[currentLanguage],
              day >= 0 && day < localization.days.full.count else {
            return "Day \(day + 1)"
        }
        return localization.days.full[day]
    }
    
    /// Get the abbreviated day name for the current language
    func shortDayName(_ day: Int) -> String {
        guard let localization = localizations[currentLanguage],
              day >= 0 && day < localization.days.short.count else {
            return "D\(day + 1)"
        }
        return localization.days.short[day]
    }
    
    /// Get the minimum day name (1-2 letters) for the current language
    func minDayName(_ day: Int) -> String {
        guard let localization = localizations[currentLanguage],
              day >= 0 && day < localization.days.min.count else {
            return "\(day + 1)"
        }
        return localization.days.min[day]
    }
    
    // Force refresh formatting - call when language changes
    func updateFormatters(monthYearFormatter: inout DateFormatter, weekdayFormatter: inout DateFormatter) {
        // Reset locale to match current language
        let locale = getLocaleForLanguage(currentLanguage)
        monthYearFormatter.locale = locale
        weekdayFormatter.locale = locale
    }
    
    // Helper to get a locale for a language
    private func getLocaleForLanguage(_ language: String) -> Locale {
        // Map language names to locale identifiers
        let localeMap: [String: String] = [
            "English": "en",
            "Deutsch": "de",
            "Nederlands": "nl",
            "Español": "es",
            "Français": "fr",
            "Čeština": "cs",
            "Italiano": "it",
            "Português": "pt",
            "Português Brasileiro": "pt-BR",
            "Norsk": "nb",
            "Svenska": "sv",
            "Dansk": "da",
            "Hrvatski": "hr",
            "Română": "ro",
            "العربية": "ar",
            "한국어": "ko",
            "עברית": "he",
            "Ελληνικά": "el",
            "Polski": "pl",
            "Русский": "ru",
            "Türkçe": "tr",
            "Български": "bg",
            "日本語": "ja",
            "简体中文": "zh-Hans",
            "繁體中文(香港)": "zh-HK",
            "繁體中文(台灣)": "zh-Hant",
            "Català": "ca",
            "Slovenščina": "sl",
            "Magyar": "hu",
            "Eesti": "et",
            "Latviski": "lv",
            "Українська": "uk",
            "Lietuvių": "lt",
            "Bahasa Indonesia": "id",
            "ภาษาไทย": "th",
            "Bahasa Malaysia": "ms",
            "Tiếng Việt": "vi",
            "Íslenska": "is",
            "Slovenčina": "sk",
            "Srpski": "sr",
            "Filipino": "fil",
            "Suomi": "fi",
            "Hindi": "hi"
        ]
        
        let localeIdentifier = localeMap[language] ?? "en"
        return Locale(identifier: localeIdentifier)
    }
}
