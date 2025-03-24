// CSV: A Cross-Platform Swift 6 Library for CSV Parsing with Concurrency Support
// https://github.com/user/CSV

#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#else
// Use a minimal subset of functionality without Foundation
#endif

/// Core CSV parsing functionality with concurrency support
public struct CSV: Sendable {
    // MARK: - Properties
    
    /// The raw CSV content
    public let content: String
    
    /// The delimiter used to separate values (default is comma)
    public let delimiter: Character
    
    /// Characters to handle quotes (default is double quote)
    public let quoteCharacter: Character
    
    /// Whether headers are present
    public let hasHeaders: Bool
    
    /// Headers from the CSV (if available)
    public private(set) var headers: [String] = []
    
    /// Rows from the CSV including headers (if present)
    public private(set) var rows: [[String]] = []
    
    /// Rows from the CSV as dictionaries with headers as keys (if headers are present)
    public private(set) var namedRows: [[String: String]] = []
    
    // MARK: - Initializers
    
    /// Initialize with a CSV string
    /// - Parameters:
    ///   - content: The CSV content as a string
    ///   - delimiter: The delimiter character (default is comma)
    ///   - quoteCharacter: The quote character (default is double quote)
    ///   - hasHeaders: Whether the CSV has headers (default is true)
    public init(
        content: String,
        delimiter: Character = ",",
        quoteCharacter: Character = "\"",
        hasHeaders: Bool = true
    ) throws {
        self.content = content
        self.delimiter = delimiter
        self.quoteCharacter = quoteCharacter
        self.hasHeaders = hasHeaders
        
        try parse()
    }
    
    /// Initialize with a file path (requires Foundation or FoundationEssentials)
    /// - Parameters:
    ///   - path: Path to the CSV file
    ///   - delimiter: The delimiter character (default is comma)
    ///   - quoteCharacter: The quote character (default is double quote)
    ///   - hasHeaders: Whether the CSV has headers (default is true)
    ///   - encoding: The string encoding to use (default is UTF-8)
    #if canImport(Foundation) || canImport(FoundationEssentials)
    public init(
        path: String,
        delimiter: Character = ",",
        quoteCharacter: Character = "\"",
        hasHeaders: Bool = true,
        encoding: String.Encoding = .utf8
    ) throws {
        let content = try String(contentsOfFile: path, encoding: encoding)
        
        self.content = content
        self.delimiter = delimiter
        self.quoteCharacter = quoteCharacter
        self.hasHeaders = hasHeaders
        
        try parse()
    }
    #endif
    
    // MARK: - Async Initializers
    
    /// Initialize with a file path using async (requires Foundation or FoundationEssentials)
    /// - Parameters:
    ///   - path: Path to the CSV file
    ///   - delimiter: The delimiter character (default is comma)
    ///   - quoteCharacter: The quote character (default is double quote)
    ///   - hasHeaders: Whether the CSV has headers (default is true)
    ///   - encoding: The string encoding to use (default is UTF-8)
    #if canImport(Foundation) || canImport(FoundationEssentials)
    public static func load(
        path: String,
        delimiter: Character = ",",
        quoteCharacter: Character = "\"",
        hasHeaders: Bool = true,
        encoding: String.Encoding = .utf8
    ) async throws -> CSV {
        return try await Task {
            return try CSV(
                path: path,
                delimiter: delimiter,
                quoteCharacter: quoteCharacter,
                hasHeaders: hasHeaders,
                encoding: encoding
            )
        }.value
    }
    #endif
    
    // MARK: - Parsing
    
    /// Parse the CSV content
    private mutating func parse() throws {
        // Handle UTF-8 BOM if present
        var contentToParse = content
        if contentToParse.hasPrefix("\u{FEFF}") {
            // Remove the BOM character
            contentToParse.removeFirst()
        }
        
        // Split the content into lines
        let lines = splitIntoLines(contentToParse)
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVError.emptyContent
        }
        
        // Parse each line into rows
        rows = try lines.map { line in
            try parseLine(line)
        }
        
