import CRaylib

/// Draws one frame: everything drawn inside `body` appears on screen when it returns.
///
/// Wraps raylib's `BeginDrawing` and `EndDrawing`, so the frame ends even if `body` throws.
@MainActor
public func drawing(_ body: () throws -> Void) rethrows {
    BeginDrawing()
    defer {
        EndDrawing()
        Headless.frameEnded()
    }
    try body()
}

/// Draws `body` through a 2D camera.
@MainActor
public func mode2D(_ camera: Camera2D, _ body: () throws -> Void) rethrows {
    BeginMode2D(camera.raw)
    defer { EndMode2D() }
    try body()
}

/// Draws `body` through a 3D camera.
@MainActor
public func mode3D(_ camera: Camera3D, _ body: () throws -> Void) rethrows {
    BeginMode3D(camera.raw)
    defer { EndMode3D() }
    try body()
}

/// Draws `body` into a render texture instead of the screen.
@MainActor
public func textureMode(_ target: borrowing RenderTexture, _ body: () throws -> Void) rethrows {
    BeginTextureMode(target.raw)
    defer { EndTextureMode() }
    try body()
}

/// Draws `body` with a custom shader.
@MainActor
public func shaderMode(_ shader: borrowing Shader, _ body: () throws -> Void) rethrows {
    BeginShaderMode(shader.raw)
    defer { EndShaderMode() }
    try body()
}

/// Draws `body` with a blend mode other than the default alpha blending.
@MainActor
public func blendMode(_ mode: BlendMode, _ body: () throws -> Void) rethrows {
    BeginBlendMode(mode.rawValue)
    defer { EndBlendMode() }
    try body()
}

/// Clips everything drawn in `body` to a rectangle in screen pixels.
@MainActor
public func scissorMode(_ area: Rectangle, _ body: () throws -> Void) rethrows {
    BeginScissorMode(Int32(area.x), Int32(area.y), Int32(area.width), Int32(area.height))
    defer { EndScissorMode() }
    try body()
}

/// Immediate drawing of shapes, text and 3D primitives. Call these inside ``drawing(_:)``.
@MainActor
public enum Draw {
    /// Fills the whole target with a color.
    public static func clearBackground(_ color: Color) {
        ClearBackground(color.raw)
    }

    /// Draws the current frame rate.
    public static func fps(x: Int, y: Int) {
        DrawFPS(Int32(x), Int32(y))
    }

    // MARK: Shapes

    /// Draws a single pixel.
    public static func pixel(at position: Vector2, color: Color) {
        DrawPixelV(position.raw, color.raw)
    }

    /// Draws a one pixel wide line.
    public static func line(from start: Vector2, to end: Vector2, color: Color) {
        DrawLineV(start.raw, end.raw, color.raw)
    }

    /// Draws a line with a thickness.
    public static func line(from start: Vector2, to end: Vector2, thickness: Float, color: Color) {
        DrawLineEx(start.raw, end.raw, thickness, color.raw)
    }

    /// Draws connected line segments through the points.
    public static func lineStrip(_ points: [Vector2], color: Color) {
        points.withUnsafeBufferPointer { buffer in
            buffer.withMemoryRebound(to: CRaylib.Vector2.self) { raw in
                DrawLineStrip(raw.baseAddress, Int32(raw.count), color.raw)
            }
        }
    }

    /// Draws a filled circle.
    public static func circle(center: Vector2, radius: Float, color: Color) {
        DrawCircleV(center.raw, radius, color.raw)
    }

    /// Draws a circle outline.
    public static func circleLines(center: Vector2, radius: Float, color: Color) {
        DrawCircleLinesV(center.raw, radius, color.raw)
    }

    /// Draws a circle shaded from `inner` at the center to `outer` at the edge.
    public static func circleGradient(center: Vector2, radius: Float, inner: Color, outer: Color) {
        DrawCircleGradient(center.raw, radius, inner.raw, outer.raw)
    }

    /// Draws a pie slice between two angles in degrees.
    public static func circleSector(
        center: Vector2, radius: Float, startAngle: Float, endAngle: Float, segments: Int = 36, color: Color
    ) {
        DrawCircleSector(center.raw, radius, startAngle, endAngle, Int32(segments), color.raw)
    }

    /// Draws a ring, or a piece of one between two angles in degrees.
    public static func ring(
        center: Vector2, innerRadius: Float, outerRadius: Float, startAngle: Float = 0, endAngle: Float = 360,
        segments: Int = 36, color: Color
    ) {
        DrawRing(center.raw, innerRadius, outerRadius, startAngle, endAngle, Int32(segments), color.raw)
    }

    /// Draws a filled ellipse.
    public static func ellipse(center: Vector2, radiusH: Float, radiusV: Float, color: Color) {
        DrawEllipseV(center.raw, radiusH, radiusV, color.raw)
    }

    /// Draws a filled rectangle.
    public static func rectangle(_ rectangle: Rectangle, color: Color) {
        DrawRectangleRec(rectangle.raw, color.raw)
    }

    /// Draws a filled rectangle rotated by degrees around `origin`, which is relative to its top left.
    public static func rectangle(_ rectangle: Rectangle, origin: Vector2, rotation: Float, color: Color) {
        DrawRectanglePro(rectangle.raw, origin.raw, rotation, color.raw)
    }

