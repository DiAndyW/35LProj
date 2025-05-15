import SwiftUI

struct ActivityTagSectionView: View {
    @Binding var selectedActivities: Set<ActivityTag>
    let predefinedActivities: [ActivityTag] // No binding needed if not modified here
    @Binding var customActivityText: String
    @Binding var showingAddCustomActivityField: Bool
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What are you doing?")
                .font(.custom("Georgia", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AddTagButton {
                        showingAddCustomActivityField.toggle()
                    }

                    ForEach(predefinedActivities + selectedActivities.filter { $0.isCustom }) { activity in
                        PillTagView(text: activity.name, isSelected: selectedActivities.contains(activity)) {
                            if selectedActivities.contains(activity) {
                                selectedActivities.remove(activity)
                            } else {
                                selectedActivities.insert(activity)
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
            }

            if showingAddCustomActivityField {
                HStack {
                    TextField("Add custom activity...", text: $customActivityText)
                        .font(.custom("Roberto", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .onSubmit { addCustomActivity() }
                    Button("Add") { addCustomActivity() }
                        .foregroundColor(accentColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private func addCustomActivity() {
        if !customActivityText.isEmpty {
            let newActivity = ActivityTag(name: customActivityText, isCustom: true)
            selectedActivities.insert(newActivity)
            customActivityText = ""
            showingAddCustomActivityField = false
        }
    }
}
