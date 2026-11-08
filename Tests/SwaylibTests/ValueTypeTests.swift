import CRaylib
import Swaylib
import Testing

@Suite("Value types")
struct ValueTypeTests {
    @Test("Match raylib's struct layouts")
    func layouts() {
        #expect(MemoryLayout<Swaylib.Vector2>.size == MemoryLayout<CRaylib.Vector2>.size)
        #expect(MemoryLayout<Swaylib.Vector3>.size == MemoryLayout<CRaylib.Vector3>.size)
        #expect(MemoryLayout<Swaylib.Vector4>.size == MemoryLayout<CRaylib.Vector4>.size)
        #expect(MemoryLayout<Swaylib.Matrix>.size == MemoryLayout<CRaylib.Matrix>.size)
        #expect(MemoryLayout<Swaylib.Rectangle>.size == MemoryLayout<CRaylib.Rectangle>.size)
        #expect(MemoryLayout<Swaylib.Color>.size == MemoryLayout<CRaylib.Color>.size)
        #expect(MemoryLayout<Swaylib.Camera2D>.size == MemoryLayout<CRaylib.Camera2D>.size)
        #expect(MemoryLayout<Swaylib.Quaternion>.size == MemoryLayout<CRaylib.Quaternion>.size)
        #expect(MemoryLayout<Swaylib.Vector2>.alignment == MemoryLayout<CRaylib.Vector2>.alignment)
        #expect(MemoryLayout<Swaylib.Matrix>.alignment == MemoryLayout<CRaylib.Matrix>.alignment)
    }

    @Test("Matrix fields sit where raylib's do")
    func matrixOffsets() {
        // Size and alignment alone would not catch two swapped fields.
        let swift: [PartialKeyPath<Swaylib.Matrix>] = [
            \.m0, \.m1, \.m2, \.m3, \.m4, \.m5, \.m6, \.m7, \.m8, \.m9, \.m10, \.m11, \.m12, \.m13, \.m14, \.m15,
        ]
        let c: [PartialKeyPath<CRaylib.Matrix>] = [
            \.m0, \.m1, \.m2, \.m3, \.m4, \.m5, \.m6, \.m7, \.m8, \.m9, \.m10, \.m11, \.m12, \.m13, \.m14, \.m15,
        ]
        let swiftOffsets = swift.map { MemoryLayout<Swaylib.Matrix>.offset(of: $0) }
        let cOffsets = c.map { MemoryLayout<CRaylib.Matrix>.offset(of: $0) }
        #expect(swiftOffsets == cOffsets)
    }

    @Test("Shader language matches the backend raylib was built for")
    func shaderLanguage() {
        let expected: Swaylib.ShaderLanguage = rlGetVersion() == Int32(RL_OPENGL_ES_30.rawValue) ? .glslES300 : .glsl330
        #expect(Swaylib.Shader.language == expected)
    }

    @Test("Vector4 products are component-wise")
    func vector4() {
        #expect(Swaylib.Vector4(1, 2, 3, 4) * Swaylib.Vector4(1, 1, 1, 1) == Swaylib.Vector4(1, 2, 3, 4))
        #expect(Swaylib.Vector4(1, 2, 3, 4) * Swaylib.Vector4(2, 0, 1, 0.5) == Swaylib.Vector4(2, 0, 3, 2))
        #expect(2 * Swaylib.Vector4(1, 2, 3, 4) == Swaylib.Vector4(2, 4, 6, 8))
    }

    @Test("Vector2 arithmetic")
    func vector2() {
        let a = Swaylib.Vector2(3, 4)
        #expect(a.length == 5)
        #expect(a.normalized.x.isApproximately(0.6))
        #expect(a + Swaylib.Vector2(1, 1) == Swaylib.Vector2(4, 5))
        #expect(a * 2 == Swaylib.Vector2(6, 8))
        #expect(2 * a == Swaylib.Vector2(6, 8))
        #expect(-a == Swaylib.Vector2(-3, -4))
        #expect(a.dot(Swaylib.Vector2(1, 0)) == 3)
        #expect(a.distance(to: .zero) == 5)
        #expect(Swaylib.Vector2.zero.lerp(to: a, amount: 0.5) == Swaylib.Vector2(1.5, 2))
        var b = a
        b += Swaylib.Vector2(1, 1)
        b *= 2
        #expect(b == Swaylib.Vector2(8, 10))
        let rotated = Swaylib.Vector2(1, 0).rotated(by: .pi / 2)
        #expect(rotated.x.isApproximately(0))
        #expect(rotated.y.isApproximately(1))
    }

    @Test("Vector3 arithmetic")
    func vector3() {
        let x = Swaylib.Vector3(1, 0, 0)
        let y = Swaylib.Vector3(0, 1, 0)
        #expect(x.cross(y) == Swaylib.Vector3(0, 0, 1))
        #expect(x.dot(y) == 0)
        #expect((x + y).length.isApproximately(Float(2).squareRoot()))
        #expect(x.transformed(by: .translation(Swaylib.Vector3(1, 2, 3))) == Swaylib.Vector3(2, 2, 3))
    }

