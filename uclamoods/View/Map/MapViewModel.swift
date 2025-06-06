//
//  MapDataCache.swift
//  uclamoods
//
//  Created by Yang Gao on 6/3/25.
//


import SwiftUI
import MapKit
import Combine

// MARK: - Cache Management

class MapDataCache: ObservableObject {
    private var moodPostsCache: [String: (data: [MapMoodPost], timestamp: Date)] = [:]
    private var heatmapCache: [String: (data: [HeatmapPoint], timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    private let maxCacheSize = 50 // Maximum cached regions
    
    func cacheKey(for region: MKCoordinateRegion, gridSize: Int? = nil) -> String {
        let lat = String(format: "%.4f", region.center.latitude)
        let lng = String(format: "%.4f", region.center.longitude)
        let latSpan = String(format: "%.4f", region.span.latitudeDelta)
        let lngSpan = String(format: "%.4f", region.span.longitudeDelta)
        
        if let gridSize = gridSize {
            return "\(lat),\(lng),\(latSpan),\(lngSpan),\(gridSize)"
        }
        return "\(lat),\(lng),\(latSpan),\(lngSpan)"
    }
    
    func getCachedMoodPosts(for region: MKCoordinateRegion) -> [MapMoodPost]? {
        let key = cacheKey(for: region)
        guard let cached = moodPostsCache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration else {
            return nil
        }
        return cached.data
    }
    
    func cacheMoodPosts(_ posts: [MapMoodPost], for region: MKCoordinateRegion) {
        let key = cacheKey(for: region)
        moodPostsCache[key] = (posts, Date())
        cleanupCache()
    }
    
    func getCachedHeatmap(for region: MKCoordinateRegion, gridSize: Int) -> [HeatmapPoint]? {
        let key = cacheKey(for: region, gridSize: gridSize)
        guard let cached = heatmapCache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration else {
            return nil
        }
        return cached.data
    }
    
    func cacheHeatmap(_ points: [HeatmapPoint], for region: MKCoordinateRegion, gridSize: Int) {
        let key = cacheKey(for: region, gridSize: gridSize)
        heatmapCache[key] = (points, Date())
        cleanupCache()
    }
    
    private func cleanupCache() {
        // Remove oldest entries if cache is too large
        if moodPostsCache.count > maxCacheSize {
            let sortedEntries = moodPostsCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let toRemove = sortedEntries.prefix(10) // Remove 10 oldest
            for (key, _) in toRemove {
                moodPostsCache.removeValue(forKey: key)
            }
        }
        
        if heatmapCache.count > maxCacheSize {
            let sortedEntries = heatmapCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let toRemove = sortedEntries.prefix(10)
            for (key, _) in toRemove {
                heatmapCache.removeValue(forKey: key)
            }
        }
    }
    
    func clearCache() {
        moodPostsCache.removeAll()
        heatmapCache.removeAll()
    }
}

// MARK: - Request Debouncer

class RequestDebouncer: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval
    
    init(debounceInterval: TimeInterval = 0.5) {
        self.debounceInterval = debounceInterval
    }
    
    func debounce<T: Equatable>(
        _ publisher: AnyPublisher<T, Never>,
        action: @escaping (T) -> Void
    ) {
        publisher
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: action)
            .store(in: &cancellables)
    }
}

// MARK: - Region Change Detection

extension MKCoordinateRegion {
    func significantChange(from other: MKCoordinateRegion, threshold: Double = 0.001) -> Bool {
        let centerChange = abs(center.latitude - other.center.latitude) > threshold ||
                          abs(center.longitude - other.center.longitude) > threshold
        let spanChange = abs(span.latitudeDelta - other.span.latitudeDelta) > threshold ||
                        abs(span.longitudeDelta - other.span.longitudeDelta) > threshold
        return centerChange || spanChange
    }
    
    func isZoomChange(from other: MKCoordinateRegion, threshold: Double = 0.001) -> Bool {
        let spanChange = abs(span.latitudeDelta - other.span.latitudeDelta) > threshold ||
                        abs(span.longitudeDelta - other.span.longitudeDelta) > threshold
        return spanChange
    }
}

// MARK: - Optimized MapViewModel

@MainActor
class MapViewModel: ObservableObject {
    @Published var annotations: [MoodPostAnnotation] = []
    @Published var heatmapPoints: [HeatmapPoint] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let cache = MapDataCache()
    private let debouncer = RequestDebouncer(debounceInterval: 0.8) // Increased to reduce calls
    private var currentTask: Task<Void, Never>?
    private var heatmapTask: Task<Void, Never>?
    private var lastFetchedRegion: MKCoordinateRegion?
    private var lastHeatmapRegion: MKCoordinateRegion?
    private var lastGridSize: Int?
    
    // Rate limiting
    private var lastApiCall: Date = Date.distantPast
    private let minimumApiInterval: TimeInterval = 1.0 // Minimum 1 second between API calls
    private var pendingRegion: MKCoordinateRegion?
    private var rateLimitTimer: Timer?
    
