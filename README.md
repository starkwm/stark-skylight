# StarkSkyLight

Swift utilities for read-only WindowServer Space queries, including display Spaces, the focused Space and window membership.

Requires Swift 6.2 and macOS 26. Uses private macOS APIs that may change between releases.

See the [documentation](docs/index.md) for an overview and the [API reference](docs/index.md#api-reference) for query methods, data types and errors.

## Usage

Add `https://github.com/starkwm/stark-skylight.git` as a Swift package dependency and link the `StarkSkyLight` product to your target.

### Read display Spaces

Create and use the client on the main actor:

```swift
import StarkSkyLight

@MainActor
func readSpaces() throws {
  let client = try SpaceClient()
  let snapshot = try client.snapshot()
  guard snapshot.isComplete else { return }

  for display in snapshot.displays {
    print(display.id.rawValue, display.currentSpaceID?.rawValue as Any)
    for space in display.spaces {
      print(space.id.rawValue, space.type)
    }
  }
}
```

Each display has an ordered list of Spaces and its current Space ID. `snapshot.activeSpaceID` identifies the focused Space. Space types are `.desktop`, `.fullscreen` or `.unknown(Int32)`.

Queries are not atomic. A snapshot can be incomplete during a Space transition; retry later when `isComplete` is false. Space IDs are WindowServer identifiers, not Mission Control indices. Display IDs can be `Main` rather than a UUID.

### Query individual Spaces and windows

Use the same client to read the focused Space or find the Spaces containing a window:

```swift
let activeSpace = try client.activeSpace()
let spaces = try client.spaceIDs(containing: windowID)
```

`windowID` is a `CGWindowID` obtained by your application. Use `currentSpace(for:)` with a display ID from a snapshot, or `spaceType(for:)` with a Space ID. Window membership alone does not determine whether a window is visible.

Queries throw `SkyLightError` on failure. Active and current Space queries return `nil` when unavailable; window membership can be empty. Consumers own refresh timing and retry handling. Inject a `SpaceQuerying` implementation to test consumers without a desktop connection.
