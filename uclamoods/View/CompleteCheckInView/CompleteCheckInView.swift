import SwiftUI

// MARK: - Data Models (Existing)
struct MockUser: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct ActivityTag: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var isCustom: Bool = false
}

// MARK: - Reusable Tag Views (Existing)
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

// MARK: - Subviews for CompleteCheckInView

struct EmotionHeaderView: View {
    let emotion: Emotion
    let timeFormatter: DateFormatter
    let currentDisplayLocation: String // e.g., "@ Sproul Hall"
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
            // The .padding and .offset for FloatingBlobButton are applied to the ZStack itself in the main view.
            VStack {
                Text(emotion.name)
                    .font(.custom("Georgia", size: 50))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(timeFormatter.string(from: Date()))
                    .font(.custom("Chivo", size: 20))
                    .foregroundColor(.white)
                    .offset(y: geometry.size.width * 0.01) // Original offset

                Text(currentDisplayLocation)
                    .font(.custom("Chivo", size: 20))
                    .foregroundColor(.white)
                    .offset(y: geometry.size.width * 0.01) // Original offset
            }
            .offset(y: geometry.size.width * 0.35)
        }
    }
}



struct SocialTagSectionView: View { // Added this section
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
                        // ACTION: Implement user selection logic (e.g., show a modal)
                        // For now, cycles the first user for demo
                        if let firstUser = availableUsers.first {
                            if selectedUsers.contains(firstUser) {
                                selectedUsers.remove(firstUser)
                            } else {
                                selectedUsers.insert(firstUser)
                            }
                        }
                    }

                    ForEach(availableUsers) { user in // Display all available for selection
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
    @Binding var selectedPrivacy: CompleteCheckInView.PrivacySetting // Explicitly scope PrivacySetting
    // let accentColor: Color // If you plan to tint the picker

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
    @Binding var currentLocation: String // Make it binding if it can be changed
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
    var isTextFieldFocused: FocusState<Bool>.Binding // Pass FocusState itself
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Why do you feel this way?")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                // .padding(.top, 30) // Original padding, adjust if needed within a larger form

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
                    .focused(isTextFieldFocused) // Use the passed FocusState
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
        // Original offset for this section was:
        // .offset(x: -geometry.size.width * 0.25, y: -geometry.size.height * 0.3)
        // This will now be handled by the overall layout of CheckInFormView if needed,
        // or applied here if this section specifically needs that offset relative to other form elements.
        // For now, removing it to allow it to flow within CheckInFormView.
    }
}

struct SaveCheckInButtonView: View {
    let geometry: GeometryProxy
    let action: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            HStack{
                Spacer()
                Button(action: action) {
                    Text("Save Check-in")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: geometry.size.width * 0.8, height: 50)
                        .background(.white)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                }
                Spacer()
            }
        }
        .padding(.bottom, 50)
    }
}

// Container for all form elements
struct CheckInFormView: View {
    @Binding var reasonText: String
    var isTextFieldFocused: FocusState<Bool>.Binding

    @Binding var selectedUsers: Set<MockUser>
    let availableUsers: [MockUser]

    @Binding var selectedActivities: Set<ActivityTag>
    let predefinedActivities: [ActivityTag]
    @Binding var customActivityText: String
    @Binding var showingAddCustomActivityField: Bool

    @Binding var selectedPrivacy: CompleteCheckInView.PrivacySetting
    @Binding var showLocation: Bool
    @Binding var currentLocation: String
    
    let emotion: Emotion // For accent colors
    let geometry: GeometryProxy // For save button width
    let saveAction: () -> Void

    var body: some View {
        VStack(spacing: 0) { // Keep original spacing 0 if sections manage their own padding
//            ActivityTagSectionView(
//                selectedActivities: $selectedActivities,
//                predefinedActivities: predefinedActivities,
//                customActivityText: $customActivityText,
//                showingAddCustomActivityField: $showingAddCustomActivityField,
//                accentColor: emotion.color
//            )

            SocialTagSectionView( // Added this based on requirements
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

            SaveCheckInButtonView(geometry: geometry, action: saveAction)
        }
    }
}


// MARK: - Main View
struct CompleteCheckInView: View {
    @EnvironmentObject private var router: MoodAppRouter
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

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private var dateFormatter: DateFormatter { // Not currently used in visible UI from snippet
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }

    var body: some View {
        GeometryReader { geometry in
            // This is the main VStack that receives the large, somewhat unusual offsets.
            // We assume these offsets are intentional for the desired screen layout.
            VStack(spacing: 0) {
                EmotionHeaderView(
                    emotion: emotion,
                    timeFormatter: timeFormatter,
                    currentDisplayLocation: "@ Sproul Hall", // Using your hardcoded example
                    geometry: geometry
                )
                .padding(.bottom, 30) // Original padding for the ZStack
                 // Original offset for the ZStack containing the blob
                .offset(x: -geometry.size.width * 0, y: -geometry.size.height * 0.4)


                // The ScrollView will handle content that might exceed screen height.
                // The CheckInFormView contains all the input fields.
             
                    CheckInFormView(
                        reasonText: $reasonText,
                        isTextFieldFocused: $isTextFieldFocused,
                        selectedUsers: $selectedUsers,
                        availableUsers: availableUsers,
                        selectedActivities: $selectedActivities,
                        predefinedActivities: predefinedActivities,
                        customActivityText: $customActivityText,
                        showingAddCustomActivityField: $showingAddCustomActivityField,
                        selectedPrivacy: $selectedPrivacy,
                        showLocation: $showLocation,
                        currentLocation: $currentLocation,
                        emotion: emotion,
                        geometry: geometry,
                        saveAction: saveCheckIn
                    ).padding(.top, -geometry.size.height * 0.48)
                
                
                //.offset(y: -geometry.size.width * 0.1)
            }
            //.background(Color.black) // Moved from GeometryReader to the VStack to be part of the offset content
            .ignoresSafeArea(edges: .top)
            .onTapGesture {
                isTextFieldFocused = false
            }
            // These are the original offsets applied to the outermost VStack in your code
            .offset(y: -geometry.size.width * 0.0) // This is a very large Y offset, using width. Verify if intended.
            .offset(x: -geometry.size.width * 0.25)
        }
    }

    private func saveCheckIn() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        // TODO: Collect all data:
        // emotion, reasonText, selectedUsers, selectedActivities, selectedPrivacy,
        // showLocation ? currentLocation : nil
        print("Saving Check-in:")
        print("- Emotion: \(emotion.name)")
        print("- Reason: \(reasonText)")
        print("- With: \(selectedUsers.map { $0.name })")
        print("- Doing: \(selectedActivities.map { $0.name })")
        print("- Privacy: \(selectedPrivacy.rawValue)")
        if showLocation {
            print("- Location: \(currentLocation)")
        } else {
            print("- Location: Hidden")
        }
        router.navigateToHome()
    }

    private func skipToComplete() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        router.navigateToHome()
    }
}

struct CompleteCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        CompleteCheckInView(emotion: EmotionDataProvider.highEnergyEmotions[3])
            .environmentObject(MoodAppRouter())
            .preferredColorScheme(.dark)
    }
}
