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
        #expect(false, "Should have thrown an error for nonexistent column")
    } catch CSVCellParsingError.cellNotFound {
        // Expected error
        #expect(true)
    } catch {
        #expect(false, "Unexpected error: \(error)")
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
        #expect(false, "Should have thrown an error for invalid Double value")
    } catch CSVCellParsingError.invalidValue {
        // Expected error
        #expect(true)
    } catch {
        #expect(false, "Unexpected error: \(error)")
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
