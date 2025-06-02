//
//  DateFormatter.swift
//  uclamoods
//
//  Created by David Sun on 6/1/25.
//

import Foundation

struct DateFormatterUtility {
    
    // Static formatters (reused for performance)
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let simplerISOFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFullTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
    
    private static let absoluteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, YYYY"
        return formatter
    }()
    
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        formatter.formattingContext = .beginningOfSentence
        return formatter
    }()
    
    static func formatTimestampParts(timestampString: String) -> (absoluteDate: String, relativeDate: String)? {
        guard let date = parseDate(from: timestampString) else {
            return nil
        }
        
        let absoluteDateString = absoluteDateFormatter.string(from: date)
        let relativeDateString = relativeFormatter.localizedString(for: date, relativeTo: Date())
        
        return (absoluteDate: absoluteDateString, relativeDate: relativeDateString)
    }
    
    private static func parseDate(from timestampString: String) -> Date? {
        if let date = isoFormatter.date(from: timestampString) {
            return date
        }
        if let date = simplerISOFormatter.date(from: timestampString) {
            return date
        }
        print("DateFormatterUtility: Failed to parse date string: \(timestampString)")
        return nil
    }
}
