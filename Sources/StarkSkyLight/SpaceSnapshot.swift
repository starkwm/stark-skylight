/// A point-in-time observation. WindowServer queries are not atomic.
public struct SpaceSnapshot: Equatable, Sendable {
  public let displays: [DisplaySpaces]
  /// The focused Space, distinct from the current Space on each display.
  public let activeSpaceID: SpaceID?

  public var allSpaceIDs: [SpaceID] {
    var seen = Set<SpaceID>()

    return displays.flatMap(\.spaces).map(\.id).filter { seen.insert($0).inserted }
  }

  public var visibleSpaceIDs: Set<SpaceID> { Set(displays.compactMap(\.currentSpaceID)) }

  /// False when current/focused IDs are missing or absent from the copied Space lists.
  public var isComplete: Bool {
    guard let activeSpaceID, allSpaceIDs.contains(activeSpaceID), !displays.isEmpty else {
      return false
    }

    return displays.allSatisfy { display in
      guard let current = display.currentSpaceID else { return false }

      return display.spaces.contains { $0.id == current }
    }
  }

  public init(displays: [DisplaySpaces], activeSpaceID: SpaceID?) {
    self.displays = displays
    self.activeSpaceID = activeSpaceID
  }

  /// Returns the first matching managed display in WindowServer order.
  public func displayID(containing spaceID: SpaceID) -> DisplayID? {
    displays.first { $0.spaces.contains { $0.id == spaceID } }?.id
  }
}

/// A WindowServer Space identifier, not a Mission Control index.
public struct SpaceID: RawRepresentable, Hashable, Sendable {
  public let rawValue: UInt64

  public init(rawValue: UInt64) { self.rawValue = rawValue }
}

/// An opaque managed display identifier. It may be "Main" rather than a UUID.
public struct DisplayID: RawRepresentable, Hashable, Sendable {
  public let rawValue: String

  public init(rawValue: String) { self.rawValue = rawValue }
}

/// Known Space types and any values introduced by a newer WindowServer.
public enum SpaceType: Equatable, Sendable {
  case desktop
  case fullscreen
  case unknown(Int32)

  public init(rawValue: Int32) {
    switch rawValue {
    case 0: self = .desktop
    case 4: self = .fullscreen
    default: self = .unknown(rawValue)
    }
  }
}

public struct Space: Equatable, Sendable, Identifiable {
  public let id: SpaceID
  public let type: SpaceType

  public init(id: SpaceID, type: SpaceType) {
    self.id = id
    self.type = type
  }
}

public struct DisplaySpaces: Equatable, Sendable, Identifiable {
  public let id: DisplayID
  /// WindowServer order, including fullscreen Spaces.
  public let spaces: [Space]
  /// Nil when WindowServer does not report a current Space.
  public let currentSpaceID: SpaceID?

  public init(id: DisplayID, spaces: [Space], currentSpaceID: SpaceID?) {
    self.id = id
    self.spaces = spaces
    self.currentSpaceID = currentSpaceID
  }
}
