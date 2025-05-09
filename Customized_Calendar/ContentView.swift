import SwiftUI

// MARK: - Language Models
struct LanguageData: Codable {
    var months: MonthNames
    var days: DayNames
    
    struct MonthNames: Codable {
        var full: [String]
        var short: [String]
    }
    
    struct DayNames: Codable {
        var full: [String]
        var short: [String]
        var min: [String]
    }
}

// MARK: - Models
struct DateSelection {
    var selectedDates: [Date] = []
    var selectionState: SelectionState = .none
    
    enum SelectionState {
        case none
        case firstDateSelected
        case rangeSelected
    }
}

// MARK: - Calendar Date Utilities
// Extracted reusable date formatting logic
struct CalendarFormatting {
    private static let dateCache = NSCache<NSString, NSString>()
    private static let timeCache = NSCache<NSString, NSString>()
    
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    static func monthString(for date: Date, languageData: LanguageData?, calendar: Calendar) -> String {
        if let languageData = languageData {
            let monthIndex = calendar.component(.month, from: date) - 1
            if monthIndex >= 0 && monthIndex < languageData.months.short.count {
                return languageData.months.short[monthIndex]
            }
        }
        return monthFormatter.string(from: date)
    }
    
    static func yearString(for date: Date) -> String {
        return yearFormatter.string(from: date)
    }
    
    static func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "MMM DD, YYYY" }
        
        let cacheKey = "\(date.timeIntervalSince1970)" as NSString
        if let cachedResult = dateCache.object(forKey: cacheKey) {
            return cachedResult as String
        }
        
        let result = fullDateFormatter.string(from: date)
        dateCache.setObject(result as NSString, forKey: cacheKey)
        return result
    }
    
    static func formattedTime(_ date: Date) -> String {
        let cacheKey = "\(date.timeIntervalSince1970)" as NSString
        if let cachedResult = timeCache.object(forKey: cacheKey) {
            return cachedResult as String
        }
        
        let result = timeFormatter.string(from: date)
        timeCache.setObject(result as NSString, forKey: cacheKey)
        return result
    }
}

// MARK: - CalendarView
struct CalendarView: View {
    // MARK: - Properties
    private let calendar = Calendar.current
    
    // MARK: - Language Properties
    @State private var languages: [String: LanguageData] = [:]
    @State private var selectedLanguage: String = "English"
    @State private var showLanguagePicker = false
    
    // MARK: - State
    @State private var dateSelection = DateSelection()
    @State private var currentMonth = Date()
    @State private var showingMonths = 12
    
    // Time selection
    @State private var timeSelection: Bool = true
    @State private var departureTime = Date()
    @State private var showDepartureTimePicker: Bool = false
    @State private var returnTime = Date()
    @State private var showReturnTimePicker: Bool = false
    
    // Single or range selection
    @State private var singleDate: Bool = true
    
    // MARK: - Computed Properties
    private var selectedDates: [Date] {
        dateSelection.selectedDates
    }
    
    private var availableLanguages: [String] {
        Array(languages.keys).sorted()
    }
    
