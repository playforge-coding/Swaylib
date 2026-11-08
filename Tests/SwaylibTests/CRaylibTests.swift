import CRaylib
import CRaylibShims
import Swaylib
import Testing

@Suite("Vendored raylib")
struct CRaylibTests {
    @Test("Reports the vendored release")
    func version() {
        #expect(raylibVersion == "6.2")
        #expect(RAYLIB_VERSION_MAJOR == 6)
        #expect(RAYLIB_VERSION_MINOR == 2)
    }

    @Test("Calls into rtextures without a window")
    func colorToInt() {
        let color = CRaylib.Color(r: 0x12, g: 0x34, b: 0x56, a: 0x78)
        #expect(ColorToInt(color) == 0x1234_5678)
    }

    @Test("Imports raymath's inline functions")
    func vectorAdd() {
        let sum = Vector2Add(CRaylib.Vector2(x: 1, y: 2), CRaylib.Vector2(x: 3, y: 4))
        #expect(sum.x == 4)
        #expect(sum.y == 6)
    }
}
