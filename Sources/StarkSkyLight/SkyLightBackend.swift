import Darwin
import Foundation

@MainActor
final class SkyLightBackend: SpaceBackend {
  private typealias Connection = @convention(c) () -> Int32
  private typealias CopyDisplays = @convention(c) (Int32) -> Unmanaged<CFArray>?
  private typealias ActiveSpace = @convention(c) (Int32) -> UInt64
  private typealias CurrentSpace = @convention(c) (Int32, CFString) -> UInt64
  private typealias GetType = @convention(c) (Int32, UInt64) -> Int32
  private typealias CopySpaces = @convention(c) (Int32, Int32, CFArray) -> Unmanaged<CFArray>?

  private let library: DynamicLibrary
  private let connection: Connection
  private let copyDisplays: CopyDisplays
  private let getActive: ActiveSpace
  private let getCurrent: CurrentSpace
  private let getType: GetType
  private let copySpaces: CopySpaces

  init() throws {
    let library = try DynamicLibrary()

    self.library = library
    connection = try library.load("SLSMainConnectionID")
    copyDisplays = try library.load("SLSCopyManagedDisplaySpaces")
    getActive = try library.load("SLSGetActiveSpace")
    getCurrent = try library.load("SLSManagedDisplayGetCurrentSpace")
    getType = try library.load("SLSSpaceGetType")
    copySpaces = try library.load("SLSCopySpacesForWindows")

    _ = try connectionID()
  }

  func displaySpaces() throws -> [Any] {
    guard let result = copyDisplays(try connectionID())?.takeRetainedValue() else {
      throw SkyLightError.queryFailed("SLSCopyManagedDisplaySpaces")
    }

    return result as [AnyObject]
  }

  func activeSpace() throws -> UInt64 { getActive(try connectionID()) }

  func currentSpace(_ display: String) throws -> UInt64 {
    getCurrent(try connectionID(), display as CFString)
  }

  func spaceType(_ space: UInt64) throws -> Int32 { getType(try connectionID(), space) }

  func spacesForWindow(_ window: UInt32) throws -> [Any] {
    // Selector 0x7 includes all Space kinds. Copy functions return owned CF objects.
    guard let result = copySpaces(try connectionID(), 0x7, [window] as CFArray)?.takeRetainedValue()
    else { throw SkyLightError.queryFailed("SLSCopySpacesForWindows") }

    return result as [AnyObject]
  }

  private func connectionID() throws -> Int32 {
    let value = connection()

    guard value != 0 else { throw SkyLightError.connectionUnavailable }

    return value
  }
}

/// Closes the library when the backend is released or initialization fails.
private final class DynamicLibrary {
  private let handle: UnsafeMutableRawPointer

  init() throws {
    guard
      let handle = dlopen(
        "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
        RTLD_NOW | RTLD_LOCAL
      )
    else {
      let detail = dlerror().map { String(cString: $0) } ?? "unknown loader error"

      throw SkyLightError.frameworkUnavailable(detail)
    }

    self.handle = handle
  }

  deinit { dlclose(handle) }

  func load<T>(_ name: String) throws -> T {
    guard let pointer = dlsym(handle, name) else { throw SkyLightError.symbolUnavailable(name) }

    return unsafeBitCast(pointer, to: T.self)
  }
}
