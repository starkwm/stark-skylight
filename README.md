# StarkSkyLight

Typed, read-only WindowServer Space queries for macOS. Requires Swift 6.2 or later and macOS 26 or later. The library product and module are both `StarkSkyLight`. There are no package dependencies or private framework linker flags.

```swift
import StarkSkyLight

@MainActor
func readSpaces() throws {
  let client = try SpaceClient()
  let snapshot = try client.snapshot()
  guard snapshot.isComplete else { return } // Retry later if a transition is in progress.

  for display in snapshot.displays {
    print(display.id.rawValue, display.currentSpaceID?.rawValue as Any)
    for space in display.spaces {
      print(space.id.rawValue, space.type)
    }
  }
}
```

`SpaceClient` conforms to the public `SpaceQuerying` protocol. Consumers can inject their own implementation for tests. All queries run on the main actor; returned models are immutable and `Sendable`. An internal raw backend lets package tests exercise parsing and failures without a desktop connection.

| Query | Result |
| --- | --- |
| `snapshot()` | Displays, ordered Spaces and their types, current Space per display, focused Space |
| `activeSpace()` | Focused Space ID, or `nil` when unavailable |
| `currentSpace(for:)` | Current Space ID for a managed display, or `nil` when unavailable |
| `spaceType(for:)` | `.desktop`, `.fullscreen`, or `.unknown(Int32)` |
| `spaceIDs(containing:)` | Distinct Space IDs for a `CGWindowID`, preserving WindowServer order |

A snapshot also provides `allSpaceIDs`, `visibleSpaceIDs`, `displayID(containing:)` and `isComplete`. “Visible” means reported as current on a display. It does not describe window visibility or animation progress. Space IDs are 64-bit identifiers, not Mission Control indices. Display IDs preserve WindowServer spelling and can be `Main` when displays share Spaces; do not assume they are UUIDs. Pass an ID obtained from a snapshot to `currentSpace(for:)`.

Queries are not atomic. `snapshot()` copies the display dictionaries, then queries the focused Space. `isComplete` checks that all reported current and focused IDs occur in the copied lists. A complete result can still become stale immediately. Consumers own notifications, refresh timing and retry policy. The snapshot's current IDs come from the copied dictionaries; `currentSpace(for:)` makes a fresh query.

The client throws `SkyLightError` for loader, missing-symbol, connection, query and malformed-response failures. It rejects zero Space/window IDs and empty display IDs supplied to queries. Zero active/current results become `nil`; a missing current dictionary also becomes `nil`. Empty display results produce an incomplete snapshot. An empty membership result means WindowServer reported no membership, which can happen after a window disappears. A null CF result throws rather than becoming an empty list.

The parser accepts `ManagedSpaceID` and `id64`, requires agreement when both occur, and rejects booleans, negative or fractional IDs, duplicate display/Space entries, and malformed types. Membership duplicates are removed. Unknown non-negative Space types retain their numeric value. Membership alone does not determine whether a window is sticky, visible or eligible for management.

## Private API boundary

Only these symbols are resolved:

| Symbol | C-compatible declaration |
| --- | --- |
| `SLSMainConnectionID` | `int32_t (void)` |
| `SLSCopyManagedDisplaySpaces` | `CFArrayRef (int32_t)` |
| `SLSGetActiveSpace` | `uint64_t (int32_t)` |
| `SLSManagedDisplayGetCurrentSpace` | `uint64_t (int32_t, CFStringRef)` |
| `SLSSpaceGetType` | `int32_t (int32_t, uint64_t)` |
| `SLSCopySpacesForWindows` | `CFArrayRef (int32_t, int32_t, CFArrayRef)` |

Declarations were checked against [yabai's declarations](https://github.com/asmvik/yabai/blob/master/src/misc/extern.h) and [Hammerspoon's declarations](https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/spaces/private.h). Copy-result ownership was checked against [Hammerspoon's implementation](https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/spaces/libspaces.m) and [yabai's membership queries](https://github.com/asmvik/yabai/blob/master/src/window.c). Swift uses `@convention(c)` and nullable `Unmanaged<CFArray>` results, consumed with `takeRetainedValue()`. Membership uses selector `0x7`.

The backend owns its `dlopen` reference for the lifetime of its function pointers. The reference is closed when the backend is released, including failed initialisation. No callbacks or function pointers escape. These private APIs have no Apple compatibility guarantee. Declaration comparison and live read checks are evidence for the tested host, not proof of an ABI contract across macOS releases.

## Development

```sh
make build
make format
make lint
make test
make live
```

Normal tests use an injected backend. `make live` explicitly enables a read-only desktop integration test. It compares dictionary and direct Space types/current IDs and queries membership for an existing on-screen window. It does not create windows, change focus, switch Spaces or alter the desktop. Run it on a settled desktop because transitions can invalidate cross-query comparisons.

Initial validation passed seven automated tests, strict formatting lint, a debug build and the opt-in live test on one display with five Spaces. It used Swift 6.4 on an arm64 macOS 27 host with a macOS 26 deployment target. Runtime validation on macOS 26, Space transitions, fullscreen transitions and multiple physical displays remains separate work.

## Scope and consumer integration

The package contains no presentation, tiling, window eligibility, focus actions, border management or Space mutation. Consumers remain unchanged. Future integration can replace the Space-query portions of swm, sbar and sborders with `SpaceQuerying`, map their IDs to `SpaceID` and `DisplayID`, and handle unavailable/incomplete results explicitly. Their existing observation, rendering and window-management policies stay in the consumers.
