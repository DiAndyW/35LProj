import SwiftUI
import MapKit

// MARK: - Data Models

extension MKCoordinateSpan: Equatable {
    public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        return lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }
}

// 3. Make MKCoordinateRegion Equatable
extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        // A region is equal if its center and span are both equal.
        // This relies on CLLocationCoordinate2D and MKCoordinateSpan being Equatable.
        return lhs.center == rhs.center && lhs.span == rhs.span
    }
}

struct UserBrief: Codable, Identifiable {
    let id: String
    let username: String
    let profilePicture: String? // Or String if it's never null

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case profilePicture
    }
}

struct MapMoodPost: Identifiable, Codable {
    let id: String
    let userId: UserBrief // Ensure UserBrief's CodingKeys map _id to id if necessary
    let emotion: SimpleEmotion
    let reason: String?
    let location: MapLocation
    let timestamp: String
    let privacy: String
    let isAnonymous: Bool?
    let distance: Double?
    let likesCount: Int       // Expects JSON key "likesCount"
    let commentsCount: Int    // Expects JSON key "commentsCount"
    let people: [String]?
    let activities: [String]?

    
    private enum CodingKeys: String, CodingKey {
        case id = "_id" // Correct: maps JSON "_id" to Swift "id"
        case userId, emotion, reason, location, timestamp, privacy, isAnonymous, distance
        // CORRECTED for new backend JSON keys:
        case likesCount
        case commentsCount
        case people, activities
        // case type // if you add type to the JSON for single posts as well
    }
    
    var asFeedItem: FeedItem {
        FeedItem(
            id: id,
            userId: userId.id, // Assuming FeedItem.userId is a String ID
            emotion: emotion,
            content: reason,
            people: people,
            activities: activities,
            location: SimpleLocation(name: location.landmarkName),
            timestamp: timestamp,
            likesCount: likesCount,     // Pass through
            commentsCount: commentsCount  // Pass through
        )
    }
}

struct MapLocation: Codable {
    let landmarkName: String
    let coordinates: GeoJSONPoint
}

struct GeoJSONPoint: Codable {
    let type: String
    let coordinates: [Double] // [longitude, latitude]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])
    }
}

struct MapMoodsResponse: Codable {
    let success: Bool
    let count: Int
    let viewport: Viewport?
    let clustered: Bool?
    let data: [MapMoodPost]
}

struct Viewport: Codable {
    let sw: CoordinatePair
    let ne: CoordinatePair
}

struct CoordinatePair: Codable {
    let lat: Double
    let lng: Double
}

// MARK: - Map Annotation

struct MoodPostAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let moodPost: MapMoodPost
    
    var color: Color {
        moodPost.emotion.color ?? Color.gray
    }
}

