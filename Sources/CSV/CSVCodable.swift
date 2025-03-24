// CSV: A Cross-Platform Swift 6 Library for CSV Parsing with Concurrency Support
// https://github.com/user/CSV

#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#endif

/// Protocol for types that can be converted to and from CSV rows
public protocol CSVCodable: Codable, Sendable {
    /// Initialize from a CSV row
    /// - Parameter row: The CSV row as a dictionary
    init(csvRow row: [String: String]) throws
}

extension CSV {
    /// Decode CSV rows into an array of models
    /// - Parameter type: The type to decode into
    /// - Returns: An array of decoded models
    public func decode<T: CSVCodable>(_ type: T.Type) throws -> [T] {
        guard hasHeaders else {
            throw CSVError.noHeaders
        }
        
        return try namedRows.map { row in
            try T(csvRow: row)
        }
    }
    
    /// Decode CSV rows into an array of models concurrently
    /// - Parameter type: The type to decode into
    /// - Returns: An array of decoded models
    public func decodeConcurrently<T: CSVCodable>(_ type: T.Type) async throws -> [T] {
        return try await processNamedRowsConcurrently { _, row in
            try T(csvRow: row)
        }
    }
    
    /// Encode an array of models to CSV
    /// - Parameters:
    ///   - models: The models to encode
    ///   - headers: The headers to use (defaults to the first model's keys)
    ///   - delimiter: The delimiter to use (default is comma)
    ///   - quoteCharacter: The quote character to use (default is double quote)
    /// - Returns: A CSV string
    public static func encode<T: Encodable>(_ models: [T], headers: [String]? = nil, delimiter: Character = ",", quoteCharacter: Character = "\"") throws -> String {
        guard !models.isEmpty else {
            return ""
        }
        
        // Convert models to dictionaries
        var rows: [[String: String]] = []
        
        for model in models {
            let encoder = JSONEncoder()
            let data = try encoder.encode(model)
            
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }
            
            // Convert any values to strings
            var stringValues: [String: String] = [:]
            for (key, value) in dict {
                stringValues[key] = "\(value)"
            }
            
            rows.append(stringValues)
        }
        
        // Determine headers if not provided
        let finalHeaders: [String]
        if let providedHeaders = headers {
            finalHeaders = providedHeaders
        } else if let firstRow = rows.first {
            finalHeaders = Array(firstRow.keys)
        } else {
            finalHeaders = []
        }
        
        // Create CSV string
        var csv = finalHeaders.joined(separator: String(delimiter)) + "\n"
        
        for row in rows {
            let values = finalHeaders.map { header in
                let value = row[header] ?? ""
                // Quote values with delimiter
                if value.contains(delimiter) {
                    return "\(quoteCharacter)\(value)\(quoteCharacter)"
                }
                return value
            }
            csv += values.joined(separator: String(delimiter)) + "\n"
        }
        
        return csv
    }
}
