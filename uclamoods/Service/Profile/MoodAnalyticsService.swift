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
    
    private var cancellables = Set<AnyCancellable>() // For Combine
    
    // Define your base URL
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
    func fetchAnalytics(period: AnalyticsPeriod) {
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
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse) // Or a custom error
                }
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if !(200...299).contains(httpResponse.statusCode) {
                    // Try to decode error message from backend if available
                    if let errorData = try? MoodAnalyticsService.jsonDecoder.decode(MoodAnalyticsResponse.self, from: output.data) {
                        throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorData.message ?? "API Error"])
                    }
                    throw URLError(URLError.Code(rawValue: httpResponse.statusCode))
                }
                return output.data
            }
            .decode(type: MoodAnalyticsResponse.self, decoder: MoodAnalyticsService.jsonDecoder)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                    case .failure(let error):
                        self?.errorMessage = "Failed to fetch analytics: \(error.localizedDescription)"
                        print("Error fetching analytics: \(error)")
                    case .finished:
                        print("Successfully fetched analytics.")
                        break
                }
            }, receiveValue: { [weak self] response in
                if response.success {
                    self?.analyticsData = response.data
                } else {
                    self?.errorMessage = response.message ?? "An unknown error occurred."
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Example Usage (Illustrative)
    // You would call this from your SwiftUI View or ViewModel
    func loadAnalyticsExample() {
        fetchAnalytics(period: .month)
    }
}
