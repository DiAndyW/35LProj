//
//  ColorData.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//
import SwiftUI
import Foundation

struct ColorData {
    static let rageRGB = (r: 208.0/255.0, g: 0.0/255.0, b: 0.0/255.0)         // #D00000
    static let euphoricRGB = (r: 255.0/255.0, g: 215.0/255.0, b: 0.0/255.0)   // #FFD700 (Gold)
    
    static let disgustedRGB = (r: 111.0/255.0, g: 45.0/255.0, b: 189.0/255.0) // #6F2DBD
    static let blissfulRGB = (r: 185.0/255.0, g: 250.0/255.0, b: 248.0/255.0)  // #B9FAF8
    
    static let miserableRGB = (r: 34.0/255.0, g: 87.0/255.0, b: 122.0/255.0)  // #22577A
    static let blessedRGB = (r: 128.0/255.0, g: 237.0/255.0, b: 153.0/255.0)  // #80ED99
    
    static func interpolateColor(pleasantness: Double, startColorRGB: (r: Double, g: Double, b: Double), endColorRGB: (r: Double, g: Double, b: Double)) -> Color {
        let t = max(0, min(1, pleasantness)) // Clamp pleasantness between 0 and 1
        let r = startColorRGB.r + (endColorRGB.r - startColorRGB.r) * t
        let g = startColorRGB.g + (endColorRGB.g - startColorRGB.g) * t
        let b = startColorRGB.b + (endColorRGB.b - startColorRGB.b) * t
        return Color(red: r, green: g, blue: b, opacity: 0.8)
    }
    
    static func getStartEndRGBs(forIntensity intensity: Double?) -> (startRGB: (r: Double, g: Double, b: Double), endRGB: (r: Double, g: Double, b: Double))? {
        guard let intensityValue = intensity else {
            return nil
        }
        
        if intensityValue >= 0.7 { // High energy
            return (startRGB: rageRGB, endRGB: euphoricRGB)
        } else if intensityValue >= 0.4 { // Medium energy
            return (startRGB: disgustedRGB, endRGB: blissfulRGB)
        } else if intensityValue < 0.4 && intensityValue >= 0.0 { // Low energy (ensure non-negative)
            return (startRGB: miserableRGB, endRGB: blessedRGB)
        } else {
            return nil
        }
    }
    
    static func calculateMoodColor(pleasantness: Double?, intensity: Double?) -> Color? {
        guard let pValue = pleasantness, let iValue = intensity else {
            return nil
        }
        // Clamp pleasantness and intensity to expected ranges if necessary (e.g., 0.0 to 1.0)
        guard let gradientRGBs = getStartEndRGBs(forIntensity: iValue) else {
            return nil // Or return a default color like Color.gray
        }
        return interpolateColor(
            pleasantness: pValue,
            startColorRGB: gradientRGBs.startRGB,
            endColorRGB: gradientRGBs.endRGB
        )
    }
}
