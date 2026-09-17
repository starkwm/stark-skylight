import Foundation

/// Reject corrupt entries rather than silently returning an apparently complete subset.
enum SpaceParser {
  static func displays(_ values: [Any]) throws -> [DisplaySpaces] {
    var seen = Set<DisplayID>()

    return try values.enumerated().map { index, value in
      let path = "displays[\(index)]"

      guard let info = value as? [String: Any],
        let name = info["Display Identifier"] as? String, !name.isEmpty,
        let rawSpaces = info["Spaces"] as? [Any]
      else { throw SkyLightError.malformedResponse(path) }

      let displayID = DisplayID(rawValue: name)

      guard seen.insert(displayID).inserted else {
        throw SkyLightError.malformedResponse("\(path).Display Identifier")
      }

      var seenSpaces = Set<SpaceID>()
      let spaces = try rawSpaces.enumerated().map { offset, raw -> Space in
        let spacePath = "\(path).Spaces[\(offset)]"

        guard let entry = raw as? [String: Any] else {
          throw SkyLightError.malformedResponse(spacePath)
        }

        let id = try identifier(entry, path: spacePath)

        guard seenSpaces.insert(id).inserted,
          let type = integer(entry["type"]).flatMap(Int32.init), type >= 0
        else { throw SkyLightError.malformedResponse(spacePath) }

        return Space(id: id, type: SpaceType(rawValue: type))
      }

      var current: SpaceID?

      if let rawCurrent = info["Current Space"] {
        guard let entry = rawCurrent as? [String: Any] else {
          throw SkyLightError.malformedResponse("\(path).Current Space")
        }

        current = try identifier(entry, path: "\(path).Current Space")
      }

      return DisplaySpaces(id: displayID, spaces: spaces, currentSpaceID: current)
    }
  }

  static func identifiers(_ values: [Any]) throws -> [SpaceID] {
    var seen = Set<SpaceID>()

    return try values.enumerated().compactMap { index, value in
      guard let raw = integer(value).flatMap(UInt64.init), raw > 0 else {
        throw SkyLightError.malformedResponse("spaces[\(index)]")
      }

      let id = SpaceID(rawValue: raw)

      return seen.insert(id).inserted ? id : nil
    }
  }

  private static func identifier(_ entry: [String: Any], path: String) throws -> SpaceID {
    // Both spellings are emitted by WindowServer. If both exist, they must agree.
    let keys = ["ManagedSpaceID", "id64"].filter { entry[$0] != nil }

    guard !keys.isEmpty else { throw SkyLightError.malformedResponse(path) }

    let values = try keys.map { key -> UInt64 in
      guard let value = integer(entry[key]).flatMap(UInt64.init), value > 0 else {
        throw SkyLightError.malformedResponse("\(path).\(key)")
      }

      return value
    }

    guard Set(values).count == 1 else { throw SkyLightError.malformedResponse(path) }

    return SpaceID(rawValue: values[0])
  }

  private static func integer(_ value: Any?) -> String? {
    guard let number = value as? NSNumber,
      CFGetTypeID(number) != CFBooleanGetTypeID()
    else { return nil }

    // Decimal parsing avoids NSNumber's truncating and signed-to-unsigned conversions.
    return number.stringValue
  }
}
