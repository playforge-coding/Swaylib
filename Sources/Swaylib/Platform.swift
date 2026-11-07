#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Darwin)
import Darwin
#elseif os(Windows)
import ucrt
#endif

// The only place in the library that reaches past raylib to the C runtime.
enum Platform {
    static func environment(_ name: String) -> String? {
        guard let value = getenv(name) else { return nil }
        return String(cString: value)
    }
}
