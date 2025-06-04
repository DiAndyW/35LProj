import SwiftUI

struct MoodPostDetailView: View {
    let post: FeedItem
    let onDismiss: () -> Void
    
    @State private var newComment: String = ""
    @State private var comments: [CommentPosts]
    @State private var isSendingComment: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isCommentFieldFocused: Bool
    
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    init(post: FeedItem, onDismiss: @escaping () -> Void) {
        self.post = post
        self.onDismiss = onDismiss
        let initialData = post.comments?.data ?? []
        self._comments = State(initialValue: initialData.sorted(by: { comment1, comment2 in
            guard let date1 = DateFormatterUtility.parseCommentTimestamp(comment1.timestamp),
                  let date2 = DateFormatterUtility.parseCommentTimestamp(comment2.timestamp) else {
                return false
            }
            return date1 > date2
        }))
    }
    
    var body: some View {
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
                        MoodPostCard(
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
                            ForEach(comments) { comment in
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
                        // Scroll to bottom when keyboard appears
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: keyboardHeight) { height in
                    if isCommentFieldFocused && height > 0 {
                        // Keep scrolled to bottom when keyboard height changes
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
                    .accentColor(.blue)
                    .focused($isCommentFieldFocused)
                    .onSubmit {
                        if !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            sendComment()
                        }
                    }
                    .submitLabel(.send)
                
                if isSendingComment {
                    ProgressView().tint(.white)
                } else {
                    Button(action: sendComment) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : post.emotion.color ?? .blue)
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
                .stroke(post.emotion.color?.opacity(0.9) ?? Color.white.opacity(0.1), lineWidth: 2)
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
        // Dismiss keyboard when tapping outside
        .onTapGesture {
            if isCommentFieldFocused {
                isCommentFieldFocused = false
            }
        }
    }
    
    func sendComment() {
        guard let currentUserId = userDataProvider.currentUser?.id,
              !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("User not logged in or comment is empty.")
            return
        }
        
        isSendingComment = true
        CommentService.addComment(postId: post.id, userId: currentUserId, content: newComment) { result in
            DispatchQueue.main.async {
                isSendingComment = false
                switch result {
                    case .success(let response):
                        self.comments.append(response.comment)
                        self.comments.sort { comment1, comment2 in
                            guard let date1 = DateFormatterUtility.parseCommentTimestamp(comment1.timestamp),
                                  let date2 = DateFormatterUtility.parseCommentTimestamp(comment2.timestamp) else {
                                return false
                            }
                            return date1 > date2
                        }
                        self.newComment = ""
                        // Dismiss keyboard after sending
                        self.isCommentFieldFocused = false
                    case .failure(let error):
                        print("Error sending comment: \(error.localizedDescription)")
                }
            }
        }
    }
}

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
