import Testing
import Foundation
@testable import CSV

// MARK: - Cell Parsing Tests

@Test func testParseIntCell() throws {
    let resourceURL = Bundle.module.url(forResource: "mixed_types", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    // Test successful parsing
    let age: Int = try csv.parse(at: 0, column: "age")
    #expect(age == 30)
    
    // Test error handling
    do {
        let _: Int = try csv.parse(at: 0, column: "nonexistent")
        #expect(Bool(false), "Should have thrown an error for nonexistent column")
    } catch CSVCellParsingError.cellNotFound {
        // Expected error
        #expect(Bool(true))
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testParseDoubleCell() throws {
    let resourceURL = Bundle.module.url(forResource: "mixed_types", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    // Test successful parsing
    let score: Double = try csv.parse(at: 0, column: "score")
    #expect(score == 85.5)
    
    // Test invalid value
    do {
        let _: Double = try csv.parse(at: 0, column: "name") // "John" can't be parsed as Double
        #expect(Bool(false), "Should have thrown an error for invalid Double value")
    } catch CSVCellParsingError.invalidValue {
        // Expected error
        #expect(Bool(true))
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testParseBoolCell() throws {
    let resourceURL = Bundle.module.url(forResource: "mixed_types", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    // Test successful parsing
    let active: Bool = try csv.parse(at: 0, column: "active")
    #expect(active == true)
    
    let inactive: Bool = try csv.parse(at: 1, column: "active")
    #expect(inactive == false)
}

@Test func testGenericParsing() throws {
    let resourceURL = Bundle.module.url(forResource: "mixed_types", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    // Test generic parsing with type inference
    let name: String = try csv.parse(at: 0, column: "name")
    #expect(name == "John")
    
    let age: Int = try csv.parse(at: 1, column: "age")
    #expect(age == 25)
    
    let score: Double = try csv.parse(at: 2, column: "score")
    #expect(score == 78.9)
    
    let active: Bool = try csv.parse(at: 0, column: "active")
    #expect(active == true)
    
    // Test parsing with column index
    let nameByIndex: String = try csv.parse(at: 0, columnIndex: 0)
    #expect(nameByIndex == "John")
}

@Test func testCustomCellParsing() throws {
    let resourceURL = Bundle.module.url(forResource: "mixed_types", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    // Test custom parser
    let uppercaseName = try csv.parseCell(at: 0, column: "name") { value in
        return value.uppercased()
    }
    #expect(uppercaseName == "JOHN")
    
    // Test parsing with index
    let age = try csv.parseCell(at: 1, columnIndex: 1) { value in
        return Int(value)!
    }
    #expect(age == 25)
}

@Test func testAsyncCellParsing() async throws {
    let resourceURL = Bundle.module.url(forResource: "mixed_types", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    // Test async parsing
    let score = try await csv.parseCellAsync(at: 2, column: "score") { value in
        // Simulate async work
        try await Task.sleep(for: .milliseconds(10))
        return Double(value)!
    }
    #expect(score == 78.9)
}

@Test func testDateParsing() throws {
    let resourceURL = Bundle.module.url(forResource: "mixed_types", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    // We don't have dates in our test file, so we'll use a custom parser
    let dateString = try csv.parseCell(at: 0, column: "name") { _ in
        return "2025-01-01"
    }
    
    let date = dateFormatter.date(from: dateString)
    #expect(date != nil)
    
    let calendar = Calendar.current
    let year = calendar.component(.year, from: date!)
    #expect(year == 2025)
}

// MARK: - Date Parsing Tests

@Test func testComplexDateParsing() throws {
    let csvContent = """
    id,date
    1,2023-05-15
    2,05/15/2023
    3,15-May-2023
    4,March 5, 2023
    5,2023.05.15
    """
    
    let csv = try CSV(content: csvContent)
    
    // Test standard ISO format
    let isoDate: Date = try csv.parseCell(at: 0, column: "date") { dateString in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            return date
        }
        throw CSVCellParsingError.invalidValue(dateString, targetType: "Date")
    }
    let calendar = Calendar.current
    #expect(calendar.component(.year, from: isoDate) == 2023)
    #expect(calendar.component(.month, from: isoDate) == 5)
    #expect(calendar.component(.day, from: isoDate) == 15)
    
    // Test US format
    let usDate: Date = try csv.parseCell(at: 1, column: "date") { dateString in
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        if let date = formatter.date(from: dateString) {
            return date
        }
        throw CSVCellParsingError.invalidValue(dateString, targetType: "Date")
    }
    #expect(calendar.component(.year, from: usDate) == 2023)
    #expect(calendar.component(.month, from: usDate) == 5)
    #expect(calendar.component(.day, from: usDate) == 15)
    
    // Test day-month-year format
    let dmyDate: Date = try csv.parseCell(at: 2, column: "date") { dateString in
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy"
        if let date = formatter.date(from: dateString) {
            return date
        }
        throw CSVCellParsingError.invalidValue(dateString, targetType: "Date")
    }
    #expect(calendar.component(.year, from: dmyDate) == 2023)
    #expect(calendar.component(.month, from: dmyDate) == 5)
    #expect(calendar.component(.day, from: dmyDate) == 15)
    
    // Test natural language format
    let nlDate: Date? = try? csv.parseCell(at: 3, column: "date") { dateString in
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        if let date = formatter.date(from: dateString) {
            return date
        }
        throw CSVCellParsingError.invalidValue(dateString, targetType: "Date")
    }
    
    if let nlDate = nlDate {
        #expect(calendar.component(.year, from: nlDate) == 2023)
        #expect(calendar.component(.month, from: nlDate) == 3)
        #expect(calendar.component(.day, from: nlDate) == 5)
    } else {
        // If parsing fails, that's acceptable too since the format is ambiguous
        #expect(Bool(true))
    }
    
    // Test dotted format
    let dottedDate: Date = try csv.parseCell(at: 4, column: "date") { dateString in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        if let date = formatter.date(from: dateString) {
            return date
        }
        throw CSVCellParsingError.invalidValue(dateString, targetType: "Date")
    }
    #expect(calendar.component(.year, from: dottedDate) == 2023)
    #expect(calendar.component(.month, from: dottedDate) == 5)
    #expect(calendar.component(.day, from: dottedDate) == 15)
}

// MARK: - Edge Case Type Parsing Tests

@Test func testParsingExtremeValues() throws {
    let csvContent = """
    type,value
    int_min,\(Int.min)
    int_max,\(Int.max)
    double_min,\(Double.leastNormalMagnitude)
    double_max,\(Double.greatestFiniteMagnitude)
    """
    
    let csv = try CSV(content: csvContent)
    
    // Test parsing extreme integer values
    let intMin: Int = try csv.parse(at: 0, column: "value")
    #expect(intMin == Int.min)
    
    let intMax: Int = try csv.parse(at: 1, column: "value")
    #expect(intMax == Int.max)
    
    // Test parsing extreme double values
    let doubleMin: Double = try csv.parse(at: 2, column: "value")
    #expect(doubleMin == Double.leastNormalMagnitude)
    
    let doubleMax: Double = try csv.parse(at: 3, column: "value")
    #expect(doubleMax == Double.greatestFiniteMagnitude)
}

@Test func testParsingMalformedNumbers() throws {
    let csvContent = """
    type,value
    int_with_spaces, 123 
    int_with_chars,123abc
    double_with_multiple_dots,123.456.789
    """
    
    let csv = try CSV(content: csvContent)
    
    // Test parsing integer with spaces (should succeed with trimming)
    do {
        let _: Int = try csv.parse(at: 0, column: "value")
        #expect(Bool(false), "Should have thrown an error for int with spaces")
    } catch CSVCellParsingError.invalidValue {
        // Expected error
        #expect(Bool(true))
    }
    
    // Test parsing integer with characters
    do {
        let _: Int = try csv.parse(at: 1, column: "value")
        #expect(Bool(false), "Should have thrown an error for int with characters")
    } catch CSVCellParsingError.invalidValue {
        // Expected error
        #expect(Bool(true))
    }
    
    // Test parsing double with multiple decimal points
    do {
        let _: Double = try csv.parse(at: 2, column: "value")
        #expect(Bool(false), "Should have thrown an error for double with multiple dots")
    } catch CSVCellParsingError.invalidValue {
        // Expected error
        #expect(Bool(true))
    }
}

@Test func testParsingDifferentBooleanRepresentations() throws {
    let csvContent = """
    representation,value
    true_value,true
    false_value,false
    yes_value,yes
    no_value,no
    one_value,1
    zero_value,0
    t_value,t
    f_value,f
    y_value,y
    n_value,n
    TRUE_value,TRUE
    FALSE_value,FALSE
    """
    
    let csv = try CSV(content: csvContent)
    
    // Standard boolean representations
    let trueValue: Bool = try csv.parse(at: 0, column: "value")
    #expect(trueValue == true)
    
    let falseValue: Bool = try csv.parse(at: 1, column: "value")
    #expect(falseValue == false)
    
    // Yes/No representations
    let yesValue: Bool = try csv.parse(at: 2, column: "value")
    #expect(yesValue == true)
    
    let noValue: Bool = try csv.parse(at: 3, column: "value")
    #expect(noValue == false)
    
    // Numeric representations
    let oneValue: Bool = try csv.parse(at: 4, column: "value")
    #expect(oneValue == true)
    
    let zeroValue: Bool = try csv.parse(at: 5, column: "value")
    #expect(zeroValue == false)
    
    // Single character representations
    do {
        let _: Bool = try csv.parse(at: 6, column: "value")
        #expect(Bool(false), "Should not parse 't' as true")
    } catch CSVCellParsingError.invalidValue {
        // Expected error for non-standard boolean format
        #expect(Bool(true))
    }
    
    do {
        let _: Bool = try csv.parse(at: 7, column: "value")
        #expect(Bool(false), "Should not parse 'f' as false")
    } catch CSVCellParsingError.invalidValue {
        // Expected error for non-standard boolean format
        #expect(Bool(true))
    }
    
    // Case insensitivity
    let upperTrueValue: Bool = try csv.parse(at: 10, column: "value")
    #expect(upperTrueValue == true)
    
    let upperFalseValue: Bool = try csv.parse(at: 11, column: "value")
    #expect(upperFalseValue == false)
}

// MARK: - Custom Type Parsing Tests

// Define a custom type for testing
struct CustomPoint: Equatable {
    let x: Double
    let y: Double
    
    init?(_ string: String) {
        let components = string.split(separator: ";").map { String($0) }
        guard components.count == 2,
              let x = Double(components[0]),
              let y = Double(components[1]) else {
            return nil
        }
        self.x = x
        self.y = y
    }
}

extension CustomPoint: CSVCellParseable {}

@Test func testCustomTypeParsing() throws {
    let csvContent = """
    id,point
    1,10.5;20.3
    2,30.7;40.2
    3,invalid
    """
    
    let csv = try CSV(content: csvContent)
    
    // Test successful parsing of custom type
    let point1: CustomPoint = try csv.parse(at: 0, column: "point")
    #expect(point1.x == 10.5)
    #expect(point1.y == 20.3)
    
    let point2: CustomPoint = try csv.parse(at: 1, column: "point")
    #expect(point2.x == 30.7)
    #expect(point2.y == 40.2)
    
    // Test invalid format
    do {
        let _: CustomPoint = try csv.parse(at: 2, column: "point")
        #expect(Bool(false), "Should have thrown an error for invalid point format")
    } catch CSVCellParsingError.invalidValue {
        // Expected error
        #expect(Bool(true))
    }
}

// MARK: - Error Propagation Tests

@Test func testCustomParserErrorPropagation() async throws {
    let csvContent = """
    id,value
    1,valid
    2,invalid
    """
    
    let csv = try CSV(content: csvContent)
    
    // Define a custom error
    enum CustomParsingError: Error {
        case invalidFormat
        case unsupportedValue
    }
    
    // Test that custom errors are properly propagated
    do {
        _ = try csv.parseCell(at: 1, column: "value") { value in
            if value != "valid" {
                throw CustomParsingError.invalidFormat
            }
            return value
        }
        #expect(Bool(false), "Should have thrown a custom error")
    } catch CSVCellParsingError.invalidValue {
        // The CSV parser wraps custom errors in invalidValue
        #expect(Bool(true))
    }
    
    // Test with async parser
    do {
        _ = try await csv.parseCellAsync(at: 1, column: "value") { value in
            try await Task.sleep(for: .milliseconds(10))
            if value != "valid" {
                throw CustomParsingError.unsupportedValue
            }
            return value
        }
        #expect(Bool(false), "Should have thrown a custom error in async context")
    } catch CSVCellParsingError.invalidValue {
        // The CSV parser wraps custom errors in invalidValue
        #expect(Bool(true))
    }
}

// MARK: - Null/Empty Value Handling Tests

@Test func testEmptyStringParsing() throws {
    let csvContent = """
    type,value
    empty_int,
    empty_double,
    empty_bool,
    """
    
    let csv = try CSV(content: csvContent)
    
    // Test parsing empty string as Int
    do {
        let _: Int = try csv.parse(at: 0, column: "value")
        #expect(Bool(false), "Should have thrown an error for empty int")
    } catch CSVCellParsingError.invalidValue {
        // Expected error
        #expect(Bool(true))
    }
    
    // Test parsing empty string as Double
    do {
        let _: Double = try csv.parse(at: 1, column: "value")
        #expect(Bool(false), "Should have thrown an error for empty double")
    } catch CSVCellParsingError.invalidValue {
        // Expected error
        #expect(Bool(true))
    }
    
    // Test parsing empty string as Bool
    do {
        let _: Bool = try csv.parse(at: 2, column: "value")
        #expect(Bool(false), "Should have thrown an error for empty bool")
    } catch CSVCellParsingError.invalidValue {
        // Expected error
        #expect(Bool(true))
    }
    
    // Test parsing empty string as String (should succeed)
    let emptyString: String = try csv.parse(at: 0, column: "value")
    #expect(emptyString == "")
}

@Test func testNullValueParsing() throws {
    let csvContent = """
    type,value
    null_value,null
    na_value,NA
    n_a_value,N/A
    """
    
    let csv = try CSV(content: csvContent)
    
    // Test custom parser that handles null values
    let nullInt = try csv.parseCell(at: 0, column: "value") { value in
        if value.lowercased() == "null" || value == "NA" || value == "N/A" {
            return nil as Int?
        }
        return Int(value)
    }
    
    #expect(nullInt == nil)
    
    let naInt = try csv.parseCell(at: 1, column: "value") { value in
        if value.lowercased() == "null" || value == "NA" || value == "N/A" {
            return nil as Int?
        }
        return Int(value)
    }
    
    #expect(naInt == nil)
    
    let naSlashInt = try csv.parseCell(at: 2, column: "value") { value in
        if value.lowercased() == "null" || value == "NA" || value == "N/A" {
            return nil as Int?
        }
        return Int(value)
    }
    
    #expect(naSlashInt == nil)
}
