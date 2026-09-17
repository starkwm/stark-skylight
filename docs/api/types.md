# Data types

[Documentation index](../index.md#api-reference)

Snapshots, displays, Spaces, and identifiers are immutable values. All types on this page conform to `Sendable`. Their public initializers let you construct values for tests without a WindowServer connection.

Initializers do not validate identifiers or snapshot consistency. `SpaceType.init(rawValue:)` maps a raw type to an enum case.

## SpaceSnapshot

`public struct SpaceSnapshot: Equatable, Sendable`

```swift
public init(displays: [DisplaySpaces], activeSpaceID: SpaceID?)
```

| Property | Type | Meaning |
| --- | --- | --- |
| `displays` | `[DisplaySpaces]` | Managed displays in WindowServer order. |
| `activeSpaceID` | `SpaceID?` | Focused Space, or `nil` when unavailable. |
| `allSpaceIDs` | `[SpaceID]` | Listed Space IDs across displays, removing duplicates in first-occurrence order. |
| `visibleSpaceIDs` | `Set<SpaceID>` | Current Space IDs reported by the displays, omitting `nil`. |
| `isComplete` | `Bool` | Whether current and focused IDs are present and belong to the copied Space lists. |

`isComplete` is true only when there is at least one display, the active Space appears in `allSpaceIDs`, and every display has a current Space in its own `spaces` list. This checks consistency within the snapshot; WindowServer queries are not atomic.

`visibleSpaceIDs` derives only from current display Spaces. It does not query window visibility.

```swift
public func displayID(containing spaceID: SpaceID) -> DisplayID?
```

Returns the first display whose Space list contains the identifier, or `nil` if no display matches. When multiple displays contain the same Space, WindowServer display order determines the result.

## DisplaySpaces

`public struct DisplaySpaces: Equatable, Sendable, Identifiable`

```swift
public init(id: DisplayID, spaces: [Space], currentSpaceID: SpaceID?)
```

| Property | Type | Meaning |
| --- | --- | --- |
| `id` | `DisplayID` | Managed display identifier. |
| `spaces` | `[Space]` | Spaces in WindowServer order, including fullscreen Spaces. |
| `currentSpaceID` | `SpaceID?` | Display's current Space, or `nil` when not reported. |

## Space

`public struct Space: Equatable, Sendable, Identifiable`

```swift
public init(id: SpaceID, type: SpaceType)
```

`id` is the Space identifier. `type` describes whether it is a desktop, fullscreen, or unknown Space.

## SpaceID

`public struct SpaceID: RawRepresentable, Hashable, Sendable`

```swift
public init(rawValue: UInt64)
```

`rawValue` is a `UInt64` WindowServer identifier. Mission Control indexes are separate from these IDs. The initializer accepts zero, but client queries that take a Space ID reject it.

## DisplayID

`public struct DisplayID: RawRepresentable, Hashable, Sendable`

```swift
public init(rawValue: String)
```

`rawValue` is an opaque `String`. Use the value returned in a snapshot, which may be `Main` rather than a UUID. The initializer accepts an empty string, but `currentSpace(for:)` rejects it.

## SpaceType

`public enum SpaceType: Equatable, Sendable`

| Case | Raw value accepted by `init(rawValue:)` |
| --- | --- |
| `.desktop` | `0` |
| `.fullscreen` | `4` |
| `.unknown(Int32)` | Any other value, preserved as the associated value. |

```swift
public init(rawValue: Int32)
```

Handle `.unknown` when switching over Space types so your application can represent values introduced by newer WindowServer versions. `SpaceType` does not conform to `RawRepresentable` or expose a `rawValue` property.
