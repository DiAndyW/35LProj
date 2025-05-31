//
//  Config.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//

// Config.swift
import Foundation

struct Config {
    static var baseURL: URL {
        return URL(string: "http://localhost:4000")!
    }
    
    static func apiURL(for endpoint: String) -> URL {
        return baseURL.appendingPathComponent(endpoint)
    }
}
