import Foundation
import Testing

@testable import StarkSkyLight

@Suite("SpaceClient")
@MainActor
struct SpaceClientTests {
  @Test("snapshot: collects display and active Space data")
  func snapshot() throws {
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

  @Test("snapshot: reports incomplete Space data")
  func snapshotWithMissingSpaces() throws {
    let backend = StubBackend()
    let client = SpaceClient(backend: backend)

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

  @Test("activeSpace: returns nil when WindowServer reports zero")
  func activeSpaceWithZero() throws {
    let client = SpaceClient(backend: StubBackend())

    #expect(try client.activeSpace() == nil)
  }

  @Test("currentSpace(for:): returns nil when WindowServer reports zero")
  func currentSpaceWithZero() throws {
    let client = SpaceClient(backend: StubBackend())

    #expect(try client.currentSpace(for: DisplayID(rawValue: "missing")) == nil)
  }

  @Test("currentSpace(for:): rejects an empty display ID")
  func currentSpaceWithEmptyDisplayID() {
    let backend = StubBackend()
    backend.failure = .connectionUnavailable

    let client = SpaceClient(backend: backend)

    #expect(throws: SkyLightError.invalidArgument("displayID")) {
      try client.currentSpace(for: DisplayID(rawValue: ""))
    }
  }

  @Test("spaceType(for:): preserves unknown types and rejects query failures")
  func spaceType() throws {
    let backend = StubBackend()

    backend.type = 19

    let client = SpaceClient(backend: backend)

    #expect(try client.spaceType(for: SpaceID(rawValue: 1)) == .unknown(19))

    backend.type = -1

    #expect(throws: SkyLightError.queryFailed("SLSSpaceGetType")) {
      try client.spaceType(for: SpaceID(rawValue: 1))
    }
  }

  @Test("spaceType(for:): rejects a zero Space ID")
  func spaceTypeWithZeroID() {
    let backend = StubBackend()
    backend.failure = .connectionUnavailable

    let client = SpaceClient(backend: backend)

    #expect(throws: SkyLightError.invalidArgument("spaceID")) {
      try client.spaceType(for: SpaceID(rawValue: 0))
    }
  }

  @Test("spaceIDs(containing:): deduplicates memberships and handles empty results")
  func spaceIDs() throws {
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

  @Test("spaceIDs(containing:): rejects a zero window ID")
  func spaceIDsWithZeroWindowID() {
    let backend = StubBackend()
    backend.failure = .connectionUnavailable

    let client = SpaceClient(backend: backend)

    // Argument validation must run before the backend can throw its error.
    #expect(throws: SkyLightError.invalidArgument("windowID")) {
      try client.spaceIDs(containing: 0)
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