    init() {
        setupRegionChangeHandling()
    }
    
    private func setupRegionChangeHandling() {
        // This would be called from your MapView when region changes
        // We'll handle the debouncing internally
    }
    
    func prefetchAdjacentRegions(for currentRegion: MKCoordinateRegion) {
        // Prefetch data for adjacent regions to improve user experience
        let prefetchDistance = currentRegion.span.latitudeDelta * 0.5
        
        let adjacentRegions = [
            // North
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: currentRegion.center.latitude + prefetchDistance,
                    longitude: currentRegion.center.longitude
                ),
                span: currentRegion.span
            ),
            // South
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: currentRegion.center.latitude - prefetchDistance,
                    longitude: currentRegion.center.longitude
                ),
                span: currentRegion.span
            ),
            // East
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: currentRegion.center.latitude,
                    longitude: currentRegion.center.longitude + prefetchDistance
                ),
                span: currentRegion.span
            ),
            // West
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: currentRegion.center.latitude,
                    longitude: currentRegion.center.longitude - prefetchDistance
                ),
                span: currentRegion.span
            )
        ]
        
        // Prefetch in background with low priority
        for region in adjacentRegions {
            if cache.getCachedMoodPosts(for: region) == nil {
                Task.detached(priority: .background) {
                    await self.performMoodPostsFetch(for: region, forceRefresh: false)
                }
            }
        }
    }
    
    func handleRegionChange(_ region: MKCoordinateRegion, viewMode: MapViewMode) {
        // Check if this is a significant change
        if let lastRegion = viewMode == .markers ? lastFetchedRegion : lastHeatmapRegion {
            if !region.significantChange(from: lastRegion, threshold: 0.002) {
                return // Not significant enough to warrant new fetch
            }
        }
        
        // Cancel pending timer
        rateLimitTimer?.invalidate()
        
        // Store pending region
        pendingRegion = region
        
        // Check rate limiting
        let timeSinceLastCall = Date().timeIntervalSince(lastApiCall)
        if timeSinceLastCall < minimumApiInterval {
            // Schedule for later
            let delay = minimumApiInterval - timeSinceLastCall
            rateLimitTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if let pendingRegion = self.pendingRegion {
                        if viewMode == .markers {
                            self.fetchMoodPosts(for: pendingRegion)
                        } else {
                            self.fetchHeatmapData(for: pendingRegion)
                        }
                    }
                }
            }
        } else {
            // Fetch immediately
            if viewMode == .markers {
                fetchMoodPosts(for: region)
            } else {
                fetchHeatmapData(for: region)
            }
        }
    }
    
    func fetchMoodPosts(for region: MKCoordinateRegion, forceRefresh: Bool = false) {
        currentTask?.cancel()
        
        // Check cache first (unless force refresh)
        if !forceRefresh, let cachedPosts = cache.getCachedMoodPosts(for: region) {
            print("📱 Using cached mood posts for region")
            updateAnnotations(with: cachedPosts)
            return
        }
        
        currentTask = Task {
            await performMoodPostsFetch(for: region, forceRefresh: forceRefresh)
        }
    }
    
    private func performMoodPostsFetch(for region: MKCoordinateRegion, forceRefresh: Bool) async {
        await MainActor.run {
            if !forceRefresh && isLoading { return }
            isLoading = true
        }
        
        do {
            lastApiCall = Date()
            _ = region.getBounds()
            let center = region.center
            
            let components = URLComponents(url: Config.apiURL(for: "/api/map/moods"), resolvingAgainstBaseURL: false)
            guard var validComponents = components else {
                throw MapError.badURL
            }
            
            // Optimize query parameters - request larger area to reduce subsequent calls
            let bufferFactor: Double = 1.2 // Request 20% larger area
            let bufferedLatDelta = region.span.latitudeDelta * bufferFactor
            let bufferedLngDelta = region.span.longitudeDelta * bufferFactor
            
            let bufferedSW = CLLocationCoordinate2D(
                latitude: center.latitude - bufferedLatDelta / 2,
                longitude: center.longitude - bufferedLngDelta / 2
            )
            let bufferedNE = CLLocationCoordinate2D(
                latitude: center.latitude + bufferedLatDelta / 2,
                longitude: center.longitude + bufferedLngDelta / 2
            )
            
            validComponents.queryItems = [
                URLQueryItem(name: "swLat", value: String(bufferedSW.latitude)),
                URLQueryItem(name: "swLng", value: String(bufferedSW.longitude)),
                URLQueryItem(name: "neLat", value: String(bufferedNE.latitude)),
                URLQueryItem(name: "neLng", value: String(bufferedNE.longitude)),
                URLQueryItem(name: "centerLat", value: String(center.latitude)),
                URLQueryItem(name: "centerLng", value: String(center.longitude)),
                URLQueryItem(name: "limit", value: "200"),
                URLQueryItem(name: "cluster", value: "false")
            ]
            
            guard let url = validComponents.url else {
                throw MapError.badURL
            }
            
            var request = URLRequest(url: url)
            request.addAuthenticationIfNeeded()
            request.timeoutInterval = 10.0 // Add timeout
            
            print("Fetching mood posts from API for region: \(region.center)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MapError.unknown
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw MapError.badServerResponse(statusCode: httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let mapMoodsResponse = try decoder.decode(MapMoodsResponse.self, from: data)
            
            if mapMoodsResponse.success {
                // Cache the result
                cache.cacheMoodPosts(mapMoodsResponse.data, for: region)
                lastFetchedRegion = region
                
                await MainActor.run {
                    updateAnnotations(with: mapMoodsResponse.data)
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Failed to load moods"
                    self.showError = true
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                    return
                }
                
                // Handle rate limiting errors specifically
                if let urlError = error as? URLError, urlError.code.rawValue == 400 {
                    self.errorMessage = "Too many requests. Please wait a moment and try again."
                } else if let localizedError = error as? LocalizedError {
                    self.errorMessage = localizedError.errorDescription ?? "An unexpected error occurred."
                } else {
                    self.errorMessage = error.localizedDescription
                }
                self.showError = true
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func updateAnnotations(with moodPosts: [MapMoodPost]) {
        let newAnnotations = moodPosts.map { moodPost in
            MoodPostAnnotation(
                id: moodPost.id,
                coordinate: moodPost.location.coordinates.coordinate,
                moodPost: moodPost
            )
        }
        self.annotations = newAnnotations
    }
    
    func fetchHeatmapData(for region: MKCoordinateRegion) {
        heatmapTask?.cancel()
        
        let gridSize = calculateGridSize(for: region)
        
        // Check cache first
        if let cachedHeatmap = cache.getCachedHeatmap(for: region, gridSize: gridSize) {
            print("📱 Using cached heatmap for region")
            heatmapPoints = cachedHeatmap
            return
        }
        
        heatmapTask = Task {
            await performHeatmapFetch(for: region, gridSize: gridSize)
        }
    }
    
    private func performHeatmapFetch(for region: MKCoordinateRegion, gridSize: Int) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            lastApiCall = Date()
            let bounds = region.getBounds()
            
            let components = URLComponents(url: Config.apiURL(for: "/api/map/moods/heatmap"), resolvingAgainstBaseURL: false)
            guard var validComponents = components else {
                throw MapError.badURL
            }
            
            validComponents.queryItems = [
                URLQueryItem(name: "swLat", value: String(bounds.sw.latitude)),
                URLQueryItem(name: "swLng", value: String(bounds.sw.longitude)),
                URLQueryItem(name: "neLat", value: String(bounds.ne.latitude)),
                URLQueryItem(name: "neLng", value: String(bounds.ne.longitude)),
                URLQueryItem(name: "gridSize", value: String(gridSize))
            ]
            
            guard let url = validComponents.url else {
                throw MapError.badURL
            }
            
            var request = URLRequest(url: url)
            request.addAuthenticationIfNeeded()
            request.timeoutInterval = 10.0
            
            print("Fetching heatmap from API for region: \(region.center)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MapError.unknown
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw MapError.badServerResponse(statusCode: httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let heatmapResponse = try decoder.decode(HeatmapResponse.self, from: data)
            
            if heatmapResponse.success {
                // Cache the result
                cache.cacheHeatmap(heatmapResponse.data, for: region, gridSize: gridSize)
                lastHeatmapRegion = region
                lastGridSize = gridSize
                
                await MainActor.run {
                    self.heatmapPoints = heatmapResponse.data
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Failed to load heatmap data"
                    self.showError = true
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                    return
                }
                
                if let urlError = error as? URLError, urlError.code.rawValue == 400 {
                    self.errorMessage = "Too many requests. Please wait a moment and try again."
                } else if let localizedError = error as? LocalizedError {
                    self.errorMessage = localizedError.errorDescription ?? "An unexpected error occurred."
                } else {
                    self.errorMessage = error.localizedDescription
                }
                self.showError = true
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func calculateGridSize(for region: MKCoordinateRegion) -> Int {
        let span = max(region.span.latitudeDelta, region.span.longitudeDelta)
        
        if span > 1.0 {
            return 20
        } else if span > 0.5 {
            return 30
        } else if span > 0.1 {
            return 40
        } else if span > 0.05 {
            return 50
        } else {
            return 60
        }
    }
    
    func clearCache() {
        cache.clearCache()
    }
}

// MARK: - Error Types

enum MapError: Error, LocalizedError {
    case badURL
    case requestFailed(Error)
    case badServerResponse(statusCode: Int)
    case decodingError(Error)
    case rateLimited
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
        case .rateLimited:
            return "Too many requests. Please wait a moment before trying again."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
