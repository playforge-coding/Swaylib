import CRaylib
import Swaylib
import Testing

// CRaylib exports the same enum names, so the generated types are qualified here.
@Suite("Generated enums")
struct GeneratedEnumTests {
    @Test("Raw values match raylib's constants")
    func rawValues() {
        #expect(Swaylib.KeyboardKey.space.rawValue == Int32(KEY_SPACE.rawValue))
        #expect(Swaylib.KeyboardKey.leftShift.rawValue == Int32(KEY_LEFT_SHIFT.rawValue))
        #expect(Swaylib.KeyboardKey.keypad0.rawValue == Int32(KEY_KP_0.rawValue))
        #expect(Swaylib.MouseButton.left.rawValue == Int32(MOUSE_BUTTON_LEFT.rawValue))
        #expect(Swaylib.MouseCursor.default.rawValue == Int32(MOUSE_CURSOR_DEFAULT.rawValue))
        #expect(Swaylib.TextureWrap.repeat.rawValue == Int32(TEXTURE_WRAP_REPEAT.rawValue))
        #expect(
            Swaylib.PixelFormat.uncompressedR8G8B8A8.rawValue == Int32(PIXELFORMAT_UNCOMPRESSED_R8G8B8A8.rawValue)
        )
        #expect(Swaylib.BlendMode.additive.rawValue == Int32(BLEND_ADDITIVE.rawValue))
        #expect(Swaylib.CameraProjection.orthographic.rawValue == Int32(CAMERA_ORTHOGRAPHIC.rawValue))
        #expect(Swaylib.TraceLogLevel.warning.rawValue == Int32(LOG_WARNING.rawValue))
    }

    @Test("Flags are option sets")
    func optionSets() {
        #expect(Swaylib.ConfigFlags.vsyncHint.rawValue == FLAG_VSYNC_HINT.rawValue)
        #expect(Swaylib.ConfigFlags.windowResizable.rawValue == FLAG_WINDOW_RESIZABLE.rawValue)
        let both: Swaylib.ConfigFlags = [.vsyncHint, .windowResizable]
        #expect(both.rawValue == FLAG_VSYNC_HINT.rawValue | FLAG_WINDOW_RESIZABLE.rawValue)
        #expect(Swaylib.Gesture.none.isEmpty)
        #expect(Swaylib.Gesture.tap.rawValue == GESTURE_TAP.rawValue)
    }

    @Test("Every raylib value has a case")
    func caseCounts() {
        #expect(Swaylib.KeyboardKey.allCases.count == 110)
        #expect(Swaylib.GamepadButton.allCases.count == 18)
        #expect(Swaylib.PixelFormat.allCases.count == 24)
    }
}
