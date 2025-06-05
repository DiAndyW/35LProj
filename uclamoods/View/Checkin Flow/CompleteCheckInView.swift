import SwiftUI
import CoreLocation
import Combine

// Keyboard height observer
class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            }
            .map { $0.height }
            .sink { [weak self] height in
                DispatchQueue.main.async {
                    self?.currentHeight = height
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.currentHeight = 0
                }
            }
            .store(in: &cancellables)
    }
}


extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct MockUser: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct ActivityTag: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var isCustom: Bool = false
}

struct PillTagView: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.custom("Chivo", size: 14))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.gray.opacity(0.3))
                .cornerRadius(20)
        }
    }
}

struct AddTagButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(0.3))
                .clipShape(Circle())
        }
    }
}

struct SocialTagSectionView: View {
    @Binding var selectedTags: Set<String>
    let predefinedTags: [String]
    
    @State private var newTagText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // Profanity Filter and Toast State
    @StateObject private var profanityFilter = ProfanityFilterService() // Assuming ProfanityFilterService is defined
    @State private var showProfanityToast: Bool = false
    @State private var toastMessage: String = ""
    
    private var customSelectedTags: [String] {
        selectedTags.filter { !predefinedTags.contains($0) }.sorted()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Who were you with")
                .font(.custom("Georgia", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Predefined Tags
                    ForEach(predefinedTags, id: \.self) { tag in
                        PillTagView(text: tag, isSelected: selectedTags.contains(tag)) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                            isTextFieldFocused = false
                        }
                    }
                    
                    // Custom selected tags
                    ForEach(customSelectedTags, id: \.self) { tag in
                        PillTagView(text: tag, isSelected: true) {
                            selectedTags.remove(tag)
                            isTextFieldFocused = false
                        }
                    }
                    
                    // "Input Pill" TextField
                    TextField("+ Add tag", text: $newTagText)
                        .font(.custom("Chivo", size: 14))
                        .foregroundColor(newTagText.isEmpty ? Color.white.opacity(0.6) : .white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                        .frame(minWidth: 100, idealWidth: 100)
                        .focused($isTextFieldFocused)
                        .onSubmit { addCustomTagFromInput() }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isTextFieldFocused ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                }
                .padding(.vertical, 5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            if isTextFieldFocused { isTextFieldFocused = false }
        }
        .toast(isShowing: $showProfanityToast, message: toastMessage, type: .error) // Assuming .toast modifier is defined
    }
    
    private func addCustomTagFromInput() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty {
            if profanityFilter.isContentAcceptable(text: trimmedTag) {
                selectedTags.insert(trimmedTag)
                newTagText = ""
                // isTextFieldFocused = true // Optionally keep focus
            } else {
                toastMessage = "This tag contains offensive language."
                showProfanityToast = true
                // Do not add the tag, newTagText can remain for user to edit
            }
        }
    }
}

struct EmotionHeaderView: View {
    let emotion: Emotion // Assuming Emotion struct is defined
    let timeFormatter: DateFormatter
    let currentDisplayLocation: String
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            FloatingBlobButton( // Assuming FloatingBlobButton is defined
                text: "",
                size: 600,
                fontSize: 50,
                morphSpeed: 0.2,
                floatSpeed: 0.05,
                colorShiftSpeed: 2.0,
                movementRange: 0.05,
                colorPool: [emotion.color],
                isSelected: false,
                action: {}
            )
            VStack {
                Text(emotion.name)
                    .font(.custom("Georgia", size: 50))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(timeFormatter.string(from: Date()))
                    .font(.custom("Chivo", size: 20))
                    .foregroundColor(.white)
                    .offset(y: geometry.size.width * 0.01)
                
                Text(currentDisplayLocation)
                    .font(.custom("Chivo", size: 20))
                    .foregroundColor(.white)
                    .offset(y: geometry.size.width * 0.01)
                    .padding(.horizontal, 100)
            }
            .offset(y: geometry.size.width * 0.35)
        }
    }
}

