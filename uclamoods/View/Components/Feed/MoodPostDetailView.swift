import SwiftUI

struct MoodPostDetailView: View {
    let post: FeedItem
    let onDismiss: () -> Void
    
    @State private var newComment: String = ""
    @State private var comments: [CommentPosts]
    @State private var isSendingComment: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isCommentFieldFocused: Bool
    
    // Block and Report states
    @State private var showingOptionsMenu = false
    @State private var showingReportMenu = false
    @State private var isBlocking = false
    @State private var isReporting = false
    @State private var statusMessage = ""
    @State private var showStatusMessage = false
    
    // Delete states
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    
    @EnvironmentObject private var userDataProvider: UserDataProvider
    @EnvironmentObject private var router: MoodAppRouter

    // MARK: - Profanity Filter and Toast State

    @StateObject private var profanityFilter = ProfanityFilterService()
    @State private var showProfanityToast: Bool = false
    @State private var toastMessage: String = ""
    
    private var accentColor: Color {
        post.emotion.color ?? .blue
    }
    
    // Check if current user is the author of the post
    private var isCurrentUserAuthor: Bool {
        guard let currentUserId = userDataProvider.currentUser?.id else { return false }
        return currentUserId == post.userId
    }

    init(post: FeedItem, onDismiss: @escaping () -> Void) {
        self.post = post
        self.onDismiss = onDismiss
        let initialDataToSort = post.comments?.data ?? []
        self._comments = State(initialValue: initialDataToSort.sorted(by: { comment1, comment2 in
            guard let date1 = DateFormatterUtility.parseCommentTimestamp(comment1.timestamp),
                  let date2 = DateFormatterUtility.parseCommentTimestamp(comment2.timestamp)
            else {
                return false
            }
            return date1 > date2
        }))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Post Details")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    
                    // Conditional Options menu based on post ownership
                    Menu {
                        if isCurrentUserAuthor {
                            Button("Delete Post", role: .destructive) {
                                showingDeleteConfirmation = true
                            }
                        } else {
                            Button("Report Post") {
                                showingReportMenu = true
                            }
                            
                            Button("Block User", role: .destructive) {
                                blockUser()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    
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
                
                // Status message
                if showStatusMessage {
                    HStack {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(statusMessage.contains("Failed") ? .red : .green)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Content with ScrollViewReader for auto-scroll
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            MoodPostCard(
                                post: post,
                                openDetailAction: {}
                            )
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
                            isCommentFieldFocused = false
                        }
                        .submitLabel(.done)
                    
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
            
            // Delete confirmation alert
            .alert("Delete Post", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deletePost()
                }
            } message: {
                Text("Are you sure you want to delete this post? This action cannot be undone.")
            }
            
            // Report reason dropdown overlay
            if showingReportMenu {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingReportMenu = false
                        }
                    
                    VStack(spacing: 0) {
                        Text("Report this post")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.8))
                        
                        VStack(spacing: 1) {
                            reportButton("Spam - fake engagement or repetitive content", reason: "This appears to be spam with fake engagement or repetitive content that doesn't contribute to meaningful discussion")
                            reportButton("Inappropriate Content - offensive or disturbing", reason: "This content contains inappropriate material that is offensive, disturbing, or violates community standards")
                            reportButton("Harassment - targeting or bullying behavior", reason: "This post contains harassment, targeting, or bullying behavior directed at individuals or groups")
                            reportButton("False Information - misleading or incorrect", reason: "This post contains false, misleading, or incorrect information that could be harmful or deceptive")
                            reportButton("Other - violates community guidelines", reason: "This content violates community guidelines in ways not covered by other categories")
                            
                            Button("Cancel") {
                                showingReportMenu = false
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.1))
                        }
                    }
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                }
            }
        }
        .toast(isShowing: $showProfanityToast, message: toastMessage, type: .error) // Apply toast modifier only for profanity
    }
    
    private func reportButton(_ title: String, reason: String) -> some View {
        Button(title) {
            showingReportMenu = false
            reportPost(reason: reason)
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
    }
    
    private func showStatus(_ message: String, duration: TimeInterval = 3.0) {
        statusMessage = message
        showStatusMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.3)) {
                showStatusMessage = false
            }
        }
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
                              let date2 = DateFormatterUtility.parseCommentTimestamp(comment2.timestamp)
                        else {
                            return false
                        }
                        return date1 > date2 // Assuming newest first
                    }
                    self.router.commentCountUpdated.send((postId: self.post.id, newCount: response.commentsCount))
                    self.newComment = ""
                    self.isCommentFieldFocused = false // Dismiss keyboard
                case .failure(let error):
                    print("Error sending comment: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deletePost() {
        guard let currentUserId = userDataProvider.currentUser?.id else {
            showStatus("Please log in to delete posts")
            return
        }
        
        guard !isDeleting else { return }
        
        isDeleting = true
        showStatus("Deleting post...")
        
        DeleteService.deletePost(postId: post.id, userId: currentUserId) { result in
            DispatchQueue.main.async {
                self.isDeleting = false
                switch result {
                    case .success(_):
                    self.showStatus("Post deleted successfully")
                    HapticFeedbackManager.shared.successNotification()
                    
                    // Dismiss the detail view after successful deletion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.onDismiss()
                    }
                    
                case .failure(let error):
                    var errorMessage: String
                    switch error {
                    case .unauthorized:
                        errorMessage = "You can only delete your own posts"
                    case .notFound:
                        errorMessage = "This post no longer exists"
                    default:
                        errorMessage = error.localizedDescription
                    }
                    self.showStatus("Failed to delete post: \(errorMessage)")
                    HapticFeedbackManager.shared.errorNotification()
                }
            }
        }
    }
    
    private func blockUser() {
        guard let currentUserId = userDataProvider.currentUser?.id else {
            showStatus("Please log in to block users")
            return
        }
        
        guard !isBlocking else { return }
        
        isBlocking = true
        showStatus("Blocking user...")
        
        BlockService.blockUser(userId: post.userId, currentUserId: currentUserId) { result in
            DispatchQueue.main.async {
                self.isBlocking = false
                switch result {
                case .success:
                    self.showStatus("User blocked successfully")
                    HapticFeedbackManager.shared.successNotification()
                    
                    self.router.userDidBlock.send(self.post.userId)
                        
                    // Optionally dismiss the detail view after blocking
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.onDismiss()
                    }
                case .failure(let error):
                    self.showStatus("Failed to block user: \(error.localizedDescription)")
                    HapticFeedbackManager.shared.errorNotification()
                }
            }
        }
    }
    
    private func reportPost(reason: String) {
        guard (userDataProvider.currentUser?.id) != nil else {
            showStatus("Please log in to report posts")
            return
        }
        
        guard !isReporting else { return }
        
        isReporting = true
        showStatus("Reporting post...")
        
        ReportService.reportPost(postId: post.id, reason: reason) { result in
            DispatchQueue.main.async {
                self.isReporting = false
                switch result {
                case .success:
                    self.showStatus("Post reported successfully")
                    HapticFeedbackManager.shared.successNotification()
                case .failure(let error):
                    self.showStatus("Failed to report post: \(error.localizedDescription)")
                    HapticFeedbackManager.shared.errorNotification()
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
