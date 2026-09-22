import Foundation
import Testing

@testable import StarkSkyLight

@MainActor
struct SpaceClientTests {
  @Test func snapshot() throws {
    let backend = StubBackend()

    backend.displays = [
      display("A", ids: [1, 2], current: 2), display("Main", ids: [3], current: 3),
    ]
    backend.active = 3

    let snapshot = try SpaceClient(backend: backend).snapshot()

    #expect(snapshot.allSpaceIDs == [1, 2, 3].map { SpaceID(rawValue: $0) })
    #expect(snapshot.visibleSpaceIDs == [SpaceID(rawValue: 2), SpaceID(rawValue: 3)])
    #expect(snapshot.activeSpaceID == SpaceID(rawValue: 3))
    #expect(snapshot.displays[0].spaces[1].type == .fullscreen)
    #expect(snapshot.displayID(containing: SpaceID(rawValue: 2)) == DisplayID(rawValue: "A"))
    #expect(snapshot.isComplete)
  }

  @Test func missingSpaces() throws {
    let backend = StubBackend()
    let client = SpaceClient(backend: backend)

    #expect(try client.activeSpace() == nil)
    #expect(try client.currentSpace(for: DisplayID(rawValue: "missing")) == nil)
    #expect(try !client.snapshot().isComplete)

    backend.active = 1

    #expect(try !client.snapshot().isComplete)

    backend.displays = [display("Main", ids: [1], current: 2)]

    #expect(try !client.snapshot().isComplete)

    backend.displays = [display("Main", ids: [2], current: 2)]

    #expect(try !client.snapshot().isComplete)

    backend.displays = [["Display Identifier": "Main", "Spaces": [["id64": 1, "type": 0]]]]

    let snapshot = try client.snapshot()

    #expect(snapshot.displays[0].currentSpaceID == nil)
    #expect(!snapshot.isComplete)
  }

  @Test func windowSpaces() throws {
    let backend = StubBackend()

    backend.membership = [NSNumber(value: UInt64.max), 3, 3, 1]

    let client = SpaceClient(backend: backend)

    #expect(
      try client.spaceIDs(containing: 42) == [UInt64.max, 3, 1].map { SpaceID(rawValue: $0) }
    )
    #expect(backend.queriedWindow == 42)

    backend.membership = []

    #expect(try client.spaceIDs(containing: 42).isEmpty)
  }

  @Test func invalidNumbers() {
    let invalid: [Any] = [true, -1, 0, 1.5, "12", NSNull(), Double.infinity, Double.nan]

    for value in invalid {
      #expect(throws: SkyLightError.malformedResponse("spaces[0]")) {
        try SpaceParser.identifiers([value])
      }
    }
  }

  @Test func invalidDisplays() {
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

  @Test func idAliases() throws {
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

  @Test func spaceTypes() throws {
    let backend = StubBackend()

    backend.type = 19

    let client = SpaceClient(backend: backend)

    #expect(try client.spaceType(for: SpaceID(rawValue: 1)) == .unknown(19))

    backend.type = -1

    #expect(throws: SkyLightError.queryFailed("SLSSpaceGetType")) {
      try client.spaceType(for: SpaceID(rawValue: 1))
    }
  }

  @Test func invalidArguments() {
    let backend = StubBackend()

    backend.failure = .connectionUnavailable

    let client = SpaceClient(backend: backend)

    // Argument validation must run before the backend can throw its error.
    #expect(throws: SkyLightError.invalidArgument("windowID")) {
      try client.spaceIDs(containing: 0)
    }

    #expect(throws: SkyLightError.invalidArgument("spaceID")) {
      try client.spaceType(for: SpaceID(rawValue: 0))
    }

    #expect(throws: SkyLightError.invalidArgument("displayID")) {
      try client.currentSpace(for: DisplayID(rawValue: ""))
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

@MainActor
private final class StubBackend: SpaceBackend {
  var displays: [Any] = []
  var active: UInt64 = 0
  var type: Int32 = 0
  var membership: [Any] = []
  var queriedWindow: UInt32?
  var failure: SkyLightError?

  func displaySpaces() throws -> [Any] {
    if let failure { throw failure }

    return displays
  }

  func activeSpace() throws -> UInt64 {
    if let failure { throw failure }

    return active
  }

  func currentSpace(_ display: String) throws -> UInt64 {
    if let failure { throw failure }

    return active
  }

  func spaceType(_ space: UInt64) throws -> Int32 {
    if let failure { throw failure }

    return type
  }

  func spacesForWindow(_ window: UInt32) throws -> [Any] {
    if let failure { throw failure }

    queriedWindow = window

    return membership
  }
}