struct PrivacyOptionsView: View {
    @Binding var selectedPrivacy: CompleteCheckInView.PrivacySetting
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Share with:")
                .font(.custom("Georgia", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Picker("Privacy", selection: $selectedPrivacy) {
                ForEach(CompleteCheckInView.PrivacySetting.allCases) { setting in
                    Text(setting.rawValue).tag(setting)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

struct LocationOptionsView: View {
    @Binding var showLocation: Bool
    @Binding var currentLocation: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Share Location?")
                .font(.custom("Georgia", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: showLocation ? "location.fill" : "location.slash.fill")
                    .foregroundColor(showLocation ? accentColor : .gray)
                Text(showLocation ? currentLocation : "Location hidden")
                    .font(.custom("Chivo", size: 16))
                    .foregroundColor(.white.opacity(showLocation ? 1.0 : 0.7))
                Spacer()
                Toggle("", isOn: $showLocation)
                    .labelsHidden()
                    .tint(accentColor)
            }
            .padding(.vertical, 5)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ReasonInputSectionView: View {
    @Binding var reasonText: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    let accentColor: Color
    let maxCharacterLimit = 300
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Why do you feel this way?")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.16))
                    )
                    .shadow(color: .white.opacity(0.1), radius: 5, x: 0, y: 0)
                
                TextField("Share your thoughts...", text: $reasonText, axis: .vertical)
                    .font(.custom("Roberto", size: 16)) // Ensure font "Roberto" is available
                    .foregroundColor(.white)
                    .accentColor(accentColor)
                    .padding(20)
                    .lineLimit(5...10)
                    .focused(isTextFieldFocused)
                    .onTapGesture {
                        isTextFieldFocused.wrappedValue = true
                    }
                    .onChange(of: reasonText) { newValue in // Using original onChange syntax
                        guard let newValueLastChar = newValue.last else { return }
                        if newValueLastChar == "\n" {
                            reasonText.removeLast()
                            hideKeyboard()
                        }
                        
                        if newValue.count > maxCharacterLimit {
                            reasonText = String(newValue.prefix(maxCharacterLimit))
                        }
                    }
                    .submitLabel(.done)
                    .onSubmit {
                        print("➡️ ReasonInputSectionView: .onSubmit triggered.")
                        print("   Before change: isTextFieldFocused.wrappedValue = \(isTextFieldFocused.wrappedValue)")
                        print("   Current reasonText before potential change: '\(reasonText)'")
                        
                        isTextFieldFocused.wrappedValue = false
                        
                        print("   After change: isTextFieldFocused.wrappedValue = \(isTextFieldFocused.wrappedValue)")
                    }
                
                Text("\(reasonText.count)/\(maxCharacterLimit)")
                    .font(.custom("Roberto", size: 14)) // Ensure font "Roberto" is available
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 30)
                    .padding(.top, 100)
            }
            .frame(height: 120)
            .padding(.horizontal, 20)
            .padding(.top, 5)
            .padding(.bottom, 30)
        }
    }
}

struct SaveCheckInButtonView: View {
    let geometry: GeometryProxy
    let action: () -> Void
    let isSaving: Bool
    let saveError: String?
    let isDisabled: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(height: 50)
            } else {
                HStack{
                    Spacer()
                    Button(action: action) {
                        Text("Save Check-in")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isDisabled ? .gray : .black)
                            .frame(width: geometry.size.width * 0.8, height: 50)
                            .background(isDisabled ? Color.white.opacity(0.5) : Color.white)
                            .cornerRadius(25)
                            .shadow(radius: 5)
                    }
                    .disabled(isDisabled)
                    Spacer()
                }
            }
            if let errorMsg = saveError, !isSaving {
                Text(errorMsg)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
        }
        .padding(.bottom, 50)
    }
}

struct CheckInFormView: View {
    @Binding var reasonText: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    
    @Binding var selectedSocialTags: Set<String>
    let predefinedSocialTags: [String]
    
    @Binding var selectedPrivacy: CompleteCheckInView.PrivacySetting
    @Binding var showLocation: Bool
    @Binding var currentLocation: String
    
    let emotion: Emotion
    let geometry: GeometryProxy
    
