import SwiftUI

struct CommentInputView: View {
    @Binding var isPresented: Bool
    let color: Color
    let onPost: (String) -> Void
    
    @State private var commentText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    private var isPostButtonDisabled: Bool {
        commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add Your Comment")
                .font(.custom("Georgia", size: 20, relativeTo: .headline).weight(.bold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 8)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $commentText)
                    .scrollContentBackground(.hidden)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .focused($isTextFieldFocused)
                    .onChange(of: commentText) {
                        if commentText.contains("\n") {
                            commentText = commentText.replacingOccurrences(of: "\n", with: "")
                            hideKeyboard()
                        }
                    }
                
                if commentText.isEmpty {
                    Text("What's on your mind?")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            
            HStack(spacing: 8) {
                Button("Cancel") {
                    hideKeyboard()
                    withAnimation { isPresented = false }
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.white)
                .clipShape(Capsule())
                
                Button("Post") {
                    hideKeyboard()
                    onPost(commentText)
                    commentText = ""
                    withAnimation { isPresented = false }
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isPostButtonDisabled ? color.opacity(0.4) : color)
                .foregroundColor(isPostButtonDisabled ? .white.opacity(0.6) : .white)
                .clipShape(Capsule())
                .disabled(isPostButtonDisabled)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        .padding(.horizontal, 20)
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
