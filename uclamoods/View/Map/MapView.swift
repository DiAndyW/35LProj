import SwiftUI
import MapKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Data Models

extension MKCoordinateSpan: @retroactive Equatable {
    public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        return lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }
}

// 3. Make MKCoordinateRegion Equatable
extension MKCoordinateRegion: @retroactive Equatable {
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
    let likesCount: Int      // Expects JSON key "likesCount"
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
            likes: nil,
            comments: nil,
            likesCount: likesCount,
            commentsCount: commentsCount
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
        moodPost.emotion.color ?? EmotionColorMap.getColor(for: moodPost.emotion.name)
    }
}

// MARK: - Heatmap Data Models

struct HeatmapPoint: Codable {
    let lat: Double
    let lng: Double
    let intensity: Int
    let dominantEmotion: SimpleEmotion?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

struct HeatmapResponse: Codable {
    let success: Bool
    let gridSize: Int
    let bounds: Viewport
    let data: [HeatmapPoint]
}

// MARK: - Heatmap Overlay

class HeatmapOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    let heatmapData: [HeatmapPoint]
    
    init(heatmapData: [HeatmapPoint], region: MKCoordinateRegion) {
        self.heatmapData = heatmapData
        self.coordinate = region.center
        
        // Calculate bounding rect from region
        let topLeft = CLLocationCoordinate2D(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude - region.span.longitudeDelta / 2
        )
        let bottomRight = CLLocationCoordinate2D(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )
        
        let topLeftPoint = MKMapPoint(topLeft)
        let bottomRightPoint = MKMapPoint(bottomRight)
        
        self.boundingMapRect = MKMapRect(
            x: topLeftPoint.x,
            y: topLeftPoint.y,
            width: bottomRightPoint.x - topLeftPoint.x,
            height: bottomRightPoint.y - topLeftPoint.y
        )
        
        super.init()
    }
}

// MARK: - Heatmap Renderer

// MARK: - Updated Heatmap Renderer with Emotion-Based Colors

class HeatmapOverlayRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? HeatmapOverlay else { return }
        
        let rect = self.rect(for: overlay.boundingMapRect)
        
        // Find max intensity for normalization
        let maxIntensity = overlay.heatmapData.map { $0.intensity }.max() ?? 1
        
        // Draw each heatmap point with its emotion-based color
        for point in overlay.heatmapData {
            let mapPoint = MKMapPoint(point.coordinate)
            let pointRect = self.point(for: mapPoint)
            
            // Skip if point is outside visible rect
            if !rect.contains(pointRect) { continue }
            
            // Calculate radius based on zoom scale
            let radius = 50.0 / zoomScale
            
            // Normalize intensity (0.0 to 1.0)
            let normalizedIntensity = CGFloat(point.intensity) / CGFloat(maxIntensity)
            
            // Get emotion-based color
            let emotionColor = getEmotionBasedColor(for: point, intensity: normalizedIntensity)
            
            // Create radial gradient for this specific emotion
            let gradient = createEmotionGradient(baseColor: emotionColor, intensity: normalizedIntensity)
            
            // Draw radial gradient for this point
            context.saveGState()
            context.addEllipse(in: CGRect(
                x: pointRect.x - radius,
                y: pointRect.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.clip()
            
            // Draw gradient
            context.drawRadialGradient(
                gradient,
                startCenter: pointRect,
                startRadius: 0,
                endCenter: pointRect,
                endRadius: radius,
                options: []
            )
            
            context.restoreGState()
        }
    }
    
    // MARK: - Emotion Color Mapping
    
    private func getEmotionBasedColor(for point: HeatmapPoint, intensity: CGFloat) -> UIColor {
        // If we have a dominant emotion, use its color
        if let dominantEmotion = point.dominantEmotion {
            let emotionColor = EmotionColorMap.getColor(for: dominantEmotion.name)
            return UIColor(emotionColor)
        }
        
        // Fallback: categorize by intensity level with emotion-appropriate colors
        return getIntensityBasedEmotionColor(intensity: intensity)
    }
    
    private func getIntensityBasedEmotionColor(intensity: CGFloat) -> UIColor {
        // Map intensity to emotion-like colors rather than rainbow
        switch intensity {
            case 0.0..<0.2:
                // Low intensity - calm, peaceful emotions (soft blues/greens)
                return UIColor(red: 0.5, green: 0.8, blue: 0.6, alpha: 1.0) // Soft teal
            case 0.2..<0.4:
                // Low-medium intensity - content emotions (gentle blues)
                return UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0) // Calm blue
            case 0.4..<0.6:
                // Medium intensity - neutral to positive (warm yellows)
                return UIColor(red: 0.9, green: 0.8, blue: 0.3, alpha: 1.0) // Warm yellow
            case 0.6..<0.8:
                // High intensity - excited/energetic (vibrant oranges)
                return UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // Energetic orange
            default:
                // Very high intensity - intense emotions (deep reds)
                return UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) // Intense red
        }
    }
    
    private func createEmotionGradient(baseColor: UIColor, intensity: CGFloat) -> CGGradient {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Create a gradient from transparent to the emotion color
        // Adjust alpha based on intensity
        let clearColor = UIColor.clear
        let lowAlphaColor = baseColor.withAlphaComponent(0.2 * intensity)
        let mediumAlphaColor = baseColor.withAlphaComponent(0.5 * intensity)
        let highAlphaColor = baseColor.withAlphaComponent(0.8 * intensity)
        
        let colors = [
            clearColor.cgColor,
            lowAlphaColor.cgColor,
            mediumAlphaColor.cgColor,
            highAlphaColor.cgColor
        ]
        
        let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]
        
        return CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: locations
        )!
    }
}

