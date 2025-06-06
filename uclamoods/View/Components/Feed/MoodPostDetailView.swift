import SwiftUI

struct MoodPostDetailView: View {
    let post: FeedItem
    let onDismiss: () -> Void
    
    @State private var newComment: String = ""
    @State private var comments: [CommentPosts]
    @State private var isSendingComment: Bool = false
    
    @State private var keyboardHeight: CGFloat = 0
    @State private var isShowingCommentSheet = false
    
    @State private var showingOptionsMenu = false
    @State private var showingReportMenu = false
    @State private var isBlocking = false
    @State private var isReporting = false
    @State private var statusMessage = ""
    @State private var showStatusMessage = false
    
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    
    @EnvironmentObject private var userDataProvider: UserDataProvider
    @EnvironmentObject private var router: MoodAppRouter
    
    @StateObject private var profanityFilter = ProfanityFilterService()
    @State private var showProfanityToast: Bool = false
    @State private var toastMessage: String = ""
    
    private var accentColor: Color {
        post.emotion.color ?? .blue
    }
    
    private var isCurrentUserAuthor: Bool {
        guard let currentUserId = userDataProvider.currentUser?.id else { return false }
        return currentUserId == post.userId
    }
    
    init(post: FeedItem, onDismiss: @escaping () -> Void) {
        self.post = post
        self.onDismiss = onDismiss
        let initialDataToSort = post.comments?.data ?? []
        self._comments = State(initialValue: initialDataToSort.sorted(by: {
            guard let date1 = DateFormatterUtility.parseCommentTimestamp($0.timestamp),
                  let date2 = DateFormatterUtility.parseCommentTimestamp($1.timestamp)
            else { return false }
            return date1 > date2
        }))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Post Details")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Menu {
                        if isCurrentUserAuthor {
                            Button("Delete Post", role: .destructive) { showingDeleteConfirmation = true }
                        } else {
                            Button("Report Post") { showingReportMenu = true }
                            Button("Block User", role: .destructive) { blockUser() }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle").font(.title2).foregroundColor(.gray.opacity(0.8))
                    }
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray.opacity(0.8))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
                
                Divider().background(Color.gray.opacity(0.3))
                
                
                MoodPostCard(post: post, openDetailAction: {})
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                
                if showStatusMessage {
                    HStack {
                        Text(statusMessage).font(.caption).foregroundColor(statusMessage.contains("Failed") ? .red : .green).padding(.horizontal)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            
                            Color.clear.frame(height: 1).id("topAnchor")
                            
                            Text("Comments (\(comments.count))")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 4)
                            
                            Divider().background(Color.gray.opacity(0.3))

                            VStack(spacing: 12){
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
                            }

                        }
                        .padding(.horizontal, 8)
                    }
                    .onChange(of: comments.count) {
                        withAnimation {
                            proxy.scrollTo("topAnchor", anchor: .top)
                        }
                    }
                }
                .layoutPriority(1)
                                
                Button(action: {
                    withAnimation { isShowingCommentSheet = true }
                }) {
                    HStack {
                        Text("Add a comment...")
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                        Spacer()
                        Image(systemName: "bubble.right.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.05))
            }
            .blur(radius: isShowingCommentSheet ? 15 : 0)
            .animation(.easeInOut, value: isShowingCommentSheet)
            
            if isShowingCommentSheet {
                Color.black.opacity(0.65).ignoresSafeArea().onTapGesture { withAnimation { isShowingCommentSheet = false } }
                
                CommentInputView(isPresented: $isShowingCommentSheet, color: self.accentColor) { commentText in
                    self.newComment = commentText
                    self.attemptSendComment()
                }
                .padding(.bottom, 160)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
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
                .toast(isShowing: $showProfanityToast, message: toastMessage, type: .error)
            }
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.1)).ignoresSafeArea())
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(accentColor.opacity(0.9), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.5), radius: 25, x: 0, y: 15)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .alert("Delete Post", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deletePost() }
        } message: { Text("Are you sure you want to delete this post? This action cannot be undone.") }
        .toast(isShowing: $showProfanityToast, message: toastMessage, type: .error)
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
            withAnimation(.easeOut(duration: 0.3)) { showStatusMessage = false }
        }
    }
    
    func attemptSendComment() {
        let trimmedComment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }
        if profanityFilter.isContentAcceptable(text: trimmedComment) {
            sendComment(content: trimmedComment)
        } else {
            toastMessage = "Your comment contains offensive language."
            showProfanityToast = true
        }
    }
    
    func sendComment(content: String) {
        guard let currentUserId = userDataProvider.currentUser?.id else { return }
        isSendingComment = true
        CommentService.addComment(postId: post.id, userId: currentUserId, content: content) { result in
            DispatchQueue.main.async {
                isSendingComment = false
                switch result {
                    case .success(let response):
                        self.comments.append(response.comment)
                        self.comments.sort {
                            guard let date1 = DateFormatterUtility.parseCommentTimestamp($0.timestamp),
                                  let date2 = DateFormatterUtility.parseCommentTimestamp($1.timestamp)
                            else { return false }
                            return date1 > date2
                        }
                        self.router.commentCountUpdated.send((postId: self.post.id, newCount: response.commentsCount))
                        self.newComment = ""
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
                    case .success:
                        self.showStatus("Post deleted successfully")
                        HapticFeedbackManager.shared.successNotification()
                        self.router.homeFeedNeedsRefresh.send()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.onDismiss() }
                    case .failure(let error):
                        let errorMessage: String
                        switch error {
                            case .unauthorized: errorMessage = "You can only delete your own posts"
                            case .notFound: errorMessage = "This post no longer exists"
                            default: errorMessage = error.localizedDescription
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.onDismiss() }
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
                    case .success(let name): self.username = name
                    case .failure: self.username = "User"
                }
            }
        }
        Divider().background(Color.white.opacity(0.2))
    }
}
