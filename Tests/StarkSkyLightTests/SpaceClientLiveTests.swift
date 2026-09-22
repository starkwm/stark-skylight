import CoreGraphics
import Foundation
import StarkSkyLight
import Testing

@Suite("SpaceClient")
@MainActor
struct SpaceClientLiveTests {
  @Test(
    "snapshot: reads the current desktop",
    .enabled(if: ProcessInfo.processInfo.environment["STARK_SKYLIGHT_LIVE"] == "1")
  )
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

    // System overlays can be onscreen without belonging to a Space.
    let info = windows.first { $0[kCGWindowLayer as String] as? Int == 0 }
    let window = try #require(info?[kCGWindowNumber as String] as? UInt32)
    let membership = try client.spaceIDs(containing: window)

    #expect(!membership.isEmpty)
    #expect(membership.allSatisfy { snapshot.allSpaceIDs.contains($0) })

    print(
      "Live: \(snapshot.displays.count) displays, \(snapshot.allSpaceIDs.count) Spaces, window \(window) in \(membership.count) Spaces"
    )
  }
}
