# Query Spaces

[Documentation index](../index.md#api-reference)

`SpaceClient` reads Spaces from the logged-in WindowServer session. Create and use it on the main actor. All five query methods are synchronous and throw on failure.

## Create a client

```swift
import StarkSkyLight

@MainActor
func readSpaces() throws {
  let client = try SpaceClient()
  let snapshot = try client.snapshot()
  print(snapshot.activeSpaceID as Any)
}
```

`SpaceClient.init()` loads the required private SkyLight symbols and checks for a WindowServer connection. It can throw `frameworkUnavailable`, `symbolUnavailable`, or `connectionUnavailable`. See [errors](errors.md) for details.

The examples below use the same client from the main actor.

## Read display Spaces

```swift
let snapshot = try client.snapshot()
```

`snapshot()` returns a `SpaceSnapshot` with the managed display Space lists and the focused Space ID. Display and Space lists follow WindowServer order, including fullscreen Spaces. Invalid response entries throw `malformedResponse`.

The client copies the display lists, then queries the focused Space. These queries are not atomic. Check [`snapshot.isComplete`](types.md#spacesnapshot) before using current and focused IDs with the Space lists, and retry later if it is false. A complete snapshot can still become outdated after the query.

## Read focused and current Spaces

```swift
let activeSpace = try client.activeSpace()

for display in snapshot.displays {
  let currentSpace = try client.currentSpace(for: display.id)
  print(display.id.rawValue, currentSpace as Any)
}
```

`activeSpace()` returns the focused `SpaceID`. `currentSpace(for:)` returns the current `SpaceID` on one managed display. Both return `SpaceID?`, with `nil` when WindowServer reports zero.

Use a `DisplayID` from a snapshot. An unknown display or a Space transition can produce `nil`. An empty display identifier throws `SkyLightError.invalidArgument("displayID")`.

## Read a Space type

```swift
if let spaceID = try client.activeSpace() {
  let type = try client.spaceType(for: spaceID)
  print(type)
}
```

`spaceType(for:)` returns `.desktop` for raw type `0`, `.fullscreen` for `4`, and `.unknown(value)` for other nonnegative values.

A zero Space identifier throws `SkyLightError.invalidArgument("spaceID")`. A negative type from WindowServer throws `SkyLightError.queryFailed("SLSSpaceGetType")`.

## Find a window's Spaces

```swift
let spaceIDs = try client.spaceIDs(containing: windowID)
```

Pass a `CGWindowID` obtained by your application. `spaceIDs(containing:)` returns `[SpaceID]` across all Space kinds. It removes duplicate IDs, keeping their first occurrence in the response.

An empty array means WindowServer reported no membership, including when the window has disappeared. Membership does not determine window visibility or eligibility.

A zero window identifier throws `SkyLightError.invalidArgument("windowID")`. Invalid identifiers in the response throw `malformedResponse`.

## Test query consumers

Accept `any SpaceQuerying` in application code to supply a test implementation without a desktop connection:

```swift
import StarkSkyLight

@MainActor
func focusedSpace(using queries: any SpaceQuerying) throws -> SpaceID? {
  try queries.activeSpace()
}
```

`SpaceQuerying` is isolated to `@MainActor` and requires these methods:

```swift
func snapshot() throws -> SpaceSnapshot
func activeSpace() throws -> SpaceID?
func currentSpace(for displayID: DisplayID) throws -> SpaceID?
func spaceType(for spaceID: SpaceID) throws -> SpaceType
func spaceIDs(containing windowID: CGWindowID) throws -> [SpaceID]
```

Use the public [data type initializers](types.md) to construct snapshots and Space lists in tests. Your application controls refresh timing, retries, and error handling.
