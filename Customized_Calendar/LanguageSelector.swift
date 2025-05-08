import SwiftUI

// MARK: - Language Selector Button
struct LanguageSelectorView: View {
    @ObservedObject var localizationManager: CalendarLocalizationManager
    @State private var isPickerShowing = false
    
    var body: some View {
        Button(action: {
            isPickerShowing = true
        }) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(Color("calendarColor"))
                Text(localizationManager.currentLanguage)
                    .font(.caption)
                    .foregroundColor(Color("calendarColor"))
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(Color("calendarColor"))
            }
            .padding(8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
        .sheet(isPresented: $isPickerShowing) {
            LanguagePickerView(
                localizationManager: localizationManager,
                isPresented: $isPickerShowing
            )
        }
    }
}

// MARK: - Compact Language Selector (Icon Only)
struct CompactLanguageSelectorView: View {
    @ObservedObject var localizationManager: CalendarLocalizationManager
    @State private var isPickerShowing = false
    
    var body: some View {
        Button(action: {
            isPickerShowing = true
        }) {
            Image(systemName: "globe")
                .font(.title3)
                .foregroundColor(Color("calendarColor"))
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .clipShape(Circle())
        }
        .sheet(isPresented: $isPickerShowing) {
            LanguagePickerView(
                localizationManager: localizationManager,
                isPresented: $isPickerShowing
            )
        }
    }
}

// MARK: - Language Picker Sheet
struct LanguagePickerView: View {
    @ObservedObject var localizationManager: CalendarLocalizationManager
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var filteredLanguages: [LanguageOption] {
        if searchText.isEmpty {
            return localizationManager.availableLanguages
        } else {
            return localizationManager.availableLanguages.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredLanguages) { language in
                    Button(action: {
                        localizationManager.currentLanguage = language.code
                        isPresented = false
                    }) {
                        HStack {
                            Text(language.name)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if localizationManager.currentLanguage == language.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Languages")
            .navigationTitle("Select Language")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview
struct LanguageSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            LanguageSelectorView(localizationManager: CalendarLocalizationManager())
            CompactLanguageSelectorView(localizationManager: CalendarLocalizationManager())
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