    private var weekdayNames: [String] {
        // Get the short day names for the selected language
        // Default to English-like weekday abbreviations if language data isn't loaded
        guard let languageData = languages[selectedLanguage] else {
            return ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        }

        var shortDays = languageData.days.short

        if shortDays.count == 7 {
            let sunday = shortDays.removeFirst()
            shortDays.append(sunday)
        }
        return shortDays
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with language selection button
                headerView
                
                // Sticky weekday header
                weekdayHeaderView
                    .background(Color.white)
                    .zIndex(1)
                
                // Calendar main part
                calendarScrollView
                
                // Footer with date selection and apply button
                footerView
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.white),
                        Color(UIColor.systemGray6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
            .onAppear {
                loadLanguageData()
            }
            .sheet(isPresented: $showLanguagePicker) {
                languagePickerView
            }
        }
    }
    
    // MARK: - View Components
    private var headerView: some View {
        HStack {
            Spacer()
            
            // Language selection button
            Button(action: {
                showLanguagePicker = true
            }) {
                HStack {
                    Text(selectedLanguage)
                        .font(.subheadline)
                    
                    Image(systemName: "globe")
                        .font(.subheadline)
                }
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
            .padding(.trailing)
        }
        .padding(.vertical, 20)
    }
    
    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(weekdayNames.indices, id: \.self) { index in
                Text(weekdayNames[index])
                    .font(.caption)
                    .fontWeight(.regular)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color("calendarColor"))
            }
        }
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    private var calendarScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                ForEach(0..<showingMonths, id: \.self) { monthOffset in
                    if let date = calendar.date(byAdding: .month, value: monthOffset, to: currentMonth) {
                        Section(header:
                            MonthHeaderView(
                                month: date,
                                calendar: calendar,
                                languageData: languages[selectedLanguage]
                            )
                        ) {
                            MonthView(
                                month: date,
                                dateSelection: $dateSelection,
                                calendar: calendar,
                                singleDateMode: !singleDate,
                                languageData: languages[selectedLanguage],
                                showHeader: false
                            )
                            .id("month-\(monthOffset)")
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    private var footerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                DateAndTime(
                    showTimePicker: $showDepartureTimePicker,
                    selectedTime: $departureTime,
                    timeSelection: $timeSelection,
                    selectedDates: dateSelection.selectedDates,
                    isFirst: true,
                    label: "Departure"
                )
                
                if singleDate {
                    DateAndTime(
                        showTimePicker: $showReturnTimePicker,
                        selectedTime: $returnTime,
                        timeSelection: $timeSelection,
                        selectedDates: dateSelection.selectedDates,
                        isFirst: false,
                        label: "Return"
                    )
                }
            }
            .padding()
            
            Button(action: {
                // Apply action
            }) {
                ApplyButton()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
    }
    
    private var languagePickerView: some View {
        NavigationView {
            List {
                ForEach(availableLanguages, id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                        showLanguagePicker = false
                    }) {
                        HStack {
                            Text(language)
                            
                            Spacer()
                            
                            if language == selectedLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Language")
            .navigationBarItems(trailing: Button("Cancel") {
                showLanguagePicker = false
            })
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Methods
    // Load language data from the calendar_localizations file
    private func loadLanguageData() {
        guard let fileURL = Bundle.main.url(forResource: "calendar_localizations", withExtension: "json"),
              let jsonData = try? Data(contentsOf: fileURL) else {
            print("Failed to load language data file")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            languages = try decoder.decode([String: LanguageData].self, from: jsonData)
            
            // Set default language - use English if available, otherwise first in list
            if languages.keys.contains("English") {
                selectedLanguage = "English"
            } else {
                selectedLanguage = languages.keys.sorted().first ?? selectedLanguage
            }
        } catch {
            print("Error decoding language data: \(error)")
        }
    }
}

// MARK: - Visibility Check Modifier
struct VisibilityDetector: ViewModifier {
    let onVisible: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: VisibilityPreferenceKey.self, value: geometry.frame(in: .named("calendarScroll")))
                }
            )
            .onPreferenceChange(VisibilityPreferenceKey.self) { frame in
                let isVisible = frame.minY < 100 && frame.maxY > 0
                onVisible(isVisible)
            }
    }
}

struct VisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension View {
    func checkVisibility(onVisible: @escaping (Bool) -> Void) -> some View {
        modifier(VisibilityDetector(onVisible: onVisible))
    }
}

// MARK: - MonthHeaderView (Sticky Section Header)
struct MonthHeaderView: View {
    let month: Date
    let calendar: Calendar
    let languageData: LanguageData?
    
    private var monthOnly: String {
        CalendarFormatting.monthString(for: month, languageData: languageData, calendar: calendar)
    }
    
    private var yearOnly: String {
        CalendarFormatting.yearString(for: month)
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Spacer()
            Text(monthOnly)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("calendarColor"))
            Text(yearOnly)
                .font(.caption)
                .foregroundColor(Color("calendarColor"))
                .fontWeight(.bold)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - MonthSectionView (Combined Month and Grid)
struct MonthSectionView: View {
    let month: Date
    @Binding var dateSelection: DateSelection
    let calendar: Calendar
    let singleDateMode: Bool
    let languageData: LanguageData?
    let onVisible: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Month dates grid without the header
            MonthView(
                month: month,
                dateSelection: $dateSelection,
                calendar: calendar,
                singleDateMode: singleDateMode,
                languageData: languageData,
                showHeader: false
            )
        }
        .checkVisibility(onVisible: onVisible)
    }
}