    @Binding var isSaving: Bool
    @Binding var saveError: String?
    @Binding var isLocationLoading: Bool
    
    let saveAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SocialTagSectionView(
                selectedTags: $selectedSocialTags,
                predefinedTags: predefinedSocialTags
            )
            
            ReasonInputSectionView(
                reasonText: $reasonText,
                isTextFieldFocused: isTextFieldFocused,
                accentColor: emotion.color
            )
            
            PrivacyOptionsView(selectedPrivacy: $selectedPrivacy)
            
            LocationOptionsView(
                showLocation: $showLocation,
                currentLocation: $currentLocation,
                accentColor: emotion.color
            )
            
            SaveCheckInButtonView(
                geometry: geometry,
                action: saveAction,
                isSaving: isSaving,
                saveError: saveError,
                isDisabled: shouldDisableSaveButton() // Using original helper
            )
        }
    }
    
    private func shouldDisableSaveButton() -> Bool {
        let isReasonEmpty = reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isLocationPending = showLocation && isLocationLoading
        return isReasonEmpty || isLocationPending
    }
}

struct CompleteCheckInView: View {
    @EnvironmentObject private var router: MoodAppRouter // Assuming MoodAppRouter is defined
    @EnvironmentObject private var userDataProvider: UserDataProvider // Assuming UserDataProvider is defined
    
    @State private var reasonText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var selectedSocialTags: Set<String> = []
    @State private var predefinedSocialTags: [String] = [
        "Friends", "Family", "By Myself"
    ]
    
    @StateObject private var profanityFilter = ProfanityFilterService() // Assuming ProfanityFilterService is defined
    @State private var showProfanityToast: Bool = false
    @State private var toastMessage: String = ""
    
    @State private var selectedActivities: Set<ActivityTag> = []
    @State private var predefinedActivities: [ActivityTag] = [ // Original predefined activities
        ActivityTag(name: "Driving"), ActivityTag(name: "Resting"), ActivityTag(name: "Hobbies"),
        ActivityTag(name: "Fitness"), ActivityTag(name: "Hanging Out"), ActivityTag(name: "Eating"),
        ActivityTag(name: "Work"), ActivityTag(name: "Studying")
    ]
    @State private var customActivityText: String = ""
    @State private var showingAddCustomActivityField = false
    
    @StateObject private var keyboardResponder = KeyboardResponder()
    
    enum PrivacySetting: String, CaseIterable, Identifiable {
        case isPublic = "Public"
        case isPrivate = "Private"
        var id: String { self.rawValue }
    }
    @State private var selectedPrivacy: PrivacySetting = .isPublic
    
    // MARK: - Location State
    @State private var showLocation: Bool = true
    @StateObject private var locationManager = LocationManager() // Assuming LocationManager is defined
    @State private var displayableLocationName: String = "Fetching location..."
    
    let emotion: Emotion // Assuming Emotion struct is defined
    
    // MARK: - Saving State
    @State private var isSaving: Bool = false
    @State private var saveError: String? = nil
    @State private var showSaveSuccessAlert: Bool = false
    
    // MARK: - Formatters
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                EmotionHeaderView(
                                    emotion: emotion,
                                    timeFormatter: timeFormatter,
                                    currentDisplayLocation: getFormattedLocationForHeader(),
                                    geometry: geometry
                                )
                                .padding(.bottom, 30)
                                .offset(x: -geometry.size.width * 0, y: -geometry.size.height * 0.48)
                                
                                CheckInFormView(
                                    reasonText: $reasonText,
                                    isTextFieldFocused: $isTextFieldFocused,
                                    selectedSocialTags: $selectedSocialTags,
                                    predefinedSocialTags: predefinedSocialTags,
                                    selectedPrivacy: $selectedPrivacy,
                                    showLocation: $showLocation,
                                    currentLocation: $displayableLocationName,
                                    emotion: emotion,
                                    geometry: geometry,
                                    isSaving: $isSaving,
                                    saveError: $saveError,
                                    isLocationLoading: .constant(locationManager.isLoading),
                                    saveAction: saveCheckIn
                                )
                                .padding(.top, -geometry.size.height * 0.56)
                                .padding(.horizontal, geometry.size.width * 0.24)
                                .id("formView") // Add ID for ScrollViewReader
                                
