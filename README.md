# CSV

A Cross-Platform Swift 6 Library for CSV Parsing with Concurrency Support

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20watchOS%20|%20tvOS%20|%20Linux%20|%20Android%20|%20Windows-blue.svg)](https://swift.org)
[![macOS](https://img.shields.io/github/actions/workflow/status/apache-edge/csv/swift.yml?branch=main&label=macOS)](https://github.com/apache-edge/csv/actions/workflows/swift.yml)
[![Linux](https://img.shields.io/github/actions/workflow/status/apache-edge/csv/swift.yml?branch=main&label=Linux)](https://github.com/apache-edge/csv/actions/workflows/swift.yml)
[![Windows](https://img.shields.io/github/actions/workflow/status/apache-edge/csv/swift.yml?branch=main&label=Windows)](https://github.com/apache-edge/csv/actions/workflows/swift.yml)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)


A cross-platform Swift 6 library for CSV parsing with concurrency support. Works on Apple platforms (iOS, macOS, tvOS, watchOS), Linux, Android, and Windows.

## Features

- ✅ Cross-platform: Works on all Swift-supported platforms
- ✅ Swift Concurrency: Built with Swift's concurrency model
- ✅ Modern Swift: Designed for Swift 6
- ✅ Codable Support: Simple conversion between CSV and Swift types
- ✅ Flexible: Works with different delimiters, quote characters, and header options
- ✅ Type-safe: Strong typing for all operations
- ✅ Performance: Parallel processing of CSV rows

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/apache-edge/csv.git", from: "0.0.1")
]
```

## Basic Usage

### Parse a CSV string

```swift
import CSV

let csvString = """
name,age,email
John,30,john@example.com
Alice,25,alice@example.com
Bob,40,bob@example.com
"""

do {
    let csv = try CSV(content: csvString)
    
    // Access headers
    print(csv.headers) // ["name", "age", "email"]
    
    // Access rows as dictionaries
    for row in csv.namedRows {
        print("\(row["name"]!) is \(row["age"]!) years old")
    }
    
    // Access a specific column
    if let emails = csv.column(named: "email") {
        print("All emails: \(emails)")
    }
} catch {
    print("Error parsing CSV: \(error)")
}
```

### Parse a CSV file

```swift
import CSV

do {
    // Synchronous API
    let csv = try CSV(path: "path/to/file.csv")
    
    // Asynchronous API
    let csvAsync = try await CSV.load(path: "path/to/file.csv")
    
    // Work with data...
} catch {
    print("Error parsing CSV: \(error)")
}
```

## Concurrency Features

Process rows in parallel using Swift's concurrency model:

```swift
import CSV

let csv = try CSV(content: csvString)

// Process all rows concurrently and collect results
let results = try await csv.processRowsConcurrently { index, row in
    // Do some heavy processing...
    return processedValue
}

// Process named rows (with headers)
let namedResults = try await csv.processNamedRowsConcurrently { index, row in
    return row["name"]!.uppercased()
}
```

## Codable Support

Easily convert between CSV and your Swift types:

```swift
import CSV

// Define a model conforming to CSVCodable
struct Person: CSVCodable {
    let name: String
    let age: Int
    let email: String
    
    // Required initializer
    init(csvRow row: [String: String]) throws {
        self.name = row["name"] ?? ""
        self.age = Int(row["age"] ?? "0") ?? 0
        self.email = row["email"] ?? ""
    }
}

// Decode from CSV
let csv = try CSV(content: csvString)
let people = try csv.decode(Person.self)

// Work with strongly-typed objects
for person in people {
    print("\(person.name) is \(person.age) years old")
}

// Decode concurrently for better performance
let peopleConcurrent = try await csv.decodeConcurrently(Person.self)

// Encode back to CSV
let newCsvString = try CSV.encode(people)
```

## Cell Parsing

Parse individual cells with type safety and error handling:

```swift
import CSV

let csv = try CSV(content: csvString)

// Parse cells with type inference
let name: String = try csv.parse(at: 0, column: "name")
let age: Int = try csv.parse(at: 0, column: "age")
let score: Double = try csv.parse(at: 0, column: "score")
let isActive: Bool = try csv.parse(at: 0, column: "active")

// Parse cells by column index
let firstName: String = try csv.parse(at: 0, columnIndex: 0)

// Parse cells with custom logic
let formattedName = try csv.parseCell(at: 0, column: "name") { value in
    return value.uppercased()
}

// Parse dates with custom formatter
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"
let date = try csv.parseCell(at: 0, column: "date") { value in
    guard let date = dateFormatter.date(from: value) else {
        throw CSVCellParsingError.invalidValue(value, targetType: "Date")
    }
    return date
}

// Parse cells asynchronously
let result = try await csv.parseCellAsync(at: 0, column: "data") { value in
    // Perform async work like API calls or complex processing
    return try await processValueAsynchronously(value)
}
```

## Customization

Configure the CSV parser to match your data format:

```swift
// Custom delimiter (semicolon)
let csv = try CSV(content: csvContent, delimiter: ";")

// Tab-delimited files
let tsvFile = try CSV(content: tsvContent, delimiter: "\t")

// Single quote for quoted fields
let csv = try CSV(content: csvContent, quoteCharacter: "'")

// CSV without headers
let csv = try CSV(content: csvContent, hasHeaders: false)
```

## License

CSV is available under the MIT license.
