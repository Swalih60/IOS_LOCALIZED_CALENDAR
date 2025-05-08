import SwiftUI

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

// MARK: - CalendarView
struct CalendarView: View {
    // MARK: - Properties
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    // MARK: - State
    @State private var dateSelection = DateSelection()
    @State private var currentMonth = Date()
    @State private var showingMonths = 12
    
    //turn this to false to remove time selection
    @State private var timeSelection: Bool = true
    @State private var departureTime = Date()
    @State private var showDepartureTimePicker: Bool = false
    @State private var returnTime = Date()
    @State private var showReturnTimePicker: Bool = false
    
    //turn this to false for single Date
    @State private var singleDate:Bool = true
    
    // MARK: - Computed Properties
    private var selectedDates: [Date] {
        dateSelection.selectedDates
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with back button
//                headerView
                
                // Sticky weekday header
                weekdayHeaderView
                
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
        }
    }
    
    // MARK: - View Components
//    private var headerView: some View {
//        HStack {
//            Button(action: {
//                // Go back action
//            }) {
//                Image(systemName: "chevron.left")
//                    .foregroundColor(.blue)
//                    .font(.title2)
//            }
//            .padding()
//
//            Text("Select Date")
//                .font(.title3)
//                .fontWeight(.bold)
//                .foregroundColor(Color("calendarColor"))
//
//            Spacer()
//        }
//        .padding(.bottom, 20)
//    }
    
    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.regular)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color("calendarColor"))
            }
        }
        .padding(.bottom, 30)
        .background(Color.white)
        .zIndex(1)
    }
    
    private var calendarScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(0..<showingMonths, id: \.self) { monthOffset in
                    if let date = calendar.date(byAdding: .month, value: monthOffset, to: currentMonth) {
                        MonthView(
                            month: date,
                            dateSelection: $dateSelection,
                            calendar: calendar,
                            singleDateMode: !singleDate
                            
                        )
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
                
                if singleDate{  DateAndTime(
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
}

// MARK: - MonthView
struct MonthView: View {
    let month: Date
    @Binding var dateSelection: DateSelection
    let calendar: Calendar
    let singleDateMode: Bool
    
    // Cache computed values
    private let monthStart: Date
    private let monthOnly: String
    private let yearOnly: String
    private let daysInMonth: Int
    private let adjustedFirstWeekday: Int
    
    init(month: Date, dateSelection: Binding<DateSelection>, calendar: Calendar, singleDateMode: Bool = false) {
        self.month = month
        self._dateSelection = dateSelection
        self.calendar = calendar
        
        // Pre-compute values
        self.monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        self.monthOnly = month.formatted(.dateTime.month(.wide))
        self.yearOnly = month.formatted(.dateTime.year())
        self.daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        self.adjustedFirstWeekday = (firstWeekday + 5) % 7 // Adjusting to make Monday = 0, Sunday = 6
        self.singleDateMode = singleDateMode
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
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
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                // Empty cells for days before the first of month
                ForEach(0..<adjustedFirstWeekday, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
                
                // Days of the month
                ForEach(1...daysInMonth, id: \.self) { day in
                    if let currentDate = calendar.date(from: DateComponents(
                        year: calendar.component(.year, from: monthStart),
                        month: calendar.component(.month, from: monthStart),
                        day: day
                    )) {
                        DayCell(
                            date: currentDate,
                            selectedDates: dateSelection.selectedDates,
                            calendar: calendar
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
    
    private func isPastDate(_ date: Date) -> Bool {
        calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }
    
    private func handleDateSelection(_ date: Date) {
        if singleDateMode {
                // Single date mode - always just select one date
                dateSelection.selectedDates = [date]
                dateSelection.selectionState = .firstDateSelected
            }
        else{
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
        
        while currentDate <= endDate {
            // Skip past dates
            if calendar.compare(currentDate, to: Date(), toGranularity: .day) != .orderedAscending {
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
    let selectedDates: [Date]
    let calendar: Calendar
    
    private var day: Int {
        calendar.component(.day, from: date)
    }
    
    private var isEndpoint: Bool {
        isDateEndpoint(date)
    }
    
    private var isInRange: Bool {
        isDateInRange(date)
    }
    
    private var isPastDate: Bool {
        calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
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
        guard selectedDates.count >= 2 else {
            return isDateSelected(date)
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

// MARK: - Helper Functions
func formattedDate(_ date: Date?) -> String {
    guard let date = date else { return "MMM DD, YYYY" }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
}

func formattedTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
}

// MARK: - DateAndTime it is a component used in the footer which has the date and time
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
                Text(formattedDate(selectedDates.first))
                    .font(.headline)
            } else {
                Text(selectedDates.count > 1 ? formattedDate(selectedDates.last) : "MMM DD, YYYY")
                    .font(.headline)
            }
            
            if timeSelection {
                Text(formattedTime(selectedTime))
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

// MARK: - TimePickerView component used in date and time
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
