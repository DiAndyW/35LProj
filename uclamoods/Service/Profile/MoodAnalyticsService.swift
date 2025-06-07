//
//  MoodAnalyticsService.swift
//  uclamoods
//
//  Created by David Sun on 6/4/25.
//

import Foundation
import Combine // If you prefer using Combine for asynchronous operations

class MoodAnalyticsService: ObservableObject {
    @Published var analyticsData: AnalyticsData?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let baseURL = Config.apiURL(for: "/profile/analytics")
    
    // Custom DateFormatter for ISO8601 dates with fractional seconds
    private static var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    // JSONDecoder with custom date strategy
    private static var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        return decoder
    }()
    
    
    // MARK: - Fetch Analytics Data
    @MainActor
    func fetchAnalytics(period: AnalyticsPeriod) async {
        guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            self.errorMessage = "Invalid base URL."
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "period", value: period.queryValue)
        ]
        
        guard let url = urlComponents.url else {
            self.errorMessage = "Could not construct URL."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthenticationIfNeeded()
        
        isLoading = true
        errorMessage = nil
        analyticsData = nil
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            print("[MoodAnalyticsService]: HTTP Status Code: \(httpResponse.statusCode)")
            
            let decodedResponse = try MoodAnalyticsService.jsonDecoder.decode(MoodAnalyticsResponse.self, from: data)

            if (200...299).contains(httpResponse.statusCode) {
                if decodedResponse.success {
                    self.analyticsData = decodedResponse.data
                    print("[MoodAnalyticsService]: Successfully fetched analytics.")
                } else {
                    throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: decodedResponse.message ?? "API Error"])
                }
            } else {
                 throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: decodedResponse.message ?? "API Error"])
            }
        } catch {
            self.errorMessage = "Failed to fetch analytics: \(error.localizedDescription)"
            print("[MoodAnalyticsService]: Error fetching analytics: \(error)")
        }
        
        isLoading = false
    }
}