    @Test("Matrix operations through raymath")
    func matrix() {
        let translate = Swaylib.Matrix.translation(Swaylib.Vector3(1, 2, 3))
        let scale = Swaylib.Matrix.scale(Swaylib.Vector3(2, 2, 2))
        let point = Swaylib.Vector3(1, 1, 1)
        // MatrixMultiply applies the left matrix first.
        #expect(point.transformed(by: scale * translate) == Swaylib.Vector3(3, 4, 5))
        #expect(point.transformed(by: translate * scale) == Swaylib.Vector3(4, 6, 8))
        #expect(Swaylib.Matrix.identity.determinant == 1)
        let roundTrip = point.transformed(by: translate.inverted).transformed(by: translate)
        #expect(roundTrip.x.isApproximately(1))
        #expect(translate.transposed.m3 == 1)
    }

    @Test("Quaternion rotation")
    func quaternion() {
        let quarterTurn = Swaylib.Quaternion(axis: .up, radians: .pi / 2)
        let rotated = Swaylib.Vector3(1, 0, 0).transformed(by: quarterTurn.matrix)
        #expect(rotated.x.isApproximately(0))
        #expect(rotated.z.isApproximately(-1))
        #expect((quarterTurn * quarterTurn.inverted).w.isApproximately(1))
    }

    @Test("Quaternion products apply the left rotation first")
    func quaternionOrder() {
        // Rotations around different axes do not commute, so this tells the two orders apart.
        let yaw = Swaylib.Quaternion(axis: .up, radians: .pi / 2)
        let roll = Swaylib.Quaternion(axis: Swaylib.Vector3(0, 0, 1), radians: .pi / 2)
        let start = Swaylib.Vector3(1, 0, 0)

        let stepByStep = start.rotated(by: yaw).rotated(by: roll)
        let combined = start.rotated(by: yaw * roll)
        #expect(combined.x.isApproximately(stepByStep.x))
        #expect(combined.y.isApproximately(stepByStep.y))
        #expect(combined.z.isApproximately(stepByStep.z))
        let otherOrder = start.rotated(by: roll * yaw)
        #expect(!otherOrder.y.isApproximately(stepByStep.y) || !otherOrder.z.isApproximately(stepByStep.z))

        // The same order as Matrix's *.
        let viaMatrices = start.transformed(by: yaw.matrix * roll.matrix)
        #expect(viaMatrices.x.isApproximately(stepByStep.x))
        #expect(viaMatrices.y.isApproximately(stepByStep.y))
        #expect(viaMatrices.z.isApproximately(stepByStep.z))
    }

    @Test("Rectangle collisions")
    func rectangle() {
        let a = Swaylib.Rectangle(x: 0, y: 0, width: 10, height: 10)
        let b = Swaylib.Rectangle(origin: Swaylib.Vector2(5, 5), size: Swaylib.Vector2(10, 10))
        #expect(a.intersects(b))
        #expect(a.intersection(with: b) == Swaylib.Rectangle(x: 5, y: 5, width: 5, height: 5))
        #expect(a.intersection(with: Swaylib.Rectangle(x: 20, y: 20, width: 1, height: 1)) == nil)
        #expect(a.contains(Swaylib.Vector2(9, 9)))
        #expect(!a.contains(Swaylib.Vector2(10, 10)))
        #expect(a.intersects(circleAt: Swaylib.Vector2(12, 5), radius: 3))
        #expect(a.center == Swaylib.Vector2(5, 5))
        var c = a
        c.origin = Swaylib.Vector2(1, 2)
        c.size = Swaylib.Vector2(3, 4)
        #expect(c == Swaylib.Rectangle(x: 1, y: 2, width: 3, height: 4))
    }

    @Test("Color conversions")
    func color() {
        let color = Swaylib.Color(red: 0x12, green: 0x34, blue: 0x56, alpha: 0x78)
        #expect(color.hex == 0x1234_5678)
        #expect(Swaylib.Color(hex: 0x1234_5678) == color)
        #expect(Swaylib.Color.rayWhite == Swaylib.Color(red: 245, green: 245, blue: 245))
        #expect(Swaylib.Color.blank == Swaylib.Color(red: 0, green: 0, blue: 0, alpha: 0))
        #expect(Swaylib.Color.red.withAlpha(0.5).alpha == 127)
        #expect(Swaylib.Color(hue: 120, saturation: 1, value: 1) == Swaylib.Color(red: 0, green: 255, blue: 0))
        #expect(Swaylib.Color.black.lerp(to: .white, amount: 1) == .white)
        #expect(Swaylib.Color.white.normalized == Swaylib.Vector4(1, 1, 1, 1))
        #expect(Swaylib.Color(normalized: Swaylib.Vector4(0, 0, 1, 1)) == Swaylib.Color(red: 0, green: 0, blue: 255))
    }

    @Test("Camera2D maps between world and screen")
    func camera2D() {
        let camera = Swaylib.Camera2D(offset: Swaylib.Vector2(100, 100), target: .zero, zoom: 2)
        #expect(camera.worldToScreen(Swaylib.Vector2(10, 10)) == Swaylib.Vector2(120, 120))
        #expect(camera.screenToWorld(Swaylib.Vector2(120, 120)) == Swaylib.Vector2(10, 10))
    }

    @Test("Random values stay in range")
    @MainActor
    func random() {
        Random.seed(42)
        for _ in 0..<100 {
            let value = Random.value(in: -3...3)
            #expect((-3...3).contains(value))
        }
    }
}

extension Float {
    func isApproximately(_ other: Float, tolerance: Float = 1e-5) -> Bool {
        abs(self - other) <= tolerance
    }
}
