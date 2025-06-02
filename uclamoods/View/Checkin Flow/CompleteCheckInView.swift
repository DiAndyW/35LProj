import SwiftUI

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
            }
            .offset(y: geometry.size.width * 0.35)
        }
    }
}


struct SocialTagSectionView: View {
    @Binding var selectedUsers: Set<MockUser>
    let availableUsers: [MockUser]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Who were you with")
                .font(.custom("Georgia", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AddTagButton {
                        if let firstUser = availableUsers.first {
                            if selectedUsers.contains(firstUser) {
                                selectedUsers.remove(firstUser)
                            } else {
                                selectedUsers.insert(firstUser)
                            }
                        }
                    }
                    
                    ForEach(availableUsers) { user in
                        PillTagView(text: user.name, isSelected: selectedUsers.contains(user)) {
                            if selectedUsers.contains(user) {
                                selectedUsers.remove(user)
                            } else {
                                selectedUsers.insert(user)
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
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
                
                Text("\(reasonText.count)/500")
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
                            .foregroundColor(.black)
                            .frame(width: geometry.size.width * 0.8, height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                            .shadow(radius: 5)
                    }
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
    
    @Binding var selectedUsers: Set<MockUser>
    let availableUsers: [MockUser]
    
    @Binding var selectedPrivacy: CompleteCheckInView.PrivacySetting
    @Binding var showLocation: Bool
    @Binding var currentLocation: String
    
    let emotion: Emotion
    let geometry: GeometryProxy
    
    @Binding var isSaving: Bool
    @Binding var saveError: String?
    
    let saveAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SocialTagSectionView(
                selectedUsers: $selectedUsers,
                availableUsers: availableUsers
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
                saveError: saveError
            )
        }
    }
}

struct CompleteCheckInView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    @State private var reasonText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var selectedUsers: Set<MockUser> = []
    @State private var availableUsers: [MockUser] = [
        MockUser(name: "Sarah"), MockUser(name: "Mike"), MockUser(name: "Chloe"),
        MockUser(name: "David R."), MockUser(name: "By Myself")
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
        case friends = "Friends"
        case isPublic = "Public"
        case isPrivate = "Private"
        var id: String { self.rawValue }
    }
    @State private var selectedPrivacy: PrivacySetting = .friends
    
    @State private var showLocation: Bool = true
    @State private var currentLocation: String = "Math Science Building"
    let emotion: Emotion
    
    @State private var isSaving: Bool = false
    @State private var saveError: String? = nil
    @State private var showSaveSuccessAlert: Bool = false
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                VStack(spacing: 0) {
                    EmotionHeaderView(
                        emotion: emotion,
                        timeFormatter: timeFormatter,
                        currentDisplayLocation: showLocation ? (currentLocation.isEmpty ? "Current Location" : "@ \(currentLocation)") : "Location Hidden",
                        geometry: geometry
                    )
                    .padding(.bottom, 30)
                    .offset(x: -geometry.size.width * 0, y: -geometry.size.height * 0.4)
                    
                    CheckInFormView(
                        reasonText: $reasonText,
                        isTextFieldFocused: $isTextFieldFocused,
                        selectedUsers: $selectedUsers,
                        availableUsers: availableUsers,
                        selectedPrivacy: $selectedPrivacy,
                        showLocation: $showLocation,
                        currentLocation: $currentLocation,
                        emotion: emotion,
                        geometry: geometry,
                        isSaving: $isSaving,
                        saveError: $saveError,
                        saveAction: saveCheckIn
                    ).padding(.top, -geometry.size.height * 0.48)
                    
                }
                .ignoresSafeArea(edges: .top)
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .offset(y: -geometry.size.width * 0.0)
                .offset(x: -geometry.size.width * 0.25)
            }
            .alert("Success!", isPresented: $showSaveSuccessAlert) {
                Button("OK", role: .cancel) {
                    router.navigateToMainApp()
                }
            } message: {
                Text("Your check-in has been saved successfully.")
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
    
    private func saveCheckIn() {
        isSaving = true
        saveError = nil
        showSaveSuccessAlert = false
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        Task {
            do {
                let response = try await CheckInService.createCheckIn(
                    emotion: self.emotion,
                    reasonText: self.reasonText,
                    selectedUsers: self.selectedUsers,
                    selectedActivities: self.selectedActivities,
                    currentLocationName: self.currentLocation,
                    showLocation: self.showLocation,
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
                    if let localizedError = error as? LocalizedError {
                        saveError = localizedError.errorDescription ?? "An unknown error occurred."
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