// MARK: - MonthView
struct MonthView: View {
    let month: Date
    @Binding var dateSelection: DateSelection
    let calendar: Calendar
    let singleDateMode: Bool
    let languageData: LanguageData?
    let showHeader: Bool
    
    // Cache computed values
    private let monthStart: Date
    private let daysInMonth: Int
    private let adjustedFirstWeekday: Int
    private let today: Date
    
    private var monthOnly: String {
        CalendarFormatting.monthString(for: month, languageData: languageData, calendar: calendar)
    }
    
    private var yearOnly: String {
        CalendarFormatting.yearString(for: month)
    }
    
    init(month: Date, dateSelection: Binding<DateSelection>, calendar: Calendar, singleDateMode: Bool = false, languageData: LanguageData? = nil, showHeader: Bool = true) {
        self.month = month
        self._dateSelection = dateSelection
        self.calendar = calendar
        self.languageData = languageData
        self.showHeader = showHeader
        self.singleDateMode = singleDateMode
        
        // Pre-compute values
        self.monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        self.daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        self.adjustedFirstWeekday = (firstWeekday + 5) % 7 // Adjusting to make Monday = 0, Sunday = 6
        
        // Cache today's date for performance
        self.today = calendar.startOfDay(for: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                HStack {
                    Text(monthOnly)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("calendarColor"))
                    Text(yearOnly)
                        .font(.caption)
                        .foregroundColor(Color("calendarColor"))
                        .fontWeight(.bold)
                }
            }
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                // Empty cells for days before the first of month
                ForEach(0..<adjustedFirstWeekday, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
                
                // Days of the month
                ForEach(1...daysInMonth, id: \.self) { day in
                    if let currentDate = createDate(day: day) {
                        DayCell(
                            date: currentDate,
                            day: day,
                            selectedDates: dateSelection.selectedDates,
                            calendar: calendar,
                            today: today
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture {
                            if !isPastDate(currentDate) {
                                handleDateSelection(currentDate)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Optimized date creation
    private func createDate(day: Int) -> Date? {
        return calendar.date(from: DateComponents(
            year: calendar.component(.year, from: monthStart),
            month: calendar.component(.month, from: monthStart),
            day: day
        ))
    }
    
    private func isPastDate(_ date: Date) -> Bool {
        calendar.compare(date, to: today, toGranularity: .day) == .orderedAscending
    }
    
    private func handleDateSelection(_ date: Date) {
        if singleDateMode {
            // Single date mode - always just select one date
            dateSelection.selectedDates = [date]
            dateSelection.selectionState = .firstDateSelected
        }
        else {
            switch dateSelection.selectionState {
            case .none:
                // First date selected
                dateSelection.selectedDates = [date]
                dateSelection.selectionState = .firstDateSelected
                
            case .firstDateSelected:
                // Second date selected, create range
                if calendar.isDate(date, inSameDayAs: dateSelection.selectedDates[0]) {
                    // If tapping the same date again, just keep it selected
                    return
                }
                
                let startDate = min(date, dateSelection.selectedDates[0])
                let endDate = max(date, dateSelection.selectedDates[0])
                dateSelection.selectedDates = createDateRange(from: startDate, to: endDate)
                dateSelection.selectionState = .rangeSelected
                
            case .rangeSelected:
                // Clear previous selection, start fresh
                dateSelection.selectedDates = [date]
                dateSelection.selectionState = .firstDateSelected
            }
        }
    }
    
    private func createDateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        
        // Pre-compute days between to avoid unnecessary date calculations in the loop
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        dates.reserveCapacity(daysBetween + 1)
        
        while currentDate <= endDate {
            // Skip past dates
            if calendar.compare(currentDate, to: today, toGranularity: .day) != .orderedAscending {
                dates.append(currentDate)
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
}

// MARK: - DayCell
struct DayCell: View {
    let date: Date
    let day: Int  // Pre-computed day value
    let selectedDates: [Date]
    let calendar: Calendar
    let today: Date
    
    // Memoized properties to avoid repeated calculations
    private var isEndpoint: Bool {
        isDateEndpoint(date)
    }
    
    private var isInRange: Bool {
        isDateInRange(date)
    }
    
    private var isPastDate: Bool {
        calendar.compare(date, to: today, toGranularity: .day) == .orderedAscending
    }
    
    var body: some View {
        Text("\(day)")
            .font(.caption)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Group {
                    if isEndpoint {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("calendarHighlightTile"))
                            .frame(width: 40, height: 40)
                    } else if isInRange {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("calendarSelectedTile"))
                            .frame(width: 40, height: 40)
                    } else {
                        Color.clear
                    }
                }
            )
            .foregroundColor(
                isEndpoint ? .white :
                    (isInRange ? .primary :
                        (isPastDate ? .gray : Color("numberColor")))
            )
            .opacity(isPastDate ? 0.5 : 1.0)
            .contentShape(Rectangle()) // Make entire cell tappable
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        selectedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    private func isDateEndpoint(_ date: Date) -> Bool {
        guard !selectedDates.isEmpty else { return false }
        
        if selectedDates.count == 1 {
            return calendar.isDate(date, inSameDayAs: selectedDates[0])
        }
        
        return calendar.isDate(date, inSameDayAs: selectedDates.first!) ||
               calendar.isDate(date, inSameDayAs: selectedDates.last!)
    }
    
    private func isDateInRange(_ date: Date) -> Bool {
        guard selectedDates.count >= 2,
              let firstDate = selectedDates.first,
              let lastDate = selectedDates.last else {
            return false
        }
        
        return calendar.compare(date, to: firstDate, toGranularity: .day) != .orderedAscending &&
               calendar.compare(date, to: lastDate, toGranularity: .day) != .orderedDescending &&
               !calendar.isDate(date, inSameDayAs: firstDate) &&
               !calendar.isDate(date, inSameDayAs: lastDate)
    }
}

// MARK: - DateAndTime
struct DateAndTime: View {
    @Binding var showTimePicker: Bool
    @Binding var selectedTime: Date
    @Binding var timeSelection: Bool
    let selectedDates: [Date]
    let isFirst: Bool
    let label: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .foregroundColor(.gray)
                .font(.caption)
            
            if isFirst {
                Text(CalendarFormatting.formattedDate(selectedDates.first))
                    .font(.headline)
            } else {
                Text(selectedDates.count > 1 ? CalendarFormatting.formattedDate(selectedDates.last) : "MMM DD, YYYY")
                    .font(.headline)
            }
            
            if timeSelection {
                Text(CalendarFormatting.formattedTime(selectedTime))
                    .font(.subheadline)
            }
        }
        .onTapGesture {
            showTimePicker = true
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .sheet(isPresented: $showTimePicker) {
            TimePickerView(selectedTime: $selectedTime, showTimePicker: $showTimePicker)
        }
    }
}

// MARK: - TimePickerView
struct TimePickerView: View {
    @Binding var selectedTime: Date
    @Binding var showTimePicker: Bool
    
    var body: some View {
        VStack {
            DatePicker(
                "Select Time",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .padding()
            
            Button("Done") {
                showTimePicker = false
            }
            .padding()
        }
        .presentationDetents([.height(250)])
    }
}

// MARK: - ApplyButton
struct ApplyButton: View {
    var body: some View {
        Text("Apply")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 253/255, green: 104/255, blue: 14/255, opacity: 1.0),
                    Color(red: 218/255, green: 69/255, blue: 1/255, opacity: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .cornerRadius(8)
    }
}

// MARK: - Previews
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
