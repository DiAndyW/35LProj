import SwiftUI
import CoreLocation

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

    // Helper to get sorted custom tags that are already selected
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
                            // Dismiss keyboard if a predefined tag is tapped
                            isTextFieldFocused = false
                        }
                    }

                    // Custom selected tags (already added)
                    ForEach(customSelectedTags, id: \.self) { tag in
                        PillTagView(text: tag, isSelected: true) { // These are always "selected" as they are from the selectedTags set
                            selectedTags.remove(tag) // Action is to remove
                            isTextFieldFocused = false // Dismiss keyboard
                        }
                    }

                    // "Input Pill" TextField
                    TextField("+ Add tag", text: $newTagText)
                        .font(.custom("Chivo", size: 14))
                        // Dynamic foreground color: placeholder is dimmer, input text is brighter
                        .foregroundColor(newTagText.isEmpty ? Color.white.opacity(0.6) : .white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.3)) // Pill background
                        .cornerRadius(20) // Pill corner radius
                        .frame(minWidth: 100, idealWidth: 100) // Give it some initial width, can expand
                        .focused($isTextFieldFocused)
                        .onSubmit { // Called when Return key is pressed
                            addCustomTagFromInput()
                        }
                        // Add a subtle border to the input pill if it's focused
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isTextFieldFocused ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                }
                .padding(.vertical, 5) // Padding for the HStack content within ScrollView
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        // Tapping the VStack background will dismiss the keyboard
        .contentShape(Rectangle()) // Ensure the whole VStack area is tappable
        .onTapGesture {
            if isTextFieldFocused { // Only dismiss if the text field was focused
                 isTextFieldFocused = false
            }
        }
    }

    private func addCustomTagFromInput() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty {
            selectedTags.insert(trimmedTag)
            newTagText = "" // Clear the input field, making it "blank" for the next tag
            // Optionally, you might want to keep the TextField focused for rapid entry:
            // isTextFieldFocused = true
        }
    }
}

struct EmotionHeaderView: View {
    let emotion: Emotion
    let timeFormatter: DateFormatter
    let currentDisplayLocation: String
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            FloatingBlobButton(
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
                    .padding(.horizontal, 200)
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

struct ReasonInputSectionView: View {
    @Binding var reasonText: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    let accentColor: Color
    let maxCharacterLimit = 300 // Add this constant
    
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
                    .font(.custom("Roberto", size: 16))
                    .foregroundColor(.white)
                    .accentColor(accentColor)
                    .padding(20)
                    .lineLimit(5...10)
                    .focused(isTextFieldFocused)
                    .onTapGesture {
                        isTextFieldFocused.wrappedValue = true
                    }
                    .onChange(of: reasonText) { newValue in
                        if newValue.count > maxCharacterLimit {
                            reasonText = String(newValue.prefix(maxCharacterLimit))
                        }
                    }
                
                Text("\(reasonText.count)/\(maxCharacterLimit)") // Update to use the constant
                    .font(.custom("Roberto", size: 14))
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
    let isDisabled: Bool // Add this property
    
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
                            .foregroundColor(isDisabled ? .gray : .black) // Change text color when disabled
                            .frame(width: geometry.size.width * 0.8, height: 50)
                            .background(isDisabled ? Color.white.opacity(0.5) : Color.white) // Change background when disabled
                            .cornerRadius(25)
                            .shadow(radius: 5)
                    }
                    .disabled(isDisabled) // Disable button when condition is met
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
    
    // Updated properties for social tags
    @Binding var selectedSocialTags: Set<String>
    let predefinedSocialTags: [String]
    
    @Binding var selectedPrivacy: CompleteCheckInView.PrivacySetting
    @Binding var showLocation: Bool
    @Binding var currentLocation: String
    
    let emotion: Emotion // Assuming Emotion struct is defined elsewhere
    let geometry: GeometryProxy
    
    @Binding var isSaving: Bool
    @Binding var saveError: String?
    
    let saveAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SocialTagSectionView(
                selectedTags: $selectedSocialTags,       // Pass the Set<String> binding
                predefinedTags: predefinedSocialTags   // Pass the [String]
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
                isDisabled: reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }
}

struct CompleteCheckInView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    @State private var reasonText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var selectedSocialTags: Set<String> = []
    @State private var predefinedSocialTags: [String] = [
        "Friends", "Family", "By Myself"
    ]
    
    @State private var selectedActivities: Set<ActivityTag> = []
    @State private var predefinedActivities: [ActivityTag] = [
        ActivityTag(name: "Driving"), ActivityTag(name: "Resting"), ActivityTag(name: "Hobbies"),
        ActivityTag(name: "Fitness"), ActivityTag(name: "Hanging Out"), ActivityTag(name: "Eating"),
        ActivityTag(name: "Work"), ActivityTag(name: "Studying")
    ]
    @State private var customActivityText: String = ""
    @State private var showingAddCustomActivityField = false
    
    enum PrivacySetting: String, CaseIterable, Identifiable {
            //case friends = "Friends"
            case isPublic = "Public" // Consider renaming to "public" to avoid "is" prefix if not boolean
            case isPrivate = "Private" // Consider "private"
            var id: String { self.rawValue }
        }
        @State private var selectedPrivacy: PrivacySetting = .isPublic
        
        // MARK: - Location State
        @State private var showLocation: Bool = true
        @StateObject private var locationManager = LocationManager() // New Location Manager
        // This will hold the landmark name or status messages from LocationManager
        @State private var displayableLocationName: String = "Fetching location..."
        
