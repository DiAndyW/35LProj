// MoodPostDetailView.swift
// Requires ProfanityFilterService.swift and Toast.swift (for ToastView/modifier) to be in the project.

import SwiftUI

struct MoodPostDetailView: View {
    let post: FeedItem // Assumed to have id: String, and emotion: Emotion? (where Emotion has color: Color?)
    let onDismiss: () -> Void
    
    @State private var newComment: String = ""
    @State private var comments: [CommentPosts] // Assumed CommentPosts and its timestamp parsing are correct
    @State private var isSendingComment: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isCommentFieldFocused: Bool
    
    @EnvironmentObject private var userDataProvider: UserDataProvider

    // MARK: - Profanity Filter and Toast State
    @StateObject private var profanityFilter = ProfanityFilterService()
    @State private var showProfanityToast: Bool = false
    @State private var toastMessage: String = ""
    
    private var accentColor: Color {
        post.emotion.color ?? .blue // Assumes FeedItem.emotion.color exists
    }

    init(post: FeedItem, onDismiss: @escaping () -> Void) {
        self.post = post
        self.onDismiss = onDismiss
        let initialData = post.comments?.data ?? []
         let initialDataToSort = post.comments?.data ?? [] // Assuming FeedItem now has optional 'comments: CommentsResponse?'
         self._comments = State(initialValue: initialDataToSort.sorted(by: { comment1, comment2 in
             guard let date1 = DateFormatterUtility.parseCommentTimestamp(comment1.timestamp),
                   let date2 = DateFormatterUtility.parseCommentTimestamp(comment2.timestamp) else {
                 return false
             }
             return date1 > date2
         }))
    }
    
    var body: some View {
        ZStack { // Ensure ZStack is the outermost for the toast modifier to cover the whole view
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Post Details")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Content with ScrollViewReader for auto-scroll
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            MoodPostCard( // This assumes MoodPostCard can handle the 'post: FeedItem'
                                post: post,
                                openDetailAction: {}
                            )
                            .scaledToFit()
                            .padding(12)
                            
                            Divider().background(Color.gray.opacity(0.9)).padding(.horizontal)
                            
                            Text("Comments (\(comments.count))")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            if comments.isEmpty {
                                Text("No comments yet.")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(comments) { comment in // Assumes CommentPosts is Identifiable
                                    CommentView(comment: comment)
                                        .padding(.horizontal)
                                }
                            }
                            
                            // Invisible anchor for scrolling to bottom
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.top)
                        .padding(.bottom, max(80, keyboardHeight + 20)) // Dynamic bottom padding
                    }
                    .onChange(of: isCommentFieldFocused) { focused in
                        if focused {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: keyboardHeight) { _ in // height parameter not used directly
                        if isCommentFieldFocused { // Scroll if focused, regardless of height value if it means keyboard is up
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Comment Input Area
                HStack(spacing: 12) {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .accentColor(accentColor)
                        .focused($isCommentFieldFocused)
                        .onSubmit {
                            attemptSendComment() // Changed to attemptSendComment
                        }
                        .submitLabel(.send)
                    
                    if isSendingComment {
                        ProgressView().tint(.white)
                    } else {
                        Button(action: attemptSendComment) { // Changed to attemptSendComment
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : accentColor)
                        }
                        .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
            }
            .offset(y: -keyboardHeight) // Move entire view up by keyboard height
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.5))
                    .ignoresSafeArea()
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentColor.opacity(0.9), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.5), radius: 25, x: 0, y: 15)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
            // Dismiss keyboard when tapping outside the text field area (e.g., on the main content)
            .onTapGesture {
                if isCommentFieldFocused {
                    isCommentFieldFocused = false
                }
            }
        }
        .toast(isShowing: $showProfanityToast, message: toastMessage, type: .error) // Apply toast modifier
    }
    
    func attemptSendComment() {
        let trimmedComment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }

        if profanityFilter.isContentAcceptable(text: trimmedComment) {
            sendComment(content: trimmedComment) // Pass the already trimmed comment
        } else {
            toastMessage = "Your comment contains offensive language."
            showProfanityToast = true
        }
    }
    
    func sendComment(content: String) { // Accepts content parameter
        guard let currentUserId = userDataProvider.currentUser?.id else {
            print("User not logged in.")
            // Optionally, show a toast for this specific error
            // self.toastMessage = "Please log in to comment."
            // self.showProfanityToast = true // Or use a different toast state for different error types
            return
        }
        
        isSendingComment = true
        CommentService.addComment(postId: post.id, userId: currentUserId, content: content) { result in
            DispatchQueue.main.async {
                isSendingComment = false
                switch result {
                    case .success(let response):
                        // Assuming response.comment is of type CommentPosts
                        self.comments.append(response.comment)
                        self.comments.sort { comment1, comment2 in
                            guard let date1 = DateFormatterUtility.parseCommentTimestamp(comment1.timestamp),
                                  let date2 = DateFormatterUtility.parseCommentTimestamp(comment2.timestamp) else {
                                return false
                            }
                            return date1 > date2 // Assuming newest first
                        }
                        self.newComment = ""
                        self.isCommentFieldFocused = false // Dismiss keyboard
                    case .failure(let error):
                        print("Error sending comment: \(error.localizedDescription)")
                        // Optionally, show a non-profanity error toast
                        // self.toastMessage = "Failed to send comment."
                        // self.showProfanityToast = true // Or a different toast state
                }
            }
        }
    }
}

// Make sure your supporting structs like FeedItem (and its comment/emotion structure),
// CommentPosts, UserDataProvider, CommentService, DateFormatterUtility, MoodPostCard, etc., are correctly defined.
// For `post.comments?.data`: Ensure `FeedItem` has an optional property `comments` of a type that has an optional `data: [CommentPosts]?`.
// For example:
// protocol FeedItem: Identifiable {
//     var id: String { get }
//     var emotion: Emotion? { get }
//     var comments: CommentsResponse? { get } // Added for comment initialization
//     // ... other properties
// }
// struct Emotion { var color: Color? /* ... */ }
// struct CommentsResponse: Codable { var data: [CommentPosts]? } // Matching structure for comments

struct CommentView: View {
    let comment: CommentPosts
    @State private var username: String = "Loading..."
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(username)
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                    Text(DateFormatterUtility.formatTimestampParts(timestampString: comment.timestamp)?.relativeDate ?? comment.timestamp)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .onAppear {
            fetchUsername(for: comment.userId) { result in
                switch result {
                    case .success(let name):
                        self.username = name
                    case .failure:
                        self.username = "User"
                }
            }
        }
    }
}
