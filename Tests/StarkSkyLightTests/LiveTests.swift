import CoreGraphics
import Foundation
import StarkSkyLight
import Testing

@MainActor
struct LiveTests {
  @Test(.enabled(if: ProcessInfo.processInfo.environment["STARK_SKYLIGHT_LIVE"] == "1"))
  func readDesktop() throws {
    let client = try SpaceClient()
    let snapshot = try client.snapshot()
    #expect(!snapshot.displays.isEmpty)
    #expect(snapshot.isComplete)
    for display in snapshot.displays {
      #expect(try client.currentSpace(for: display.id) == display.currentSpaceID)
      for space in display.spaces {
        #expect(try client.spaceType(for: space.id) == space.type)
      }
    }
    let windows =
      CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], 0)
      as? [[String: Any]] ?? []
    let window = try #require(windows.first?[kCGWindowNumber as String] as? UInt32)
    let membership = try client.spaceIDs(containing: window)
    #expect(!membership.isEmpty)
    #expect(membership.allSatisfy { snapshot.allSpaceIDs.contains($0) })
    print(
      "Live: \(snapshot.displays.count) displays, \(snapshot.allSpaceIDs.count) Spaces, window \(window) in \(membership.count) Spaces"
    )
  }
}
