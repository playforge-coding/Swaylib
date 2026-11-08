import CRaylib
import Foundation
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

    /// Raw values of every generated enum, keyed by its raylib name.
    static let generated: [String: [Int32]] = [
        "TraceLogLevel": rawValues(of: Swaylib.TraceLogLevel.self),
        "KeyboardKey": rawValues(of: Swaylib.KeyboardKey.self),
        "MouseButton": rawValues(of: Swaylib.MouseButton.self),
        "MouseCursor": rawValues(of: Swaylib.MouseCursor.self),
        "GamepadButton": rawValues(of: Swaylib.GamepadButton.self),
        "GamepadAxis": rawValues(of: Swaylib.GamepadAxis.self),
        "MaterialMapIndex": rawValues(of: Swaylib.MaterialMapIndex.self),
        "ShaderLocationIndex": rawValues(of: Swaylib.ShaderLocationIndex.self),
        "ShaderUniformDataType": rawValues(of: Swaylib.ShaderUniformDataType.self),
        "ShaderAttributeDataType": rawValues(of: Swaylib.ShaderAttributeDataType.self),
        "PixelFormat": rawValues(of: Swaylib.PixelFormat.self),
        "TextureFilter": rawValues(of: Swaylib.TextureFilter.self),
        "TextureWrap": rawValues(of: Swaylib.TextureWrap.self),
        "CubemapLayout": rawValues(of: Swaylib.CubemapLayout.self),
        "FontType": rawValues(of: Swaylib.FontType.self),
        "BlendMode": rawValues(of: Swaylib.BlendMode.self),
        "CameraMode": rawValues(of: Swaylib.CameraMode.self),
        "CameraProjection": rawValues(of: Swaylib.CameraProjection.self),
        "NPatchLayout": rawValues(of: Swaylib.NPatchLayout.self),
    ]

    /// raylib's flag sets, generated as option sets rather than enums.
    static let optionSets: Set<String> = ["ConfigFlags", "Gesture"]

    static func rawValues<E: CaseIterable & RawRepresentable>(of type: E.Type) -> [Int32] where E.RawValue == Int32 {
        type.allCases.map(\.rawValue).sorted()
    }

    @Test("Every raylib enum and value has a generated counterpart")
    func casesMatchRaylib() throws {
        // Read raylib's own parser output from the submodule, independently of the generator.
        let apiFile = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/CRaylib/raylib/tools/rlparser/output/raylib_api.json")
        let api = try JSONDecoder().decode(RaylibAPI.self, from: Data(contentsOf: apiFile))

        for raylibEnum in api.enums where !Self.optionSets.contains(raylibEnum.name) {
            let expected = raylibEnum.values.map(\.value).sorted()
            #expect(Self.generated[raylibEnum.name] == expected, "\(raylibEnum.name) differs from raylib")
        }
        let raylibNames = Set(api.enums.map(\.name))
        #expect(Set(Self.generated.keys).union(Self.optionSets) == raylibNames)
    }
}

/// The part of `raylib_api.json` this test reads.
private struct RaylibAPI: Decodable {
    struct Enum: Decodable {
        struct Value: Decodable {
            let value: Int32
        }
        let name: String
        let values: [Value]
    }
    let enums: [Enum]
}