                                // Add invisible spacer that expands when keyboard appears
                                Color.clear
                                    .frame(height: keyboardResponder.currentHeight > 0 ? keyboardResponder.currentHeight * 0.4 : 0)
                                    .animation(.easeOut(duration: 0.25), value: keyboardResponder.currentHeight)
                            }
                            .ignoresSafeArea(edges: .top)
                            .onTapGesture {
                                isTextFieldFocused = false
                            }
                            .offset(y: -geometry.size.width * 0.0)
                            .offset(x: -geometry.size.width * 0.25)
                        }
                        .scrollDisabled(keyboardResponder.currentHeight == 0) // Disable scrolling when keyboard is hidden
                        .onChange(of: isTextFieldFocused) { focused in
                            if focused {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("formView", anchor: .center)
                                }
                            }
                        }
                    }
                    
                    VStack {
                        HStack {
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.prepare()
                                impactFeedback.impactOccurred()
                                router.navigateBackInMoodFlow(from: CGPoint(x: UIScreen.main.bounds.size.width * 0.1, y: UIScreen.main.bounds.size.height * 0.0))
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                            .padding(.leading, 25)
                            .padding(.top, -geometry.size.height * 0.02)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
        .toast(isShowing: $showProfanityToast, message: toastMessage, type: .error)
        .alert("Success!", isPresented: $showSaveSuccessAlert) {
            Button("OK", role: .cancel) {
                router.navigateToMainApp()
            }
        } message: {
            Text("Your check-in has been saved successfully.")
        }
        .onAppear {
            if showLocation {
                displayableLocationName = "Fetching location..."
                locationManager.requestLocationAccessIfNeeded()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    locationManager.fetchCurrentLocationAndLandmark()
                }
            } else {
                displayableLocationName = "Location Hidden"
            }
        }
        .onChange(of: showLocation) { newShowValue in
            if newShowValue {
                displayableLocationName = "Fetching location..."
                locationManager.fetchCurrentLocationAndLandmark()
            } else {
                displayableLocationName = "Location Hidden"
                locationManager.stopUpdatingMapLocation()
            }
        }
        .onChange(of: locationManager.landmarkName) { newLandmark in
            updateDisplayableLocationName(landmark: newLandmark, coordinates: locationManager.userCoordinates, isLoading: locationManager.isLoading)
        }
        .onChange(of: locationManager.userCoordinates) { newCoordinates in
            updateDisplayableLocationName(landmark: locationManager.landmarkName, coordinates: newCoordinates, isLoading: locationManager.isLoading)
        }
        .onChange(of: locationManager.isLoading) { newIsLoading in
            updateDisplayableLocationName(landmark: locationManager.landmarkName, coordinates: locationManager.userCoordinates, isLoading: newIsLoading)
        }
        .onChange(of: locationManager.authorizationStatus) { newStatus in
            print("Auth status changed to: \(newStatus)")
            if newStatus == .denied || newStatus == .restricted {
                displayableLocationName = "Location access needed"
            } else if newStatus == .authorizedAlways || newStatus == .authorizedWhenInUse {
                if showLocation && locationManager.userCoordinates == nil {
                    locationManager.fetchCurrentLocationAndLandmark()
                }
            }
        }
    }
    
    // MARK: - Helper Methods (Original versions)
    private func getFormattedLocationForHeader() -> String {
        if !showLocation {
            return "Location Hidden"
        }
        if displayableLocationName.isEmpty || displayableLocationName == "Fetching location..." || displayableLocationName == "Location unavailable" {
            return displayableLocationName
        }
        return "@ \(displayableLocationName)"
    }
    
    private func updateDisplayableLocationName(landmark: String?, coordinates: CLLocationCoordinate2D?, isLoading: Bool) {
        if isLoading {
            displayableLocationName = "Fetching location..."
            return
        }
        if let name = landmark, !name.isEmpty {
            displayableLocationName = name
        } else if coordinates != nil {
            displayableLocationName = "Near your current location"
        } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
            displayableLocationName = "Location access needed"
        }
        else {
            displayableLocationName = "Location unavailable"
        }
    }
    
    // MARK: - saveCheckIn (MODIFIED LOGIC)
    private func saveCheckIn() {
        isSaving = true
        saveError = nil
        showSaveSuccessAlert = false
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        let trimmedReasonText = self.reasonText.trimmingCharacters(in: .whitespacesAndNewlines)
        let customSocialTags = selectedSocialTags.filter { !predefinedSocialTags.contains($0) }
        let customActivityNames = selectedActivities.filter { $0.isCustom }.map { $0.name }
        
        // --- PROFANITY CHECKS ---
        if !profanityFilter.isContentAcceptable(text: trimmedReasonText) {
            isSaving = false
            toastMessage = "Your reason contains offensive language."
            showProfanityToast = true
            return
        }
        if !customSocialTags.allSatisfy({ profanityFilter.isContentAcceptable(text: $0) }) {
            isSaving = false
            toastMessage = "A social tag contains offensive language."
            showProfanityToast = true
            return
        }
        if !customActivityNames.allSatisfy({ profanityFilter.isContentAcceptable(text: $0) }) {
            isSaving = false
            toastMessage = "A custom activity contains offensive language."
            showProfanityToast = true
            return
        }
        
        // MODIFIED SECTION FOR LOCATION HANDLING
        let finalLandmarkName: String?
        let finalCoordinates: CLLocationCoordinate2D?
        let finalShowLocationFlag: Bool
        
        if self.showLocation && self.locationManager.userCoordinates != nil {
            // User wants to show location AND coordinates are available
            finalCoordinates = self.locationManager.userCoordinates
            finalLandmarkName = self.locationManager.landmarkName // This could be nil if landmark isn't found, which is acceptable for the backend if coordinates are present.
            finalShowLocationFlag = true
        } else {
            // User either chose to hide location (self.showLocation is false), OR
            // self.showLocation is true BUT self.locationManager.userCoordinates is nil (e.g. permissions denied, error fetching)
            // In these cases, the entire location object should be treated as null/hidden for the backend.
            finalCoordinates = nil
            finalLandmarkName = nil
            finalShowLocationFlag = false
        }
        
        // Original print statement, updated to use resolved values
        print("Saving CheckIn - Landmark: \(finalLandmarkName ?? "nil"), Coords: \(String(describing: finalCoordinates)), ShowLocation (to service): \(finalShowLocationFlag)")
        
        Task {
            do {
                // Assuming CheckInService and its error types are defined elsewhere
                let response = try await CheckInService.createCheckIn(
                    emotion: self.emotion,
                    reasonText: trimmedReasonText,
                    socialTags: self.selectedSocialTags,
                    selectedActivities: self.selectedActivities,
                    landmarkName: finalLandmarkName,         // Use the resolved landmark name
                    userCoordinates: finalCoordinates,       // Use the resolved coordinates
                    showLocation: finalShowLocationFlag,     // Use the resolved show location flag
                    privacySetting: self.selectedPrivacy,
                    userDataProvider: self.userDataProvider
                )
                
                await MainActor.run {
                    isSaving = false
                    print("Save successful: \(response.message)") // Assuming response has a message
                    showSaveSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    if let serviceError = error as? CheckInServiceError { // Assuming CheckInServiceError is defined
                        saveError = serviceError.errorDescription ?? "An unknown error occurred."
                    } else {
                        saveError = error.localizedDescription
                    }
                    print("Failed to save check-in: \(String(describing: saveError))")
                }
            }
        }
    }
}

struct UpdatedCompleteCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        // Assuming Emotion, EmotionDataProvider, MoodAppRouter, UserDataProvider are defined elsewhere
        // and work as intended for the preview.
        CompleteCheckInView(emotion: EmotionDataProvider.highEnergyEmotions[3])
            .environmentObject(MoodAppRouter())
            .environmentObject(UserDataProvider.shared)
            .preferredColorScheme(.dark)
    }
}