        // Extract headers if needed
        if hasHeaders {
            guard rows.count >= 1 else {
                throw CSVError.noHeaders
            }
            
            headers = rows[0]
            let dataRows = Array(rows.dropFirst())
            
            // Create named rows
            namedRows = dataRows.map { row in
                var namedRow: [String: String] = [:]
                for (index, header) in headers.enumerated() {
                    if index < row.count {
                        namedRow[header] = row[index]
                    } else {
                        namedRow[header] = ""
                    }
                }
                return namedRow
            }
        }
    }
    
    /// Parse a single line of CSV into fields
    /// - Parameter line: The line to parse
    /// - Returns: An array of fields
    private func parseLine(_ line: String) throws -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        
        // Process each character in the line
        for char in line {
            if char == quoteCharacter {
                // Toggle quote state
                inQuotes.toggle()
            } else if char == delimiter && !inQuotes {
                // End of field
                fields.append(currentField)
                currentField = ""
            } else {
                // Add to current field
                currentField.append(char)
            }
        }
        
        // Add the last field
        fields.append(currentField)
        
        // Check for unclosed quotes
        if inQuotes {
            throw CSVError.unclosedQuote
        }
        
        return fields
    }
    
    // MARK: - Concurrency Methods
    
    /// Process rows in parallel with a closure
    /// - Parameter process: The closure to process each row
    /// - Returns: The processed results
    public func processRowsConcurrently<T: Sendable>(_ process: @escaping @Sendable (Int, [String]) async throws -> T) async throws -> [T] {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, row) in rows.enumerated() {
                group.addTask {
                    let result = try await process(index, row)
                    return (index, result)
                }
            }
            
            var results: [(Int, T)] = []
            for try await result in group {
                results.append(result)
            }
            
            // Sort results by index to maintain row order
            results.sort { $0.0 < $1.0 }
            return results.map { $0.1 }
        }
    }
    
    /// Process named rows in parallel with a closure (only if headers are present)
    /// - Parameter process: The closure to process each named row
    /// - Returns: The processed results
    public func processNamedRowsConcurrently<T: Sendable>(_ process: @escaping @Sendable (Int, [String: String]) async throws -> T) async throws -> [T] {
        guard hasHeaders else {
            throw CSVError.noHeaders
        }
        
        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, namedRow) in namedRows.enumerated() {
                group.addTask {
                    let result = try await process(index, namedRow)
                    return (index, result)
                }
            }
            
            var results: [(Int, T)] = []
            for try await result in group {
                results.append(result)
            }
            
            // Sort results by index to maintain row order
            results.sort { $0.0 < $1.0 }
            return results.map { $0.1 }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Get a column by index
    /// - Parameter index: The column index
    /// - Returns: An array of values for the column
    public func column(at index: Int) -> [String]? {
        guard index >= 0 else { return nil }
        
        let dataRows = hasHeaders ? Array(rows.dropFirst()) : rows
        
        let values = dataRows.compactMap { row in
            index < row.count ? row[index] : nil
        }
        
        // Return nil if no values were found (out of bounds)
        return values.isEmpty ? nil : values
    }
    
    /// Get a column by name (requires headers)
    /// - Parameter name: The column name
    /// - Returns: An array of values for the column
    public func column(named name: String) -> [String]? {
        guard hasHeaders,
              let index = headers.firstIndex(of: name) else {
            return nil
        }
        
        return column(at: index)
    }
}

// MARK: - Error Types

/// Errors that can occur during CSV parsing
public enum CSVError: Error, Sendable, Equatable {
    /// The CSV content is empty
    case emptyContent
    
    /// The CSV is supposed to have headers but doesn't
    case noHeaders
    
    /// The CSV contains an unclosed quoted field
    case unclosedQuote
    
    /// Error reading file
    case fileReadError(String)
    
    public static func == (lhs: CSVError, rhs: CSVError) -> Bool {
        switch (lhs, rhs) {
        case (.emptyContent, .emptyContent):
            return true
        case (.noHeaders, .noHeaders):
            return true
        case (.unclosedQuote, .unclosedQuote):
            return true
        case (.fileReadError(let lhsMsg), .fileReadError(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - String Extensions

extension String {
    /// Split a string into lines, handling different line endings
    fileprivate func splitIntoLines() -> [String] {
        #if canImport(Foundation)
        return self.components(separatedBy: .newlines)
        #elseif canImport(FoundationEssentials)
        return self.components(separatedBy: .newlines)
        #else
        // Basic implementation for platforms without Foundation
        var lines: [String] = []
        var currentLine = ""
        
        for char in self {
            if char == "\n" || char == "\r" {
                lines.append(currentLine)
                currentLine = ""
                
                // Skip \r\n pairs
                if char == "\r" && self.dropFirst().first == "\n" {
                    continue
                }
            } else {
                currentLine.append(char)
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines
        #endif
    }
}

/// Helper function to split a string into lines
private func splitIntoLines(_ string: String) -> [String] {
    return string.splitIntoLines()
}

// MARK: - CharacterSet Extensions

/// A basic CharacterSet implementation for platforms without Foundation
#if !canImport(Foundation) && !canImport(FoundationEssentials)
public struct CharacterSet: Sendable {
    private let characters: Set<Unicode.Scalar>
    
    public static let newlines = CharacterSet(characters: ["\n", "\r"])
    
    init(characters: Set<Character>) {
        self.characters = Set(characters.flatMap { $0.unicodeScalars })
    }
    
    func contains(_ scalar: Unicode.Scalar) -> Bool {
        return characters.contains(scalar)
    }
}
#endif

#if canImport(Foundation) || canImport(FoundationEssentials)
// MARK: - Async Loading

extension CSV {
    /// Load CSV from a file asynchronously
    /// - Parameters:
    ///   - path: Path to the CSV file
    ///   - delimiter: The delimiter character (default is comma)
    ///   - hasHeaders: Whether the CSV has headers (default is true)
    /// - Returns: A CSV instance
    public static func load(path: String, delimiter: Character = ",", hasHeaders: Bool = true) async throws -> CSV {
        return try await Task {
            return try CSV(path: path, delimiter: delimiter, hasHeaders: hasHeaders)
        }.value
    }
}
#endif
