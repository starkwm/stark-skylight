# Getting started

[Documentation index](index.md)

## Requirements

- macOS 26 or later
- Swift 6.2 or later
- A logged-in macOS desktop when using `SpaceClient`

StarkSkyLight uses private SkyLight APIs. A macOS update may change behavior that it relies on.

## Installation

Add `https://github.com/starkwm/stark-skylight.git` as a Swift package dependency and link the `StarkSkyLight` product to your target.

## Read Spaces

Create and use the client on the main actor:

```swift
import StarkSkyLight

@MainActor
func readSpaces() throws {
  let client = try SpaceClient()
  let snapshot = try client.snapshot()
  guard snapshot.isComplete else { return }

  for display in snapshot.displays {
    for space in display.spaces {
      print(display.id.rawValue, space.id.rawValue, space.type)
    }
  }
}
```

Each display has an ordered list of Spaces and its own current Space. `snapshot.activeSpaceID` identifies the focused Space across displays.

WindowServer queries are not atomic. If a snapshot is incomplete during a Space transition, retry later. Your application controls refresh timing and retries.

See [query Spaces](api/queries.md) for individual queries and window membership, [data types](api/types.md) for snapshot properties, and [errors](api/errors.md) for failure handling.
