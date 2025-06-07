// ProfanityFilterService.swift
import Foundation

class ProfanityFilterService: ObservableObject {

    private var extremelyOffensiveWords: Set<String>

    init(customOffensiveWordsFile: (name: String, type: String)? = (name: "offensive_words", type: "txt")) {
        if let fileInfo = customOffensiveWordsFile {
            self.extremelyOffensiveWords = ProfanityFilterService.loadOffensiveWordsFromFile(filename: fileInfo.name, filetype: fileInfo.type)
        } else {
            // Fallback to an empty set or a very small, hardcoded default if the file isn't specified
            print("[ProfanityFilterService]: No custom offensive words file specified. Using an empty filter list.")
            self.extremelyOffensiveWords = Set()
        }

        if self.extremelyOffensiveWords.isEmpty {
            print("[ProfanityFilterService]: The profanity filter list is empty. No words will be filtered.")
        } else {
            print("[ProfanityFilterService]: initialized with \(self.extremelyOffensiveWords.count) words.")
        }
    }

    private static func loadOffensiveWordsFromFile(filename: String, filetype: String) -> Set<String> {
        guard let filePath = Bundle.main.path(forResource: filename, ofType: filetype) else {
            print("[ProfanityFilterService]: Error: List file '\(filename).\(filetype)' not found in bundle.")
            return Set()
        }
        do {
            let fileContents = try String(contentsOfFile: filePath, encoding: .utf8)
            let words = fileContents.components(separatedBy: .newlines) // Assumes one word per line
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                                .filter { !$0.isEmpty } // Remove empty lines
            return Set(words)
        } catch {
            print("[ProfanityFilterService]: Error: Could not read list file '\(filename).\(filetype)': \(error)")
            return Set()
        }
    }

    func isContentAcceptable(text: String) -> Bool {
        if text.isEmpty {
            return true
        }
        if extremelyOffensiveWords.isEmpty { // If the list is empty, consider all content acceptable
            return true
        }

        let lowercasedText = text.lowercased()
        let wordsInText = lowercasedText.components(separatedBy: .whitespacesAndNewlines)

        for word in wordsInText {
            let cleanedWord = word.trimmingCharacters(in: .punctuationCharacters)
            if !cleanedWord.isEmpty && extremelyOffensiveWords.contains(cleanedWord) {
                print("[ProfanityFilterService]: Offensive word found - '\(cleanedWord)'")
                return false
            }
        }
        return true
    }

    func areTagsAcceptable(tags: Set<String>) -> Bool {
        if extremelyOffensiveWords.isEmpty { // If the list is empty, consider all tags acceptable
            return true
        }
        for tag in tags {
            if !isContentAcceptable(text: tag) {
                return false
            }
        }
        return true
    }
}