// MARK: - Alternative: Blended Emotion Heatmap Renderer
// Use this version if you want to blend multiple emotions in an area

class BlendedEmotionHeatmapRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? HeatmapOverlay else { return }
        
        let rect = self.rect(for: overlay.boundingMapRect)
        let maxIntensity = overlay.heatmapData.map { $0.intensity }.max() ?? 1
        
        // Group nearby points for color blending
        let groupedPoints = groupNearbyPoints(overlay.heatmapData, threshold: 0.001) // ~100m
        
        for group in groupedPoints {
            let centerPoint = calculateCenterPoint(of: group)
            let blendedColor = blendEmotionColors(from: group)
            let totalIntensity = group.reduce(0) { $0 + $1.intensity }
            let normalizedIntensity = CGFloat(totalIntensity) / CGFloat(maxIntensity * group.count)
            
            let mapPoint = MKMapPoint(centerPoint)
            let pointRect = self.point(for: mapPoint)
            
            if !rect.contains(pointRect) { continue }
            
            let radius = 60.0 / zoomScale // Slightly larger for blended areas
            
            let gradient = createBlendedGradient(color: blendedColor, intensity: normalizedIntensity)
            
            context.saveGState()
            context.addEllipse(in: CGRect(
                x: pointRect.x - radius,
                y: pointRect.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.clip()
            
            context.drawRadialGradient(
                gradient,
                startCenter: pointRect,
                startRadius: 0,
                endCenter: pointRect,
                endRadius: radius,
                options: []
            )
            
            context.restoreGState()
        }
    }
    
    private func groupNearbyPoints(_ points: [HeatmapPoint], threshold: Double) -> [[HeatmapPoint]] {
        var groups: [[HeatmapPoint]] = []
        var processed: Set<Int> = []
        
        for (index, point) in points.enumerated() {
            if processed.contains(index) { continue }
            
            var group = [point]
            processed.insert(index)
            
            // Find nearby points
            for (otherIndex, otherPoint) in points.enumerated() {
                if processed.contains(otherIndex) { continue }
                
                let distance = calculateDistance(from: point.coordinate, to: otherPoint.coordinate)
                if distance < threshold {
                    group.append(otherPoint)
                    processed.insert(otherIndex)
                }
            }
            
            groups.append(group)
        }
        
        return groups
    }
    
    private func calculateCenterPoint(of points: [HeatmapPoint]) -> CLLocationCoordinate2D {
        let totalLat = points.reduce(0.0) { $0 + $1.lat }
        let totalLng = points.reduce(0.0) { $0 + $1.lng }
        return CLLocationCoordinate2D(
            latitude: totalLat / Double(points.count),
            longitude: totalLng / Double(points.count)
        )
    }
    
    private func blendEmotionColors(from points: [HeatmapPoint]) -> UIColor {
        var totalRed: CGFloat = 0
        var totalGreen: CGFloat = 0
        var totalBlue: CGFloat = 0
        var totalWeight: CGFloat = 0
        
        for point in points {
            let weight = CGFloat(point.intensity)
            let color: UIColor
            
            if let emotion = point.dominantEmotion {
                color = UIColor(EmotionColorMap.getColor(for: emotion.name))
            } else {
                color = UIColor.gray
            }
            
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            totalRed += red * weight
            totalGreen += green * weight
            totalBlue += blue * weight
            totalWeight += weight
        }
        
        guard totalWeight > 0 else { return UIColor.gray }
        
        return UIColor(
            red: totalRed / totalWeight,
            green: totalGreen / totalWeight,
            blue: totalBlue / totalWeight,
            alpha: 1.0
        )
    }
    
    private func createBlendedGradient(color: UIColor, intensity: CGFloat) -> CGGradient {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let colors = [
            UIColor.clear.cgColor,
            color.withAlphaComponent(0.1 * intensity).cgColor,
            color.withAlphaComponent(0.4 * intensity).cgColor,
            color.withAlphaComponent(0.7 * intensity).cgColor
        ]
        
        let locations: [CGFloat] = [0.0, 0.4, 0.8, 1.0]
        
        return CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: locations
        )!
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // Convert to km
    }
}

