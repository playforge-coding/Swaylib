import CRaylib

/// A 4D vector. Same layout as raylib's `Vector4`. Rotations have their own type, ``Quaternion``,
/// so that `*` between two vectors stays component-wise as it is for ``Vector2`` and ``Vector3``.
public struct Vector4: Hashable, Sendable {
    /// The x component.
    public var x: Float
    /// The y component.
    public var y: Float
    /// The z component.
    public var z: Float
    /// The w component.
    public var w: Float

    /// Creates a vector from its components.
    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    /// Creates a vector from its components, unlabeled.
    public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    /// (0, 0, 0, 0).
    public static let zero = Vector4(0, 0, 0, 0)

    init(_ raw: CRaylib.Vector4) {
        self.init(raw.x, raw.y, raw.z, raw.w)
    }

    var raw: CRaylib.Vector4 {
        CRaylib.Vector4(x: x, y: y, z: z, w: w)
    }

    /// The length (magnitude).
    public var length: Float {
        (x * x + y * y + z * z + w * w).squareRoot()
    }

    /// Component-wise sum.
    public static func + (lhs: Vector4, rhs: Vector4) -> Vector4 {
        Vector4(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w)
    }

    /// Component-wise difference.
    public static func - (lhs: Vector4, rhs: Vector4) -> Vector4 {
        Vector4(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w)
    }

    /// Component-wise product.
    public static func * (lhs: Vector4, rhs: Vector4) -> Vector4 {
        Vector4(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z, lhs.w * rhs.w)
    }

    /// Scales by a scalar.
    public static func * (lhs: Vector4, rhs: Float) -> Vector4 {
        Vector4(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs)
    }

    /// Scales by a scalar.
    public static func * (lhs: Float, rhs: Vector4) -> Vector4 {
        rhs * lhs
    }
}

/// A rotation stored as a unit quaternion. Same layout as raylib's `Quaternion`, which in C is
/// another name for `Vector4`; here it is a separate type so rotations and vectors do not mix.
public struct Quaternion: Hashable, Sendable {
    /// The x component of the vector part.
    public var x: Float
    /// The y component of the vector part.
    public var y: Float
    /// The z component of the vector part.
    public var z: Float
    /// The scalar part.
    public var w: Float

    /// Creates a quaternion from its components.
    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    init(_ raw: CRaylib.Quaternion) {
        self.init(x: raw.x, y: raw.y, z: raw.z, w: raw.w)
    }

    var raw: CRaylib.Quaternion {
        CRaylib.Quaternion(x: x, y: y, z: z, w: w)
    }

    /// The components as a vector, for code that treats them as plain numbers.
    public var vector: Vector4 {
        Vector4(x, y, z, w)
    }

    /// No rotation.
    public static let identity = Quaternion(QuaternionIdentity())

    /// A rotation of `radians` around `axis`.
    public init(axis: Vector3, radians: Float) {
        self.init(QuaternionFromAxisAngle(axis.raw, radians))
    }

    /// A rotation from Euler angles in radians (pitch around x, yaw around y, roll around z).
    public init(pitch: Float, yaw: Float, roll: Float) {
        self.init(QuaternionFromEuler(pitch, yaw, roll))
    }

    /// The rotation as a matrix.
    public var matrix: Matrix {
        Matrix(QuaternionToMatrix(raw))
    }

    /// The inverse rotation.
    public var inverted: Quaternion {
        Quaternion(QuaternionInvert(raw))
    }

    /// Spherical interpolation toward `other`.
    public func slerp(to other: Quaternion, amount: Float) -> Quaternion {
        Quaternion(QuaternionSlerp(raw, other.raw, amount))
    }

    /// Combines two rotations, applying `lhs` first and then `rhs`, the same order as ``Matrix``'s
    /// `*`, so `(a * b).matrix` equals `a.matrix * b.matrix`.
    ///
    /// raylib's `QuaternionMultiply(q1, q2)` is the Hamilton product, which applies `q2` first;
    /// `a * b` here is `QuaternionMultiply(b, a)`.
    public static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(QuaternionMultiply(rhs.raw, lhs.raw))
    }
}

extension Vector3 {
    /// The vector rotated by a quaternion.
    public func rotated(by rotation: Quaternion) -> Vector3 {
        Vector3(Vector3RotateByQuaternion(raw, rotation.raw))
    }
}
