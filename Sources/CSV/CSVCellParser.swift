// CSV: A Cross-Platform Swift 6 Library for CSV Parsing with Concurrency Support
// https://github.com/user/CSV

#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#endif

/// Error types that can occur during cell parsing
public enum CSVCellParsingError: Error, Sendable, Equatable {
    case invalidValue(String, targetType: String)
    case cellNotFound(rowIndex: Int, columnName: String)
    case columnNotFound(columnName: String)
    case indexOutOfBounds(rowIndex: Int, columnIndex: Int)
    case unsupportedType(String)
}

/// Protocol for types that can be parsed from a CSV cell string
public protocol CSVCellParseable {
    /// Initialize from a CSV cell string
    /// - Parameter string: The cell value as a string
    init?(_ string: String)
}

// Make standard types conform to CSVCellParseable
extension Int: CSVCellParseable {}
extension Double: CSVCellParseable {}
extension Float: CSVCellParseable {}
extension Bool: CSVCellParseable {
    public init?(_ string: String) {
        let lowercased = string.lowercased()
        if ["true", "yes", "1"].contains(lowercased) {
            self = true
        } else if ["false", "no", "0"].contains(lowercased) {
            self = false
        } else {
            return nil
        }
    }
}
extension String: CSVCellParseable {
    public init?(_ string: String) {
        self = string
    }
}

#if canImport(Foundation) || canImport(FoundationEssentials)
extension Date: CSVCellParseable {
    public init?(_ string: String) {
        // Default implementation returns nil since we need a DateFormatter
        // Use the parseCell method with a custom parser for dates
        return nil
    }
}
#endif

extension CSV {
    // MARK: - Generic Cell Parsing
    
    /// Parse a cell value to a specific type
    /// - Parameters:
    ///   - rowIndex: The row index
    ///   - columnName: The column name
    /// - Returns: The parsed value of type T
    public func parse<T: CSVCellParseable>(at rowIndex: Int, column columnName: String) throws -> T {
        guard hasHeaders else {
            throw CSVError.noHeaders
        }
        
        guard rowIndex >= 0 && rowIndex < namedRows.count else {
            throw CSVCellParsingError.indexOutOfBounds(rowIndex: rowIndex, columnIndex: -1)
        }
        
        guard let value = namedRows[rowIndex][columnName] else {
            throw CSVCellParsingError.cellNotFound(rowIndex: rowIndex, columnName: columnName)
        }
        
        guard let result = T(value) else {
            throw CSVCellParsingError.invalidValue(value, targetType: String(describing: T.self))
        }
        
        return result
    }
    
    /// Parse a cell value to a specific type
    /// - Parameters:
    ///   - rowIndex: The row index
    ///   - columnIndex: The column index
    /// - Returns: The parsed value of type T
    public func parse<T: CSVCellParseable>(at rowIndex: Int, columnIndex: Int) throws -> T {
        guard rowIndex >= 0 && rowIndex < rows.count - (hasHeaders ? 1 : 0) else {
            throw CSVCellParsingError.indexOutOfBounds(rowIndex: rowIndex, columnIndex: columnIndex)
        }
        
        let actualRowIndex = hasHeaders ? rowIndex + 1 : rowIndex
        
        guard columnIndex >= 0 && columnIndex < rows[actualRowIndex].count else {
            throw CSVCellParsingError.indexOutOfBounds(rowIndex: rowIndex, columnIndex: columnIndex)
        }
        
        let value = rows[actualRowIndex][columnIndex]
        
        guard let result = T(value) else {
            throw CSVCellParsingError.invalidValue(value, targetType: String(describing: T.self))
        }
        
        return result
    }
    
    // MARK: - Synchronous Cell Parsing
    
