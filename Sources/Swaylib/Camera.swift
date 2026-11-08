import CRaylib

/// A 2D camera for ``mode2D(_:_:)``. Same layout as raylib's `Camera2D`.
public struct Camera2D: Hashable, Sendable {
    /// Where ``target`` lands on screen, in pixels from the top left.
    public var offset: Vector2
    /// The world point the camera looks at.
    public var target: Vector2
    /// Rotation in degrees around the target.
    public var rotation: Float
    /// Zoom around the target; 1 is no scaling.
    public var zoom: Float

    /// Creates a camera. The defaults show the world unscaled with its origin at the top left.
    public init(offset: Vector2 = .zero, target: Vector2 = .zero, rotation: Float = 0, zoom: Float = 1) {
        self.offset = offset
        self.target = target
        self.rotation = rotation
        self.zoom = zoom
    }

    var raw: CRaylib.Camera2D {
        CRaylib.Camera2D(offset: offset.raw, target: target.raw, rotation: rotation, zoom: zoom)
    }

    /// The camera's transform.
    public var matrix: Matrix {
        Matrix(GetCameraMatrix2D(raw))
    }

    /// Where a world point appears on screen.
    public func worldToScreen(_ position: Vector2) -> Vector2 {
        Vector2(GetWorldToScreen2D(position.raw, raw))
    }

    /// The world point under a screen position.
    public func screenToWorld(_ position: Vector2) -> Vector2 {
        Vector2(GetScreenToWorld2D(position.raw, raw))
    }
}

/// A 3D camera for ``mode3D(_:_:)``. Converted field by field to raylib's `Camera3D`, because
/// ``projection`` is a Swift enum rather than a C int.
public struct Camera3D: Hashable, Sendable {
    /// Where the camera is.
    public var position: Vector3
    /// The point the camera looks at.
    public var target: Vector3
    /// The up direction.
    public var up: Vector3
    /// The vertical field of view in degrees, or the near plane height for orthographic projection.
    public var fovy: Float
    /// Perspective or orthographic.
    public var projection: CameraProjection

    /// Creates a camera.
    public init(
        position: Vector3, target: Vector3 = .zero, up: Vector3 = .up, fovy: Float = 45,
        projection: CameraProjection = .perspective
    ) {
        self.position = position
        self.target = target
        self.up = up
        self.fovy = fovy
        self.projection = projection
    }

    init(_ raw: CRaylib.Camera3D) {
        self.init(
            position: Vector3(raw.position), target: Vector3(raw.target), up: Vector3(raw.up), fovy: raw.fovy,
            projection: CameraProjection(rawValue: raw.projection) ?? .perspective
        )
    }

    var raw: CRaylib.Camera3D {
        CRaylib.Camera3D(
            position: position.raw, target: target.raw, up: up.raw, fovy: fovy, projection: projection.rawValue
        )
    }

    /// The camera's view matrix.
    public var matrix: Matrix {
        Matrix(GetCameraMatrix(raw))
    }

    /// Where a world point appears on screen.
    @MainActor
    public func worldToScreen(_ position: Vector3) -> Vector2 {
        Vector2(GetWorldToScreen(position.raw, raw))
    }

    /// Moves the camera for one frame from keyboard and mouse input, in one of raylib's built-in modes.
    @MainActor
    public mutating func update(mode: CameraMode) {
        var camera = raw
        UpdateCamera(&camera, mode.rawValue)
        self = Camera3D(camera)
    }
}