// MARK: - MapView

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedMoodPost: MapMoodPost?
    @State private var showingMoodDetail = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0689, longitude: -118.4452),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var tracking: MapUserTrackingMode = .follow
    
    var body: some View {
        ZStack {
            // Main Map
            Map(
                coordinateRegion: $mapRegion,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $tracking,
                annotationItems: viewModel.annotations
            ) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    MoodPostMarker(annotation: annotation) {
                        selectedMoodPost = annotation.moodPost
                        showingMoodDetail = true
                    }
        .preferredColorScheme(.dark) // Match MoodPostCard dark theme
                }
            }
            .onAppear {
                locationManager.startUpdatingMapLocation()
                if let userCoord = locationManager.userCoordinates {
                    mapRegion.center = userCoord
                }
            }
            .onDisappear {
                locationManager.stopUpdatingMapLocation()
            }
            .onChange(of: mapRegion) { _ in
                viewModel.fetchMoodPosts(for: mapRegion)
            }
            .onChange(of: locationManager.userCoordinates) { newCoordinates in
                if let coordinates = newCoordinates, tracking == .follow {
                    withAnimation {
                        mapRegion.center = coordinates
                    }
                }
            }
            
            // Overlay Controls
            VStack {
                HStack {
                    // Refresh Button
                    Button(action: {
                        viewModel.fetchMoodPosts(for: mapRegion, forceRefresh: true)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // User Location Button
                    Button(action: {
                        if let userCoord = locationManager.userCoordinates {
                            withAnimation {
                                mapRegion.center = userCoord
                                tracking = .follow
                            }
                        }
                    }) {
                        Image(systemName: tracking == .follow ? "location.fill" : "location")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Mood count in area
                if !viewModel.annotations.isEmpty {
                    Text("\(viewModel.annotations.count) mood\(viewModel.annotations.count == 1 ? "" : "s") nearby")
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding()
                }
            }
            
//            // Loading Indicator
//            if viewModel.isLoading {
//                VStack {
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                        .scaleEffect(0.8)
//                    Text("Loading nearby moods...")
//                        .font(.custom("Georgia", size: 13))
//                        .foregroundColor(.white.opacity(0.7))
//                }
//                .padding()
//                .background(Color.black.opacity(0.7))
//                .cornerRadius(12)
//            }
        }
        .sheet(isPresented: $showingMoodDetail) {
            if let moodPost = selectedMoodPost {
                MoodPostDetailView(moodPost: moodPost)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Mood Post Marker

struct MoodPostMarker: View {
    let annotation: MoodPostAnnotation
    let action: () -> Void
    @State private var showingPreview = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Mood color marker
            Circle()
                .fill(annotation.color)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(radius: 4)
                .onTapGesture {
                    action()
                }
                .onLongPressGesture {
                    showingPreview.toggle()
                }
            
            // Pin tail
            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(annotation.color)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
        .popover(isPresented: $showingPreview) {
            MoodPostPreview(moodPost: annotation.moodPost)
                .frame(width: 250, height: 150)
        }
    }
}

// MARK: - Mood Post Preview

struct MoodPostPreview: View {
    let moodPost: MapMoodPost
    @State private var displayUsername: String = "Loading..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Mood color indicator
                Circle()
                    .fill(moodPost.emotion.color ?? Color.gray)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayUsername)
                        .font(.custom("Georgia", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(moodPost.location.landmarkName)
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text(moodPost.emotion.name)
                    .font(.custom("Georgia", size: 13))
                    .fontWeight(.medium)
                    .foregroundColor(moodPost.emotion.color ?? .white)
            }
            
            if let reason = moodPost.reason {
                Text(reason)
                    .font(.custom("Georgia", size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
            }
            
            HStack {
                Text(formatRelativeTimestamp(from: moodPost.timestamp))
                    .font(.custom("Georgia", size: 12))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                if let distance = moodPost.distance {
                    Text("\(String(format: "%.1f", distance)) km away")
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.25))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            fetchUsername(for: moodPost.userId.id) { result in
                switch result {
                case .success(let username):
                    displayUsername = moodPost.isAnonymous ?? false ? "Anonymous" : username
                case .failure:
                    displayUsername = "User"
                }
            }
        }
    }
}

// MARK: - Mood Post Detail View

struct MoodPostDetailView: View {
    let moodPost: MapMoodPost
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background to match MoodPostCard styling
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Use the existing MoodPostCard for consistent styling
                        MoodPostCard(post: moodPost.asFeedItem)
                            .padding(.horizontal)
                        
                        // Mini Map
                        Map(coordinateRegion: .constant(
                            MKCoordinateRegion(
                                center: moodPost.location.coordinates.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        ), annotationItems: [moodPost]) { post in
                            MapPin(
                                coordinate: post.location.coordinates.coordinate,
                                tint: post.emotion.color ?? Color.gray
                            )
                        }
                        .frame(height: 200)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Additional map-specific info
                        if let distance = moodPost.distance {
                            HStack {
                                Image(systemName: "location.circle")
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(String(format: "%.1f", distance)) km from your location")
                                    .font(.custom("Georgia", size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Remove the MoodStatsBar struct since we're using inline styling

// MARK: - View Model

@MainActor
class MapViewModel: ObservableObject {
    @Published var annotations: [MoodPostAnnotation] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private var currentTask: Task<Void, Never>?

    // Define a custom error enum for more specific error handling if desired
    enum MapError: Error, LocalizedError {
        case badURL
        case requestFailed(Error)
        case badServerResponse(statusCode: Int)
        case decodingError(Error)
        case unknown

        var errorDescription: String? {
            switch self {
            case .badURL:
                return "The URL for fetching map data was invalid."
            case .requestFailed(let error):
                return "Network request failed: \(error.localizedDescription)"
            case .badServerResponse(let statusCode):
                return "Server returned an error: HTTP \(statusCode)."
            case .decodingError(let error):
                return "Failed to decode map data: \(error.localizedDescription)"
            case .unknown:
                return "An unknown error occurred."
            }
        }
    }

    func fetchMoodPosts(for region: MKCoordinateRegion, forceRefresh: Bool = false) {
        currentTask?.cancel()

        currentTask = Task {
            // Ensure UI updates are on the main thread if not already guaranteed by @MainActor on the class
            await MainActor.run {
                if !forceRefresh && isLoading { return }
                isLoading = true
                // showError = false // Optionally reset error state at the beginning
                // errorMessage = ""
            }

            do {
                let bounds = region.getBounds()
                let center = region.center

                var components = URLComponents(url: Config.apiURL(for: "/api/map/moods"), resolvingAgainstBaseURL: false)
                guard var validComponents = components else {
                    throw MapError.badURL // Use custom error
                }

                validComponents.queryItems = [
                    URLQueryItem(name: "swLat", value: String(bounds.sw.latitude)),
                    URLQueryItem(name: "swLng", value: String(bounds.sw.longitude)),
                    URLQueryItem(name: "neLat", value: String(bounds.ne.latitude)),
                    URLQueryItem(name: "neLng", value: String(bounds.ne.longitude)),
                    URLQueryItem(name: "centerLat", value: String(center.latitude)),
                    URLQueryItem(name: "centerLng", value: String(center.longitude)),
                    URLQueryItem(name: "limit", value: "200"),
                    URLQueryItem(name: "cluster", value: "false")
                ]

                guard let url = validComponents.url else {
                    throw MapError.badURL // Use custom error
                }

                var request = URLRequest(url: url)
                request.addAuthenticationIfNeeded()

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw MapError.unknown // Or a more specific "invalid response type" error
                }
                
                print("MapViewModel: Received HTTP status code \(httpResponse.statusCode) for \(url.absoluteString)")


                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to decode an error message from the server if available
                    // This assumes your server sends a JSON like {"msg": "error detail"} or similar for errors
                    if let errorData = String(data: data, encoding: .utf8) {
                        print("MapViewModel: Server error response data: \(errorData)")
                        // You might want to decode this into a specific error struct
                    }
                    throw MapError.badServerResponse(statusCode: httpResponse.statusCode)
                }

                let decoder = JSONDecoder()
                let mapMoodsResponse = try decoder.decode(MapMoodsResponse.self, from: data)

                if mapMoodsResponse.success {
                    let newAnnotations = mapMoodsResponse.data.map { moodPost in
                        MoodPostAnnotation(
                            id: moodPost.id,
                            coordinate: moodPost.location.coordinates.coordinate,
                            moodPost: moodPost
                        )
                    }
                    await MainActor.run {
                        self.annotations = newAnnotations
                    }
                } else {
                    // Handle backend "success: false" case, potentially with a message from response
                    let message = "Failed to load moods (server indicated not successful)." // Replace with actual error message from response if available
                     await MainActor.run {
                        self.errorMessage = message
                        self.showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false // Ensure isLoading is set to false in all catch paths
                    if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                        print("MapViewModel: Task was cancelled.")
                        // Do not show error for cancellation
                        return
                    }
                    
                    print("MapViewModel fetchMoodPosts error: \(error)")
                    if let localizedError = error as? LocalizedError {
                        self.errorMessage = localizedError.errorDescription ?? "An unexpected error occurred."
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.showError = true
                }
            }
            // Ensure isLoading is set to false after successful completion or handled error
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Helper Functions

func formatDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

func formatRelativeTimestamp(from timestampString: String) -> String {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    guard let date = isoFormatter.date(from: timestampString) else {
        isoFormatter.formatOptions = [.withInternetDateTime]
        guard let dateWithoutFractions = isoFormatter.date(from: timestampString) else {
            return "Recently"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: dateWithoutFractions, relativeTo: Date())
    }

    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.dateTimeStyle = .named
    return formatter.localizedString(for: date, relativeTo: Date())
}

// MARK: - Extensions

extension MKCoordinateRegion {
    func getBounds() -> (sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D) {
        let halfLatDelta = self.span.latitudeDelta / 2
        let halfLngDelta = self.span.longitudeDelta / 2
        
        let sw = CLLocationCoordinate2D(
            latitude: self.center.latitude - halfLatDelta,
            longitude: self.center.longitude - halfLngDelta
        )
        let ne = CLLocationCoordinate2D(
            latitude: self.center.latitude + halfLatDelta,
            longitude: self.center.longitude + halfLngDelta
        )
        
        return (sw, ne)
    }
}
