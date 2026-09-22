import Foundation
import Testing

@testable import StarkSkyLight

@Suite("SpaceParser")
struct SpaceParserTests {
  @Test("displays: rejects malformed and duplicate entries")
  func displaysWithInvalidEntries() {
    let bad: [[Any]] = [
      ["wrong"],
      [["Spaces": []]],
      [["Display Identifier": "", "Spaces": []]],
      [["Display Identifier": "Main", "Spaces": ["wrong"]]],
      [["Display Identifier": "Main", "Spaces": [["type": 0]]]],
      [["Display Identifier": "Main", "Spaces": [["ManagedSpaceID": 1]]]],
      [["Display Identifier": "Main", "Spaces": [["ManagedSpaceID": true, "type": 0]]]],
      [["Display Identifier": "Main", "Spaces": [["id64": 1, "type": true]]]],
      [["Display Identifier": "Main", "Spaces": [["id64": 1, "type": -1]]]],
      [["Display Identifier": "Main", "Spaces": [], "Current Space": NSNull()]],
      [display("Main", ids: [1, 1], current: 1)],
      [display("Main", ids: [1], current: 1), display("Main", ids: [2], current: 2)],
      [["Display Identifier": "Main", "Spaces": [["id64": 1, "ManagedSpaceID": 2, "type": 0]]]],
    ]

    for value in bad {
      #expect(throws: SkyLightError.self) { try SpaceParser.displays(value) }
    }
  }

  @Test("displays: accepts matching ID aliases and unknown Space types")
  func displaysWithIDAliases() throws {
    let values: [Any] = [
      [
        "Display Identifier": "Main",
        "Spaces": [["id64": NSNumber(value: UInt64.max), "type": 19]],
        "Current Space": [
          "id64": NSNumber(value: UInt64.max), "ManagedSpaceID": NSNumber(value: UInt64.max),
        ],
      ]
    ]

    let parsed = try SpaceParser.displays(values)

    #expect(parsed[0].spaces[0].id.rawValue == UInt64.max)
    #expect(parsed[0].spaces[0].type == .unknown(19))
    #expect(parsed[0].currentSpaceID?.rawValue == UInt64.max)
  }

  @Test("identifiers: rejects invalid numbers")
  func identifiersWithInvalidNumbers() {
    let invalid: [Any] = [true, -1, 0, 1.5, "12", NSNull(), Double.infinity, Double.nan]

    for value in invalid {
      #expect(throws: SkyLightError.malformedResponse("spaces[0]")) {
        try SpaceParser.identifiers([value])
      }
    }
  }

  private func display(_ name: String, ids: [UInt64], current: UInt64) -> [String: Any] {
    [
      "Display Identifier": name,
      "Spaces": ids.map { ["ManagedSpaceID": $0, "type": $0 == 2 ? 4 : 0] },
      "Current Space": ["ManagedSpaceID": current],
    ]
  }
}
