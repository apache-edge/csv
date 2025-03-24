import Testing
import Foundation
@testable import CSV

// MARK: - Basic CSV Tests

@Test func testBasicCSVParsing() throws {
    let resourceURL = Bundle.module.url(forResource: "basic", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    #expect(csv.headers == ["name", "age", "email"])
    #expect(csv.rows.count == 4)  // Including header row
    #expect(csv.namedRows.count == 3)
    #expect(csv.namedRows[0]["name"] == "John")
    #expect(csv.namedRows[1]["age"] == "25")
    #expect(csv.namedRows[2]["email"] == "bob@example.com")
}

@Test func testCSVWithDifferentDelimiter() throws {
    let resourceURL = Bundle.module.url(forResource: "semicolon", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path, delimiter: ";")
    
    #expect(csv.headers == ["name", "age", "email"])
    #expect(csv.namedRows.count == 3)
    #expect(csv.namedRows[1]["name"] == "Alice")
}

@Test func testCSVWithoutHeaders() throws {
    let resourceURL = Bundle.module.url(forResource: "no_headers", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path, hasHeaders: false)
    
    #expect(csv.headers.isEmpty)
    #expect(csv.rows.count == 3)
    #expect(csv.namedRows.isEmpty)
    #expect(csv.rows[0][0] == "John")
    #expect(csv.rows[1][1] == "25")
    #expect(csv.rows[2][2] == "bob@example.com")
}

@Test func testCSVWithQuotedFields() throws {
    let resourceURL = Bundle.module.url(forResource: "quoted", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    #expect(csv.headers == ["name", "description", "email"])
    #expect(csv.namedRows.count == 3)
    #expect(csv.namedRows[0]["description"] == "Software Engineer, Senior")
    #expect(csv.namedRows[1]["description"] == "Product Manager, AI")
    #expect(csv.namedRows[2]["description"] == "CEO, Acme Inc.")
}

@Test func testCSVWithEmptyFields() throws {
    let resourceURL = Bundle.module.url(forResource: "empty_fields", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    #expect(csv.namedRows[0]["age"] == "")
    #expect(csv.namedRows[1]["name"] == "")
    #expect(csv.namedRows[2]["email"] == "")
}

@Test func testEmptyCSVThrows() throws {
    let resourceURL = Bundle.module.url(forResource: "empty", withExtension: "csv", subdirectory: "Resources")!
    
    #expect(throws: CSVError.emptyContent) {
        _ = try CSV(path: resourceURL.path)
    }
}

@Test func testUnclosedQuotesThrows() throws {
    let resourceURL = Bundle.module.url(forResource: "unclosed_quotes", withExtension: "csv", subdirectory: "Resources")!
    
    #expect(throws: CSVError.unclosedQuote) {
        _ = try CSV(path: resourceURL.path)
    }
}

// MARK: - Column Access Tests

@Test func testColumnAccess() throws {
    let resourceURL = Bundle.module.url(forResource: "basic", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    let nameColumn = csv.column(named: "name")
    #expect(nameColumn != nil)
    #expect(nameColumn == ["John", "Alice", "Bob"])
    
    let ageColumn = csv.column(at: 1)
    #expect(ageColumn != nil)
    #expect(ageColumn == ["30", "25", "40"])
    
    let nonExistentColumn = csv.column(named: "nonexistent")
    #expect(nonExistentColumn == nil)
    
    let outOfBoundsColumn = csv.column(at: 10)
    #expect(outOfBoundsColumn == nil)
}

// MARK: - Concurrency Tests

@Test func testProcessRowsConcurrently() async throws {
    let resourceURL = Bundle.module.url(forResource: "basic", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    let results = try await csv.processRowsConcurrently { index, row in
        // Process each row (including header)
        return row.joined(separator: "-")
    }
    
    #expect(results.count == 4)
    #expect(results[0] == "name-age-email")
    #expect(results[1] == "John-30-john@example.com")
}

@Test func testProcessNamedRowsConcurrently() async throws {
    let resourceURL = Bundle.module.url(forResource: "basic", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    let results = try await csv.processNamedRowsConcurrently { index, row in
        // Process each named row
        return "\(row["name"]!)-\(row["age"]!)"
    }
    
    #expect(results.count == 3)
    #expect(results[0] == "John-30")
    #expect(results[1] == "Alice-25")
    #expect(results[2] == "Bob-40")
}

// MARK: - Codable Tests

@Test func testDecodingCSV() throws {
    let resourceURL = Bundle.module.url(forResource: "basic", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    let people = try csv.decode(Person.self)
    
    #expect(people.count == 3)
    #expect(people[0].name == "John")
    #expect(people[0].age == 30)
    #expect(people[0].email == "john@example.com")
}

@Test func testDecodingCSVConcurrently() async throws {
    let resourceURL = Bundle.module.url(forResource: "basic", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    let people = try await csv.decodeConcurrently(Person.self)
    
    #expect(people.count == 3)
    #expect(people[0].name == "John")
    #expect(people[0].age == 30)
    #expect(people[0].email == "john@example.com")
}

@Test func testEncodingToCSV() throws {
    let people = [
        try Person(csvRow: ["name": "John", "age": "30", "email": "john@example.com"]),
        try Person(csvRow: ["name": "Alice", "age": "25", "email": "alice@example.com"]),
        try Person(csvRow: ["name": "Bob", "age": "40", "email": "bob@example.com"])
    ]
    
    let csvString = try CSV.encode(people)
    
    // Create a CSV from the encoded string to validate
    let csv = try CSV(content: csvString)
    
    #expect(csv.headers.contains("name"))
    #expect(csv.headers.contains("age"))
    #expect(csv.headers.contains("email"))
    #expect(csv.namedRows.count == 3)
    #expect(csv.namedRows[0]["name"] == "John")
    #expect(csv.namedRows[1]["age"] == "25")
    #expect(csv.namedRows[2]["email"] == "bob@example.com")
}

// MARK: - Encoding Tests

@Test func testUTF8WithBOMParsing() throws {
    let resourceURL = Bundle.module.url(forResource: "utf8_with_bom", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    // Verify that the BOM is properly handled and doesn't affect parsing
    #expect(csv.headers == ["name", "age", "email"])
    #expect(csv.namedRows.count == 3)
    #expect(csv.namedRows[0]["name"] == "John")
    #expect(csv.namedRows[1]["age"] == "25")
    #expect(csv.namedRows[2]["email"] == "bob@example.com")
}

@Test func testInternationalCharacters() throws {
    let resourceURL = Bundle.module.url(forResource: "international", withExtension: "csv", subdirectory: "Resources")!
    let csv = try CSV(path: resourceURL.path)
    
    #expect(csv.headers == ["name", "country", "greeting"])
    #expect(csv.namedRows.count == 4)
    #expect(csv.namedRows[0]["name"] == "María")
    #expect(csv.namedRows[1]["greeting"] == "Bonjour!")
    #expect(csv.namedRows[2]["name"] == "日本人")
    #expect(csv.namedRows[3]["country"] == "Russia")
}

// MARK: - Async Loading Tests

@Test func testAsyncLoading() async throws {
    let resourceURL = Bundle.module.url(forResource: "basic", withExtension: "csv", subdirectory: "Resources")!
    let csv = try await CSV.load(path: resourceURL.path)
    
    #expect(csv.headers == ["name", "age", "email"])
    #expect(csv.namedRows.count == 3)
    #expect(csv.namedRows[0]["name"] == "John")
}

// MARK: - Test Helpers

/// Test model for Codable tests
struct Person: CSVCodable {
    let name: String
    let age: Int
    let email: String
    
    init(csvRow row: [String: String]) throws {
        self.name = row["name"] ?? ""
        self.age = Int(row["age"] ?? "0") ?? 0
        self.email = row["email"] ?? ""
    }
}
