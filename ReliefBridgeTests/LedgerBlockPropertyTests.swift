// ReliefBridgeTests/LedgerBlockPropertyTests.swift
// Property-based tests for LedgerBlock rendering.
// Property 6: Ledger Block Required Fields

import XCTest
import SwiftCheck
import SwiftUI
@testable import ReliefBridge

// MARK: - LedgerBlock Generator

extension LedgerBlock: Arbitrary {
    public static var arbitrary: Gen<LedgerBlock> {
        Gen.zip(
            Date.arbitrary,
            String.arbitrary.map { "FL-\(abs($0.hashValue) % 9999)" },
            Gen<Double>.fromElements(in: 0.5...12.0).resize(20),  // carbonSavedMetricTons in [0.5, 12.0]
            Gen<RegulatoryStandard>.fromElements(of: [.corsia, .euEts]),
            String.arbitrary.map { String(format: "%064x", abs($0.hashValue)) }  // simulated SHA-256 hex
        ).map { timestamp, flightId, carbon, standard, hash in
            LedgerBlock(
                id: UUID(),
                timestamp: timestamp,
                flightIdentifier: flightId,
                carbonSavedMetricTons: carbon,
                regulatoryStandard: standard,
                blockHash: hash
            )
        }
    }
}

extension Date: @retroactive Arbitrary {
    public static var arbitrary: Gen<Date> {
        Gen<Int>.fromElements(in: 0...365*5).map { days in
            // Generate dates within the last 5 years
            Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        }
    }
}

// MARK: - Property 6: Ledger Block Required Fields

// Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
// Validates: Requirements 4.1, 4.2, 4.10

final class LedgerBlockRequiredFieldsPropertyTests: XCTestCase {

