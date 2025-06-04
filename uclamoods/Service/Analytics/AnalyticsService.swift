//
//  AnalyticsService.swift
//  uclamoods
//
//  Created by Assistant on 6/3/25.
//

import Foundation
import CoreLocation

// MARK: - Analytics Data Models
struct MapStatsResponse: Codable {
    let success: Bool
    let bounds: MapBounds
    let data: MapStatsData
}

struct MapBounds: Codable {
    let sw: Coordinate
    let ne: Coordinate
}

struct Coordinate: Codable {
    let lat: Double
    let lng: Double
}

struct MapStatsData: Codable {
    let totalPosts: Int
    let emotionBreakdown: [String: Int]
    let postsPerDay: Double
}

struct CommunityAnalyticsData: Codable {
    let overallStats: MapStatsData
    let localStats: MapStatsData?
    let globalComparison: GlobalComparison?
    let trends: TrendData?
}

struct GlobalComparison: Codable {
    let localDominantEmotion: String
    let comparisonText: String
    let percentageDifference: Double
}

struct TrendData: Codable {
    let trendingHashtags: [String]
    let popularLocations: [String]
    let weeklyGrowth: Double
}

// MARK: - Analytics Service
class AnalyticsService: ObservableObject {
    @Published var communityData: CommunityAnalyticsData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    enum AnalyticsError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case decodingError(Error)
        case noLocationPermission
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid analytics URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from server"
            case .decodingError(let error):
                return "Failed to parse analytics data: \(error.localizedDescription)"
            case .noLocationPermission:
                return "Location permission required for local analytics"
            }
        }
    }
    
    // MARK: - Fetch Analytics Data
    func fetchCommunityAnalytics(userLocation: CLLocationCoordinate2D? = nil) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Fetch global stats (large area around UCLA or worldwide)
            let globalStats = try await fetchMapStats(
                swLat: 33.5, swLng: -119.0,  // Large area around LA
                neLat: 34.5, neLng: -117.0
            )
            
            var localStats: MapStatsData? = nil
            var comparison: GlobalComparison? = nil
            
            // Fetch local stats if user location is available
            if let userLoc = userLocation {
                localStats = try await fetchMapStats(
                    swLat: userLoc.latitude - 0.1, swLng: userLoc.longitude - 0.1,
                    neLat: userLoc.latitude + 0.1, neLng: userLoc.longitude + 0.1
                )
                
                // Generate comparison
                if let local = localStats {
                    comparison = generateComparison(global: globalStats, local: local)
                }
            }
            
            // Generate mock trend data (you can implement real endpoints for this later)
            let trends = generateMockTrends()
            
            let analyticsData = CommunityAnalyticsData(
                overallStats: globalStats,
                localStats: localStats,
                globalComparison: comparison,
                trends: trends
            )
            
            await MainActor.run {
                self.communityData = analyticsData
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Private Methods
    private func fetchMapStats(swLat: Double, swLng: Double, neLat: Double, neLng: Double) async throws -> MapStatsData {
        guard var components = URLComponents(url: Config.apiURL(for: "/api/map/stats"), resolvingAgainstBaseURL: false) else {
            throw AnalyticsError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "swLat", value: String(swLat)),
            URLQueryItem(name: "swLng", value: String(swLng)),
            URLQueryItem(name: "neLat", value: String(neLat)),
            URLQueryItem(name: "neLng", value: String(neLng))
        ]
        
        guard let url = components.url else {
            throw AnalyticsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addAuthenticationIfNeeded()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AnalyticsError.invalidResponse
        }
        
        do {
            let statsResponse = try JSONDecoder().decode(MapStatsResponse.self, from: data)
            return statsResponse.data
        } catch {
            throw AnalyticsError.decodingError(error)
        }
    }
    
    private func generateComparison(global: MapStatsData, local: MapStatsData) -> GlobalComparison {
        // Find dominant emotion in local area
        let localDominant = local.emotionBreakdown.max { $0.value < $1.value }?.key ?? "Unknown"
        
        // Calculate percentage difference
        let localCount = local.emotionBreakdown[localDominant] ?? 0
        let globalCount = global.emotionBreakdown[localDominant] ?? 0
        
        let localPercentage = local.totalPosts > 0 ? Double(localCount) / Double(local.totalPosts) * 100 : 0
        let globalPercentage = global.totalPosts > 0 ? Double(globalCount) / Double(global.totalPosts) * 100 : 0
        
        let difference = localPercentage - globalPercentage
        
        let comparisonText: String
        if abs(difference) < 5 {
            comparisonText = "\(localDominant) is trending similarly here compared to globally"
        } else if difference > 0 {
            comparisonText = "\(localDominant) is trending \(String(format: "%.1f", abs(difference)))% higher here than globally!"
        } else {
            comparisonText = "\(localDominant) is \(String(format: "%.1f", abs(difference)))% lower here than globally"
        }
        
        return GlobalComparison(
            localDominantEmotion: localDominant,
            comparisonText: comparisonText,
            percentageDifference: difference
        )
    }
    
    private func generateMockTrends() -> TrendData {
        // You can implement real trend tracking later
        return TrendData(
            trendingHashtags: ["#MindfulMoments", "#UCLAVibes", "#StudyBreak"],
            popularLocations: ["Royce Hall", "Powell Library", "Janss Steps"],
            weeklyGrowth: 12.5
        )
    }
}
