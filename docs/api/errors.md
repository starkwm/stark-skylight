# Errors

[Documentation index](../index.md#api-reference)

Client initialization and queries throw `SkyLightError` on failure. It conforms to `Error`, `Equatable`, `Sendable`, and `LocalizedError`. Use `errorDescription` for a readable description.

## Error cases

| Case | Meaning |
| --- | --- |
| `.frameworkUnavailable(String)` | SkyLight could not be loaded. The associated value contains loader details. |
| `.symbolUnavailable(String)` | A required private symbol is missing. The associated value names the symbol. |
| `.connectionUnavailable` | No WindowServer connection is available. |
| `.queryFailed(String)` | A WindowServer query failed. The associated value names the query. |
| `.malformedResponse(String)` | A response has an invalid structure or value. The associated value identifies the response path. |
| `.invalidArgument(String)` | A query received an invalid argument. The associated value names the argument. |

Client methods reject empty display IDs, zero Space IDs, and zero window IDs where those arguments apply. Invalid response entries throw `malformedResponse`.

## Missing state and retries

Missing state does not always throw. `activeSpace()` and `currentSpace(for:)` can return `nil`, and `spaceIDs(containing:)` can return an empty array. A successfully returned snapshot can have `isComplete == false`.

Your application controls retries for incomplete snapshots and failed queries. Loading and symbol failures may require compatibility changes rather than a retry.
