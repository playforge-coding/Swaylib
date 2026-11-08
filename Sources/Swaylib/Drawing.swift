import CRaylib

/// Draws one frame: everything drawn inside `body` appears on screen when it returns.
///
/// Wraps raylib's `BeginDrawing` and `EndDrawing`, so the frame ends even if `body` throws.
@MainActor
public func drawing(_ body: () throws -> Void) rethrows {
    BeginDrawing()
    defer {
        Headless.frameEnding()
        EndDrawing()
    }
    try body()
}

/// Draws `body` through a 2D camera.
///
/// The modes below can nest in any combination. When an inner one ends, drawing goes on with
/// whatever the enclosing calls set up, not raylib's defaults.
@MainActor
public func mode2D(_ camera: Camera2D, _ body: () throws -> Void) rethrows {
    BeginMode2D(camera.raw)
    DrawingState.cameras.append(.twoD(camera.raw))
    defer {
        EndMode2D()
        DrawingState.cameras.removeLast()
        DrawingState.restoreCamera()
    }
    try body()
}

/// Draws `body` through a 3D camera.
@MainActor
public func mode3D(_ camera: Camera3D, _ body: () throws -> Void) rethrows {
    BeginMode3D(camera.raw)
    DrawingState.cameras.append(.threeD(camera.raw))
    defer {
        EndMode3D()
        DrawingState.cameras.removeLast()
        DrawingState.restoreCamera()
    }
    try body()
}

/// Draws `body` into a render texture instead of the screen.
///
/// The body starts without a camera, even inside ``mode2D(_:_:)`` or ``mode3D(_:_:)``, since those
/// were set up for the outer target. When it ends, drawing goes back to the outer render texture
/// (or the screen) and its camera.
@MainActor
public func textureMode(_ target: borrowing RenderTexture, _ body: () throws -> Void) rethrows {
    BeginTextureMode(target.raw)
    DrawingState.targets.append(target.raw)
    DrawingState.cameras.append(nil)
    defer {
        EndTextureMode()
        DrawingState.targets.removeLast()
        DrawingState.cameras.removeLast()
        if let outer = DrawingState.targets.last {
            BeginTextureMode(outer)
        }
        DrawingState.restoreCamera()
    }
    try body()
}

/// What the scoped modes that are currently open set up, innermost last. raylib only knows the
/// current value of each and resets it to its default when a mode ends, so the enclosing value is
/// set again from here.
@MainActor
enum DrawingState {
    enum Camera {
        case twoD(CRaylib.Camera2D)
        case threeD(CRaylib.Camera3D)
    }

    static var targets: [RenderTexture2D] = []
    /// nil entries mark a ``textureMode(_:_:)``, which starts without a camera.
    static var cameras: [Camera?] = []
    static var shaders: [CRaylib.Shader] = []
    static var blendModes: [BlendMode] = []
    static var scissorAreas: [Rectangle] = []

    /// Sets up the camera of the innermost open camera mode again, after an inner mode reset it.
    static func restoreCamera() {
        switch cameras.last {
        case .twoD(let camera):
            BeginMode2D(camera)
        case .threeD(let camera):
            // BeginMode3D pushes the projection matrix and EndMode3D pops it, so pop the outer
            // mode's push before pushing again; its own EndMode3D pops this one.
            EndMode3D()
            BeginMode3D(camera)
        case nil, .some(nil):
            break
        }
    }
}

/// Draws `body` with a custom shader.
@MainActor
public func shaderMode(_ shader: borrowing Shader, _ body: () throws -> Void) rethrows {
    BeginShaderMode(shader.raw)
    DrawingState.shaders.append(shader.raw)
    defer {
        EndShaderMode()
        DrawingState.shaders.removeLast()
        if let outer = DrawingState.shaders.last {
            BeginShaderMode(outer)
        }
    }
    try body()
}

/// Draws `body` with a blend mode other than the default alpha blending.
@MainActor
public func blendMode(_ mode: BlendMode, _ body: () throws -> Void) rethrows {
    BeginBlendMode(mode.rawValue)
    DrawingState.blendModes.append(mode)
    defer {
        EndBlendMode()
        DrawingState.blendModes.removeLast()
        if let outer = DrawingState.blendModes.last {
            BeginBlendMode(outer.rawValue)
        }
    }
    try body()
}

/// Clips everything drawn in `body` to a rectangle in screen pixels. A nested call replaces the
/// outer rectangle until it ends rather than intersecting with it.
@MainActor
public func scissorMode(_ area: Rectangle, _ body: () throws -> Void) rethrows {
    DrawingState.beginScissor(area)
    DrawingState.scissorAreas.append(area)
    defer {
        EndScissorMode()
        DrawingState.scissorAreas.removeLast()
        if let outer = DrawingState.scissorAreas.last {
            DrawingState.beginScissor(outer)
        }
    }
    try body()
}

extension DrawingState {
    static func beginScissor(_ area: Rectangle) {
        BeginScissorMode(Int32(area.x), Int32(area.y), Int32(area.width), Int32(area.height))
    }
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