// MARK: - Map View Mode

enum MapViewMode {
    case markers
    case heatmap
}

// MARK: - Updated MapView for iOS 17
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedMoodPost: MapMoodPost?
    @State private var showingMoodDetail = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0689, longitude: -118.4452),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var viewMode: MapViewMode = .markers
    @State private var lastRegionChangeTime = Date()
    @State private var regionChangeTimer: Timer?
    @State private var mapSelection: String?
    @State private var isFollowingUser = false
    
    // Track the current visible region for API calls
    @State private var visibleRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0689, longitude: -118.4452),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        ZStack {
            // Main Map Content
            if viewMode == .markers {
                markersMapView
            } else {
                // For heatmap, we still need UIViewRepresentable due to overlay requirements
                HeatmapMapView(
                    region: $visibleRegion,
                    tracking: $isFollowingUser,
                    heatmapData: viewModel.heatmapPoints,
                    onRegionChange: handleRegionChange
                )
                .ignoresSafeArea()
            }
            
            // Overlay Controls
            mapControlsOverlay
        }
        .sheet(isPresented: $showingMoodDetail) {
            if let moodPost = selectedMoodPost {
                MapPostDetailView(moodPost: moodPost)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewMode) { oldMode, newMode in
            handleViewModeChange(newMode)
        }
        .onAppear {
            setupInitialLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingMapLocation()
            regionChangeTimer?.invalidate()
        }
    }
    
    // MARK: - Markers Map View (iOS 17 Style)
    @ViewBuilder
    private var markersMapView: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
            // User Location Annotation
            if let userCoord = locationManager.userCoordinates {
                Annotation("Me", coordinate: userCoord) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 32, height: 32)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
                .annotationTitles(.hidden)
            }
            
            // Mood Post Annotations
            ForEach(viewModel.annotations) { annotation in
                Annotation(
                    annotation.moodPost.emotion.name,
                    coordinate: annotation.coordinate,
                    anchor: .bottom
                ) {
                    MoodPostMarkerView(annotation: annotation) {
                        selectedMoodPost = annotation.moodPost
                        showingMoodDetail = true
                    }
                }
                .tag(annotation.id)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            handleCameraChange(context)
        }
        .onChange(of: mapSelection) { _, newSelection in
            if let selection = newSelection,
               let annotation = viewModel.annotations.first(where: { $0.id == selection }) {
                selectedMoodPost = annotation.moodPost
                showingMoodDetail = true
            }
        }
    }
    
    // MARK: - Map Controls Overlay
    @ViewBuilder
    private var mapControlsOverlay: some View {
        VStack {
            HStack {
                // View Mode Toggle
                Picker("View Mode", selection: $viewMode) {
                    Label("Markers", systemImage: "mappin.circle.fill")
                        .tag(MapViewMode.markers)
                    Label("Heatmap", systemImage: "heat.waves")
                        .tag(MapViewMode.heatmap)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                
                Spacer()
                
                // Control Buttons
//                HStack(spacing: 12) {
//                    // Refresh Button
//                    Button(action: refreshData) {
//                        Image(systemName: "arrow.clockwise")
//                            .foregroundColor(.white)
//                            .frame(width: 44, height: 44)
//                            .background(Color.black.opacity(0.7))
//                            .clipShape(Circle())
//                    }
//                }
            }
            .padding()
            
            Spacer()
            
            // Status Bar
            statusBar
        }
    }
    
    // MARK: - Status Bar
    @ViewBuilder
    private var statusBar: some View {
        if viewModel.isLoading || shouldShowStatus {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                if let statusText = statusText {
                    Text(statusText)
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding()
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
        }
    }
    
    private var shouldShowStatus: Bool {
        (viewMode == .markers && !viewModel.annotations.isEmpty) ||
        (viewMode == .heatmap && !viewModel.heatmapPoints.isEmpty) ||
        viewModel.isLoading
    }
    
    private var statusText: String? {
        if viewMode == .markers && !viewModel.annotations.isEmpty {
            return "\(viewModel.annotations.count) mood\(viewModel.annotations.count == 1 ? "" : "s") nearby"
        } else if viewMode == .heatmap && !viewModel.heatmapPoints.isEmpty {
            return "Showing mood intensity heatmap"
        }
        return nil
    }
    
    // MARK: - Helper Methods
    private func setupInitialLocation() {
        locationManager.startUpdatingMapLocation()
        
        if let userCoord = locationManager.userCoordinates {
            let region = MKCoordinateRegion(
                center: userCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            visibleRegion = region
            cameraPosition = .region(region)
            isFollowingUser = true
        }
        
        // Initial fetch
        viewModel.handleRegionChange(visibleRegion, viewMode: viewMode)
    }
    
    private func handleCameraChange(_ context: MapCameraUpdateContext) {
        // Update visible region
        visibleRegion = context.region
        
        // Cancel any existing timer
        regionChangeTimer?.invalidate()
        
        // Debounce region changes
        regionChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            handleRegionChange(context.region)
        }
        
        // Update following status
        if let userCoord = locationManager.userCoordinates {
            let distance = CLLocation(
                latitude: context.region.center.latitude,
                longitude: context.region.center.longitude
            ).distance(from: CLLocation(
                latitude: userCoord.latitude,
                longitude: userCoord.longitude
            ))
            
            isFollowingUser = distance < 100 // Within 100 meters
        }
    }
    
    private func handleRegionChange(_ newRegion: MKCoordinateRegion) {
        lastRegionChangeTime = Date()
        viewModel.handleRegionChange(newRegion, viewMode: viewMode)
    }
    
    private func handleViewModeChange(_ newMode: MapViewMode) {
        viewModel.handleRegionChange(visibleRegion, viewMode: newMode)
    }
    
    private func refreshData() {
        if viewMode == .markers {
            viewModel.fetchMoodPosts(for: visibleRegion, forceRefresh: true)
        } else {
            viewModel.fetchHeatmapData(for: visibleRegion)
        }
    }
}

// MARK: - Updated Mood Post Marker View
struct MoodPostMarkerView: View {
    let annotation: MoodPostAnnotation
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Mood color marker
                Circle()
                    .fill(annotation.color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: annotation.color.opacity(0.3), radius: 4)
                
                // Pin tail
                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(annotation.color)
                    .rotationEffect(.degrees(180))
                    .offset(y: -2)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}

// MARK: - Updated Heatmap View (Still needs UIViewRepresentable)
struct HeatmapMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var tracking: Bool
    let heatmapData: [HeatmapPoint]
    let onRegionChange: (MKCoordinateRegion) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = tracking ? .follow : .none
        mapView.setRegion(region, animated: false)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update tracking mode
        if mapView.userTrackingMode != (tracking ? .follow : .none) {
            mapView.setUserTrackingMode(tracking ? .follow : .none, animated: true)
        }
        
        // Update region if needed
        if !context.coordinator.isUserInteracting {
            let currentRegion = mapView.region
            if !region.isEqual(to: currentRegion, threshold: 0.0001) {
                mapView.setRegion(region, animated: true)
            }
        }
        
        // Update overlays
        let coordinator = context.coordinator
        if coordinator.shouldUpdateOverlays(with: heatmapData) {
            mapView.removeOverlays(mapView.overlays)
            if !heatmapData.isEmpty {
                let overlay = HeatmapOverlay(heatmapData: heatmapData, region: region)
                mapView.addOverlay(overlay)
            }
            coordinator.updateHeatmapData(heatmapData)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: HeatmapMapView
        var isUserInteracting = false
        private var regionChangeTimer: Timer?
        private var cachedHeatmapData: [HeatmapPoint] = []
        
        init(_ parent: HeatmapMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isUserInteracting = true
            regionChangeTimer?.invalidate()
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
            
            regionChangeTimer?.invalidate()
            regionChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                self?.isUserInteracting = false
                self?.parent.onRegionChange(mapView.region)
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is HeatmapOverlay {
                return BlendedEmotionHeatmapRenderer(overlay: overlay)
            }
            return MKOverlayRenderer()
        }
        
        func shouldUpdateOverlays(with newData: [HeatmapPoint]) -> Bool {
            guard cachedHeatmapData.count == newData.count else { return true }
            
            for (index, point) in newData.enumerated() {
                if index >= cachedHeatmapData.count ||
                    cachedHeatmapData[index].lat != point.lat ||
                    cachedHeatmapData[index].lng != point.lng ||
                    cachedHeatmapData[index].intensity != point.intensity {
                    return true
                }
            }
            return false
        }
        
        func updateHeatmapData(_ newData: [HeatmapPoint]) {
            cachedHeatmapData = newData
        }
    }
}

