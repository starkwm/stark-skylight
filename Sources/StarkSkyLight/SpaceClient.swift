import CoreGraphics
import Foundation

/// Injectable read-only queries for consumers. Calls are confined to the main actor.
@MainActor
public protocol SpaceQuerying {
  func snapshot() throws -> SpaceSnapshot
  func activeSpace() throws -> SpaceID?
  func currentSpace(for displayID: DisplayID) throws -> SpaceID?
  func spaceType(for spaceID: SpaceID) throws -> SpaceType
  func spaceIDs(containing windowID: CGWindowID) throws -> [SpaceID]
}

@MainActor
public final class SpaceClient: SpaceQuerying {
  private let backend: any SpaceBackend

  /// Loads the required private symbols. Requires a logged-in macOS desktop.
  public convenience init() throws {
    self.init(backend: try SkyLightBackend())
  }

  init(backend: any SpaceBackend) { self.backend = backend }

  public func snapshot() throws -> SpaceSnapshot {
    let displays = try SpaceParser.displays(backend.displaySpaces())
    return SpaceSnapshot(displays: displays, activeSpaceID: try activeSpace())
  }

  /// Zero from WindowServer means unavailable and is returned as nil.
  public func activeSpace() throws -> SpaceID? {
    let raw = try backend.activeSpace()
    return raw == 0 ? nil : SpaceID(rawValue: raw)
  }

  /// Nil can mean an unknown display or a Space transition.
  public func currentSpace(for displayID: DisplayID) throws -> SpaceID? {
    guard !displayID.rawValue.isEmpty else { throw SkyLightError.invalidArgument("displayID") }
    let raw = try backend.currentSpace(displayID.rawValue)
    return raw == 0 ? nil : SpaceID(rawValue: raw)
  }

  public func spaceType(for spaceID: SpaceID) throws -> SpaceType {
    guard spaceID.rawValue != 0 else { throw SkyLightError.invalidArgument("spaceID") }
    let raw = try backend.spaceType(spaceID.rawValue)
    guard raw >= 0 else { throw SkyLightError.queryFailed("SLSSpaceGetType") }
    return SpaceType(rawValue: raw)
  }

  /// Empty means no reported membership, including a window that has disappeared.
  /// This is not a test of window visibility or eligibility.
  public func spaceIDs(containing windowID: CGWindowID) throws -> [SpaceID] {
    guard windowID != 0 else { throw SkyLightError.invalidArgument("windowID") }
    return try SpaceParser.identifiers(backend.spacesForWindow(windowID))
  }
}

@MainActor
protocol SpaceBackend {
  func displaySpaces() throws -> [Any]
  func activeSpace() throws -> UInt64
  func currentSpace(_ display: String) throws -> UInt64
  func spaceType(_ space: UInt64) throws -> Int32
  func spacesForWindow(_ window: UInt32) throws -> [Any]
}