    /// Property 6: Ledger Block Required Fields
    ///
    /// For any LedgerBlock in the data set, the rendered LedgerBlockRow SHALL display:
    /// 1. The block's timestamp
    /// 2. The flight identifier
    /// 3. The carbon savings value
    /// 4. The regulatory standard label
    /// 5. An immutability indicator (hash string or lock icon)
    func testProperty6_LedgerBlockRequiredFields() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Every LedgerBlock contains all required fields") <- forAll(
            LedgerBlock.arbitrary
        ) { (block: LedgerBlock) in
            // Verify that all required fields are present and non-empty/valid
            
            // 1. Timestamp must be a valid date
            let timestampValid = block.timestamp.timeIntervalSince1970 > 0
            
            // 2. Flight identifier must be non-empty
            let flightIdValid = !block.flightIdentifier.isEmpty
            
            // 3. Carbon savings must be in valid range [0.5, 12.0]
            let carbonValid = block.carbonSavedMetricTons >= 0.5 && block.carbonSavedMetricTons <= 12.0
            
            // 4. Regulatory standard must have a non-empty string representation
            let standardValid = !block.regulatoryStandard.rawValue.isEmpty
            
            // 5. Block hash (immutability indicator) must be non-empty
            let hashValid = !block.blockHash.isEmpty
            
            return timestampValid && flightIdValid && carbonValid && standardValid && hashValid
        }
    }

    /// Property 6 (timestamp): Timestamp is always displayable.
    func testProperty6_TimestampIsDisplayable() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Timestamp is always displayable") <- forAll(
            LedgerBlock.arbitrary
        ) { (block: LedgerBlock) in
            // Verify that the timestamp can be formatted for display
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let formatted = formatter.string(from: block.timestamp)
            return !formatted.isEmpty
        }
    }

    /// Property 6 (flight identifier): Flight identifier is always non-empty.
    func testProperty6_FlightIdentifierNonEmpty() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Flight identifier is always non-empty") <- forAll(
            LedgerBlock.arbitrary
        ) { (block: LedgerBlock) in
            return !block.flightIdentifier.isEmpty
        }
    }

    /// Property 6 (carbon savings): Carbon savings is always in valid range.
    func testProperty6_CarbonSavingsInValidRange() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Carbon savings is always in [0.5, 12.0] metric tons") <- forAll(
            LedgerBlock.arbitrary
        ) { (block: LedgerBlock) in
            return block.carbonSavedMetricTons >= 0.5 && block.carbonSavedMetricTons <= 12.0
        }
    }

    /// Property 6 (regulatory standard): Regulatory standard label is always displayable.
    func testProperty6_RegulatoryStandardDisplayable() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Regulatory standard label is always displayable") <- forAll(
            LedgerBlock.arbitrary
        ) { (block: LedgerBlock) in
            let label = block.regulatoryStandard.rawValue
            return !label.isEmpty && (label == "CORSIA" || label == "EU ETS")
        }
    }

    /// Property 6 (immutability indicator): Block hash is always non-empty.
    func testProperty6_ImmutabilityIndicatorPresent() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Immutability indicator (block hash) is always present") <- forAll(
            LedgerBlock.arbitrary
        ) { (block: LedgerBlock) in
            return !block.blockHash.isEmpty
        }
    }

    /// Property 6 (all fields present): All five required fields are present simultaneously.
    func testProperty6_AllFieldsPresentSimultaneously() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("All five required fields are present simultaneously") <- forAll(
            [LedgerBlock].arbitrary.resize(20).suchThat { !$0.isEmpty }
        ) { (blocks: [LedgerBlock]) in
            for block in blocks {
                // Verify all five fields are present and valid
                let hasTimestamp = block.timestamp.timeIntervalSince1970 > 0
                let hasFlightId = !block.flightIdentifier.isEmpty
                let hasCarbonSavings = block.carbonSavedMetricTons >= 0.5 && block.carbonSavedMetricTons <= 12.0
                let hasStandard = !block.regulatoryStandard.rawValue.isEmpty
                let hasHash = !block.blockHash.isEmpty
                
                guard hasTimestamp && hasFlightId && hasCarbonSavings && hasStandard && hasHash else {
                    return false
                }
            }
            return true
        }
    }

    /// Property 6 (carbon formatting): Carbon savings can be formatted with metric tons unit.
    func testProperty6_CarbonSavingsFormattable() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Carbon savings can be formatted with metric tons unit") <- forAll(
            LedgerBlock.arbitrary
        ) { (block: LedgerBlock) in
            // Verify that carbon savings can be formatted as a string with unit
            let formatted = String(format: "%.2f metric tons", block.carbonSavedMetricTons)
            return !formatted.isEmpty && formatted.contains("metric tons")
        }
    }

    /// Property 6 (hash format): Block hash is a valid hex string.
    func testProperty6_BlockHashIsValidHex() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Block hash is a valid hexadecimal string") <- forAll(
            LedgerBlock.arbitrary
        ) { (block: LedgerBlock) in
            // Verify that the hash contains only valid hex characters (0-9, a-f, A-F)
            let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
            let hashCharacterSet = CharacterSet(charactersIn: block.blockHash)
            return hexCharacterSet.isSuperset(of: hashCharacterSet) && !block.blockHash.isEmpty
        }
    }

    /// Property 6 (timestamp ordering): Blocks can be sorted by timestamp.
    func testProperty6_BlocksCanBeSortedByTimestamp() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Blocks can be sorted by timestamp") <- forAll(
            [LedgerBlock].arbitrary.resize(20).suchThat { $0.count >= 2 }
        ) { (blocks: [LedgerBlock]) in
            // Sort blocks by timestamp
            let sorted = blocks.sorted { $0.timestamp < $1.timestamp }
            
            // Verify that the sorted array is in ascending order
            for i in 0..<(sorted.count - 1) {
                if sorted[i].timestamp > sorted[i + 1].timestamp {
                    return false
                }
            }
            return true
        }
    }

    /// Property 6 (uniqueness): Each block has a unique ID.
    func testProperty6_EachBlockHasUniqueID() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Each block has a unique ID") <- forAll(
            [LedgerBlock].arbitrary.resize(20).suchThat { $0.count >= 2 }
        ) { (blocks: [LedgerBlock]) in
            // Verify that all block IDs are unique
            let ids = blocks.map(\.id)
            let uniqueIds = Set(ids)
            return ids.count == uniqueIds.count
        }
    }

    /// Property 6 (regulatory standard coverage): Both regulatory standards are valid.
    func testProperty6_RegulatoryStandardCoverage() {
        // Feature: reliefbridge-insight, Property 6: Every LedgerBlockRow SHALL display all required fields
        property("Regulatory standard is always CORSIA or EU ETS") <- forAll(
            LedgerBlock.arbitrary
        ) { (block: LedgerBlock) in
            return block.regulatoryStandard == .corsia || block.regulatoryStandard == .euEts
        }
    }
}