// MARK: - Region Equality Extension

extension MKCoordinateRegion {
    func isEqual(to other: MKCoordinateRegion, threshold: Double) -> Bool {
        let centerEqual = abs(center.latitude - other.center.latitude) < threshold &&
        abs(center.longitude - other.center.longitude) < threshold
        let spanEqual = abs(span.latitudeDelta - other.span.latitudeDelta) < threshold &&
        abs(span.longitudeDelta - other.span.longitudeDelta) < threshold
        return centerEqual && spanEqual
    }
}

// MARK: - Efficient Annotation Updates

extension MapViewModel {
    func updateAnnotationsEfficiently(with newPosts: [MapMoodPost]) {
        // Convert to set for O(1) lookup
        let newPostIds = Set(newPosts.map { $0.id })
        let existingIds = Set(annotations.map { $0.id })
        
        // Only update if there are actual changes
        if newPostIds != existingIds {
            let newAnnotations = newPosts.map { moodPost in
                MoodPostAnnotation(
                    id: moodPost.id,
                    coordinate: moodPost.location.coordinates.coordinate,
                    moodPost: moodPost
                )
            }
            
            DispatchQueue.main.async {
                self.annotations = newAnnotations
            }
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

struct MapPostDetailView: View {
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
                        MoodPostCard(post: moodPost.asFeedItem, openDetailAction: {})
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
                                tint: post.emotion.color ?? EmotionColorMap.getColor(for: post.emotion.name)
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
