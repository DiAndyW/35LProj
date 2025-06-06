import SwiftUI
import FluidGradient
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


extension CLLocationCoordinate2D: @retroactive Equatable {
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
    let currentLocation: String
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
                    .onChange(of: reasonText) {
                        if reasonText.contains("\n") {
                            reasonText = reasonText.replacingOccurrences(of: "\n", with: "")
                            hideKeyboard()
                        }
                        if reasonText.count > maxCharacterLimit {
                            reasonText = String(reasonText.prefix(maxCharacterLimit))
                        }
                    }
                    .submitLabel(.done)
                    .onSubmit {
                        print("   ReasonInputSectionView: .onSubmit triggered.")
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
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    let currentLocation: String
    
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
                currentLocation: currentLocation,
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
    @EnvironmentObject var locationManager: LocationManager
    
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
    @State private var displayableLocationName: String = "Fetching location..."
    
    let emotion: Emotion // Assuming Emotion struct is defined
    
    // MARK: - Saving State
    @State private var isSaving: Bool = false
    @State private var saveError: String? = nil
    @State private var showSaveSuccessAlert: Bool = false
    
    struct LocationState: Equatable {
        let isLoading: Bool
        let landmarkName: String?
        let coordinates: CLLocationCoordinate2D?
        let authStatus: CLAuthorizationStatus
    }
    
    private var currentDisplayLocation: String {
        if !showLocation {
            return "Location Hidden"
        }
        
        if locationManager.isLoading {
            return "Fetching location..."
        }
        
        if let name = locationManager.landmarkName, !name.isEmpty {
            return name
        }
        
        if locationManager.userCoordinates != nil {
            return "Near your current location"
        }
        
        switch locationManager.authorizationStatus {
            case .denied, .restricted:
                return "Location access needed"
            default:
                return "Location unavailable"
        }
    }
    
    // MARK: - Formatters
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: geometry.safeAreaInsets.top + 60)
                        
                        VStack {
                            Text(emotion.name)
                                .font(.custom("Georgia", size: 40, relativeTo: .largeTitle))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 5)
                            
                            Text(timeFormatter.string(from: Date()))
                                .font(.custom("Chivo", size: 18, relativeTo: .headline))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.2), radius: 3)
                            
                            Text(getFormattedLocationForHeader())
                                .font(.custom("Chivo", size: 18, relativeTo: .headline))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .padding(.horizontal)
                                .shadow(color: .black.opacity(0.2), radius: 3)
                        }
                        .padding(.bottom, 30)
                        
                        CheckInFormView(
                            reasonText: $reasonText,
                            isTextFieldFocused: $isTextFieldFocused,
                            selectedSocialTags: $selectedSocialTags,
                            predefinedSocialTags: predefinedSocialTags,
                            selectedPrivacy: $selectedPrivacy,
                            showLocation: $showLocation,
                            currentLocation: currentDisplayLocation,
                            emotion: emotion,
                            geometry: geometry,
                            isSaving: $isSaving,
                            saveError: $saveError,
                            isLocationLoading: .constant(locationManager.isLoading),
                            saveAction: saveCheckIn
                        )
                    }
                    .padding(.horizontal)
                }
                .scrollContentBackground(.hidden)
                .padding(.bottom, keyboardResponder.currentHeight > 0 ? keyboardResponder.currentHeight - geometry.safeAreaInsets.bottom : 0)
                .animation(.easeOut(duration: 0.25), value: keyboardResponder.currentHeight)
                
                VStack {
                    HStack {
                        Button(action: {
                            router.navigateBackInMoodFlow(from: .zero)
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.leading)
                    .padding(.top, geometry.safeAreaInsets.top)
                    Spacer()
                }
            }
            .background(
                FloatingBlobButton(
                    text: "",
                    size: geometry.size.width * 2,
                    fontSize: 0,
                    morphSpeed: 0.2,
                    floatSpeed: 0.05,
                    colorShiftSpeed: 0.1,
                    movementRange: 0.05,
                    colorPool: [emotion.color],
                    isSelected: false,
                    action: {}
                )
                .blur(radius: 60)
                .position(x: geometry.size.width / 2, y: 0)
                    .ignoresSafeArea()
            )
            .background(.black)
            .ignoresSafeArea()
            .navigationBarHidden(true)
            .onTapGesture {
                isTextFieldFocused = false
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
                    locationManager.requestLocationAccessIfNeeded()
                    locationManager.fetchCurrentLocationAndLandmark()
                }
            }
            .onChange(of: showLocation) {
                if showLocation {
                    locationManager.fetchCurrentLocationAndLandmark()
                } else {
                    locationManager.stopUpdatingMapLocation()
                }
            }
        }
    }
    
    private func getFormattedLocationForHeader() -> String {
        let location = currentDisplayLocation
        if location.isEmpty || location == "Fetching location..." || location == "Location unavailable" || location == "Location Hidden" || location == "Location access needed" {
            return location
        }
        return "@ \(location)"
    }
    
    private func updateDisplayableLocationName(with state: LocationState) {
        if state.isLoading {
            self.displayableLocationName = "Fetching location..."
            return
        }
        
        if let name = state.landmarkName, !name.isEmpty {
            self.displayableLocationName = name
        } else if state.coordinates != nil {
            self.displayableLocationName = "Near your current location"
        } else if state.authStatus == .denied || state.authStatus == .restricted {
            self.displayableLocationName = "Location access needed"
        } else {
            self.displayableLocationName = "Location unavailable"
        }
    }
    
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
                    router.homeFeedNeedsRefresh.send()
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
