import Foundation

public enum SkyLightError: Error, Equatable, Sendable {
  case frameworkUnavailable(String)
  case symbolUnavailable(String)
  case connectionUnavailable
  case queryFailed(String)
  case malformedResponse(String)
  case invalidArgument(String)
}

extension SkyLightError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .frameworkUnavailable(let detail): "Cannot load SkyLight: \(detail)"
    case .symbolUnavailable(let name): "SkyLight symbol unavailable: \(name)"
    case .connectionUnavailable: "No WindowServer connection is available."
    case .queryFailed(let name): "WindowServer query failed: \(name)"
    case .malformedResponse(let path): "Malformed WindowServer response at \(path)."
    case .invalidArgument(let name): "Invalid WindowServer query argument: \(name)"
    }
  }
}