    /// Parse a cell value to a specific type
    /// - Parameters:
    ///   - rowIndex: The row index
    ///   - columnName: The column name
    ///   - parser: A closure that parses the string value to the desired type
    /// - Returns: The parsed value
    public func parseCell<T>(at rowIndex: Int, column columnName: String, using parser: (String) throws -> T) throws -> T {
        guard hasHeaders else {
            throw CSVError.noHeaders
        }
        
        guard rowIndex >= 0 && rowIndex < namedRows.count else {
            throw CSVCellParsingError.indexOutOfBounds(rowIndex: rowIndex, columnIndex: -1)
        }
        
        guard let value = namedRows[rowIndex][columnName] else {
            throw CSVCellParsingError.cellNotFound(rowIndex: rowIndex, columnName: columnName)
        }
        
        do {
            return try parser(value)
        } catch {
            throw CSVCellParsingError.invalidValue(value, targetType: String(describing: T.self))
        }
    }
    
    /// Parse a cell value to a specific type
    /// - Parameters:
    ///   - rowIndex: The row index
    ///   - columnIndex: The column index
    ///   - parser: A closure that parses the string value to the desired type
    /// - Returns: The parsed value
    public func parseCell<T>(at rowIndex: Int, columnIndex: Int, using parser: (String) throws -> T) throws -> T {
        guard rowIndex >= 0 && rowIndex < rows.count - (hasHeaders ? 1 : 0) else {
            throw CSVCellParsingError.indexOutOfBounds(rowIndex: rowIndex, columnIndex: columnIndex)
        }
        
        let actualRowIndex = hasHeaders ? rowIndex + 1 : rowIndex
        
        guard columnIndex >= 0 && columnIndex < rows[actualRowIndex].count else {
            throw CSVCellParsingError.indexOutOfBounds(rowIndex: rowIndex, columnIndex: columnIndex)
        }
        
        let value = rows[actualRowIndex][columnIndex]
        
        do {
            return try parser(value)
        } catch {
            throw CSVCellParsingError.invalidValue(value, targetType: String(describing: T.self))
        }
    }
    
    // MARK: - Asynchronous Cell Parsing
    
    /// Parse a cell value to a specific type asynchronously
    /// - Parameters:
    ///   - rowIndex: The row index
    ///   - columnName: The column name
    ///   - parser: A closure that parses the string value to the desired type
    /// - Returns: The parsed value
    public func parseCellAsync<T>(at rowIndex: Int, column columnName: String, using parser: @escaping (String) async throws -> T) async throws -> T {
        guard hasHeaders else {
            throw CSVError.noHeaders
        }
        
        guard rowIndex >= 0 && rowIndex < namedRows.count else {
            throw CSVCellParsingError.indexOutOfBounds(rowIndex: rowIndex, columnIndex: -1)
        }
        
        guard let value = namedRows[rowIndex][columnName] else {
            throw CSVCellParsingError.cellNotFound(rowIndex: rowIndex, columnName: columnName)
        }
        
        do {
            return try await parser(value)
        } catch {
            throw CSVCellParsingError.invalidValue(value, targetType: String(describing: T.self))
        }
    }
    
    /// Parse a cell value to a specific type asynchronously
    /// - Parameters:
    ///   - rowIndex: The row index
    ///   - columnIndex: The column index
    ///   - parser: A closure that parses the string value to the desired type
    /// - Returns: The parsed value
    public func parseCellAsync<T>(at rowIndex: Int, columnIndex: Int, using parser: @escaping (String) async throws -> T) async throws -> T {
        guard rowIndex >= 0 && rowIndex < rows.count - (hasHeaders ? 1 : 0) else {
            throw CSVCellParsingError.indexOutOfBounds(rowIndex: rowIndex, columnIndex: columnIndex)
        }
        
        let actualRowIndex = hasHeaders ? rowIndex + 1 : rowIndex
        
        guard columnIndex >= 0 && columnIndex < rows[actualRowIndex].count else {
            throw CSVCellParsingError.indexOutOfBounds(rowIndex: rowIndex, columnIndex: columnIndex)
        }
        
        let value = rows[actualRowIndex][columnIndex]
        
        do {
            return try await parser(value)
        } catch {
            throw CSVCellParsingError.invalidValue(value, targetType: String(describing: T.self))
        }
    }
}