        let emotion: Emotion // Passed in
        
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
            GeometryReader { geometry in
                ZStack {
                    // Main content stack
                    VStack(spacing: 0) {
                        EmotionHeaderView(
                            emotion: emotion,
                            timeFormatter: timeFormatter,
                            currentDisplayLocation: getFormattedLocationForHeader(),
                            geometry: geometry
                        )
                        .padding(.bottom, 30) // Adjust these offsets as per your original design
                        .offset(x: -geometry.size.width * 0, y: -geometry.size.height * 0.48) // Example offset
                        
                        CheckInFormView(
                            reasonText: $reasonText,
                            isTextFieldFocused: $isTextFieldFocused,
                            selectedSocialTags: $selectedSocialTags,
                            predefinedSocialTags: predefinedSocialTags,
                            selectedPrivacy: $selectedPrivacy,
                            showLocation: $showLocation,
                            currentLocation: $displayableLocationName, // Pass the displayable name
                            emotion: emotion,
                            geometry: geometry,
                            isSaving: $isSaving,
                            saveError: $saveError,
                            saveAction: saveCheckIn
                        )
                        .padding(.top, -geometry.size.height * 0.56)
                        .padding(.horizontal, geometry.size.width * 0.24)
                    }
                    .ignoresSafeArea(edges: .top)
                    .onTapGesture {
                        isTextFieldFocused = false // Dismiss keyboard
                    }
                    .offset(y: -geometry.size.width * 0.0)
                    .offset(x: -geometry.size.width * 0.25)

                    // Back Button Overlay
                    VStack {
                        HStack {
                            Button(action: {
                                // Your navigation logic
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.prepare()
                                impactFeedback.impactOccurred()
                                router.navigateBackInMoodFlow(from: CGPoint(x: UIScreen.main.bounds.size.width * 0.1, y: UIScreen.main.bounds.size.height * 0.0))
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44) // Ensure good tap area
                            }
                            .padding(.leading, 25)
                            .padding(.top, -geometry.size.height * 0.02)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                }
                // Alert for save success
                .alert("Success!", isPresented: $showSaveSuccessAlert) {
                    Button("OK", role: .cancel) {
                        router.navigateToMainApp()
                    }
                } message: {
                    Text("Your check-in has been saved successfully.")
                }
            }
            // MARK: - View Lifecycle and Location Logic
            .onAppear {
                locationManager.requestLocationAccessIfNeeded() // Request access first
                if showLocation {
                     // displayableLocationName = "Fetching location..." // Set initial status
                    locationManager.fetchCurrentLocationAndLandmark()
                } else {
                    displayableLocationName = "Location Hidden"
                }
            }
            .onChange(of: showLocation) { newShowValue in
                if newShowValue {
                    displayableLocationName = locationManager.isLoading ? "Fetching location..." : (locationManager.landmarkName ?? "Tap to refresh location")
                    locationManager.fetchCurrentLocationAndLandmark() // Fetch if toggled on
                } else {
                    displayableLocationName = "Location Hidden"
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
                    // showLocation = false // Optionally turn off the toggle
                } else if newStatus == .authorizedAlways || newStatus == .authorizedWhenInUse {
                    if showLocation && locationManager.userCoordinates == nil { // If authorized and location is shown but no coords yet
                        locationManager.fetchCurrentLocationAndLandmark()
                    }
                }
            }
        }
        
        // MARK: - Helper Methods
        private func getFormattedLocationForHeader() -> String {
            if !showLocation {
                return "Location Hidden"
            }
            if displayableLocationName.isEmpty || displayableLocationName == "Fetching location..." || displayableLocationName == "Location unavailable" {
                return displayableLocationName // Show status
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
            } else if coordinates != nil { // Have coords but no name (or name fetch failed)
                displayableLocationName = "Near your current location"
            } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                 displayableLocationName = "Location access needed"
            }
            else {
                displayableLocationName = "Location unavailable" // Fallback
            }
        }
        
        private func saveCheckIn() {
            isSaving = true
            saveError = nil
            showSaveSuccessAlert = false
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            Task {
                do {
                    // Get the latest landmark name and coordinates from the locationManager
                    let landmarkToSave = showLocation ? locationManager.landmarkName : nil
                    let coordinatesToSave = showLocation ? locationManager.userCoordinates : nil
                    
                    print("Saving CheckIn - Landmark: \(landmarkToSave ?? "nil"), Coords: \(String(describing: coordinatesToSave)), ShowLocation: \(showLocation)")

                    let response = try await CheckInService.createCheckIn(
                        emotion: self.emotion,
                        reasonText: self.reasonText,
                        socialTags: self.selectedSocialTags,
                        selectedActivities: self.selectedActivities,
                        landmarkName: landmarkToSave,         // Pass fetched landmark name
                        userCoordinates: coordinatesToSave,   // Pass fetched coordinates
                        showLocation: self.showLocation,      // User's intent
                        privacySetting: self.selectedPrivacy,
                        userDataProvider: self.userDataProvider
                    )
                    
                    await MainActor.run {
                        isSaving = false
                        print("Save successful: \(response.message)")
                        showSaveSuccessAlert = true
                    }
                } catch {
                    await MainActor.run {
                        isSaving = false
                        if let serviceError = error as? CheckInServiceError {
                            saveError = serviceError.errorDescription ?? "An unknown error occurred."
                        } else if let localizedError = error as? LocalizedError {
                            saveError = localizedError.errorDescription ?? error.localizedDescription
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
        CompleteCheckInView(emotion: EmotionDataProvider.highEnergyEmotions[3])
            .environmentObject(MoodAppRouter())
            .environmentObject(UserDataProvider.shared)
            .preferredColorScheme(.dark)
    }
}