    /// Draws a rectangle outline.
    public static func rectangleLines(_ rectangle: Rectangle, thickness: Float = 1, color: Color) {
        DrawRectangleLinesEx(rectangle.raw, thickness, color.raw)
    }

    /// Draws a rectangle with one color per corner.
    public static func rectangleGradient(
        _ rectangle: Rectangle, topLeft: Color, bottomLeft: Color, bottomRight: Color, topRight: Color
    ) {
        DrawRectangleGradientEx(rectangle.raw, topLeft.raw, bottomLeft.raw, bottomRight.raw, topRight.raw)
    }

    /// Draws a filled rectangle with rounded corners; `roundness` is 0 (square) to 1 (fully round).
    public static func rectangleRounded(_ rectangle: Rectangle, roundness: Float, segments: Int = 8, color: Color) {
        DrawRectangleRounded(rectangle.raw, roundness, Int32(segments), color.raw)
    }

    /// Draws a rounded rectangle outline.
    public static func rectangleRoundedLines(
        _ rectangle: Rectangle, roundness: Float, segments: Int = 8, thickness: Float = 1, color: Color
    ) {
        DrawRectangleRoundedLinesEx(rectangle.raw, roundness, Int32(segments), thickness, color.raw)
    }

    /// Draws a filled triangle; give the vertices counterclockwise.
    public static func triangle(_ a: Vector2, _ b: Vector2, _ c: Vector2, color: Color) {
        DrawTriangle(a.raw, b.raw, c.raw, color.raw)
    }

    /// Draws a triangle outline.
    public static func triangleLines(_ a: Vector2, _ b: Vector2, _ c: Vector2, color: Color) {
        DrawTriangleLines(a.raw, b.raw, c.raw, color.raw)
    }

    /// Draws a filled regular polygon, rotated by degrees.
    public static func polygon(center: Vector2, sides: Int, radius: Float, rotation: Float = 0, color: Color) {
        DrawPoly(center.raw, Int32(sides), radius, rotation, color.raw)
    }

    /// Draws a regular polygon outline.
    public static func polygonLines(
        center: Vector2, sides: Int, radius: Float, rotation: Float = 0, thickness: Float = 1, color: Color
    ) {
        DrawPolyLinesEx(center.raw, Int32(sides), radius, rotation, thickness, color.raw)
    }

    // MARK: Text

    /// Draws text with the default font at an integer position.
    public static func text(_ text: String, x: Int, y: Int, fontSize: Int = 20, color: Color) {
        DrawText(text, Int32(x), Int32(y), Int32(fontSize), color.raw)
    }

    /// Draws text with a font. `spacing` is the extra pixels between characters.
    public static func text(
        _ text: String, font: borrowing Font = .default, at position: Vector2, fontSize: Float, spacing: Float = 1,
        color: Color
    ) {
        DrawTextEx(font.raw, text, position.raw, fontSize, spacing, color.raw)
    }

    /// Draws text rotated by degrees around `origin`, which is relative to the text's top left.
    public static func text(
        _ text: String, font: borrowing Font = .default, at position: Vector2, origin: Vector2, rotation: Float,
        fontSize: Float, spacing: Float = 1, color: Color
    ) {
        DrawTextPro(font.raw, text, position.raw, origin.raw, rotation, fontSize, spacing, color.raw)
    }

    // MARK: 3D

    /// Draws a line in 3D space.
    public static func line3D(from start: Vector3, to end: Vector3, color: Color) {
        DrawLine3D(start.raw, end.raw, color.raw)
    }

    /// Draws a filled box centered at `position`.
    public static func cube(at position: Vector3, size: Vector3, color: Color) {
        DrawCubeV(position.raw, size.raw, color.raw)
    }

    /// Draws the edges of a box centered at `position`.
    public static func cubeWires(at position: Vector3, size: Vector3, color: Color) {
        DrawCubeWiresV(position.raw, size.raw, color.raw)
    }

    /// Draws a filled sphere.
    public static func sphere(at center: Vector3, radius: Float, color: Color) {
        DrawSphere(center.raw, radius, color.raw)
    }

    /// Draws a wireframe sphere.
    public static func sphereWires(at center: Vector3, radius: Float, rings: Int = 16, slices: Int = 16, color: Color) {
        DrawSphereWires(center.raw, radius, Int32(rings), Int32(slices), color.raw)
    }

    /// Draws a cylinder, or a cone when one radius is 0, standing on `position`.
    public static func cylinder(
        at position: Vector3, radiusTop: Float, radiusBottom: Float, height: Float, slices: Int = 16, color: Color
    ) {
        DrawCylinder(position.raw, radiusTop, radiusBottom, height, Int32(slices), color.raw)
    }

    /// Draws a capsule between two points.
    public static func capsule(
        from start: Vector3, to end: Vector3, radius: Float, slices: Int = 16, rings: Int = 8, color: Color
    ) {
        DrawCapsule(start.raw, end.raw, radius, Int32(slices), Int32(rings), color.raw)
    }

    /// Draws a flat rectangle on the XZ plane centered at `position`.
    public static func plane(at position: Vector3, size: Vector2, color: Color) {
        DrawPlane(position.raw, size.raw, color.raw)
    }

    /// Draws a grid on the XZ plane centered at the origin.
    public static func grid(slices: Int, spacing: Float) {
        DrawGrid(Int32(slices), spacing)
    }
}
