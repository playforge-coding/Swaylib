import CRaylib

/// A 3D vector or point. Same layout as raylib's `Vector3`.
public struct Vector3: Hashable, Sendable {
    /// The x component.
    public var x: Float
    /// The y component.
    public var y: Float
    /// The z component.
    public var z: Float

    /// Creates a vector from its components.
    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Creates a vector from its components, unlabeled.
    public init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// (0, 0, 0).
    public static let zero = Vector3(0, 0, 0)
    /// (1, 1, 1).
    public static let one = Vector3(1, 1, 1)
    /// (0, 1, 0), raylib's default up direction.
    public static let up = Vector3(0, 1, 0)

    init(_ raw: CRaylib.Vector3) {
        self.init(raw.x, raw.y, raw.z)
    }

    var raw: CRaylib.Vector3 {
        CRaylib.Vector3(x: x, y: y, z: z)
    }

    /// The length (magnitude).
    public var length: Float {
        (x * x + y * y + z * z).squareRoot()
    }

    /// The length squared.
    public var lengthSquared: Float {
        x * x + y * y + z * z
    }

    /// The vector scaled to length 1, or zero if it has no length.
    public var normalized: Vector3 {
        Vector3(Vector3Normalize(raw))
    }

    /// The dot product.
    public func dot(_ other: Vector3) -> Float {
        x * other.x + y * other.y + z * other.z
    }

    /// The cross product.
    public func cross(_ other: Vector3) -> Vector3 {
        Vector3(Vector3CrossProduct(raw, other.raw))
    }

    /// The distance to another point.
    public func distance(to other: Vector3) -> Float {
        (other - self).length
    }

    /// The angle in radians between this vector and another.
    public func angle(to other: Vector3) -> Float {
        Vector3Angle(raw, other.raw)
    }

    /// Linear interpolation toward `other`; `amount` 0 gives self, 1 gives `other`.
    public func lerp(to other: Vector3, amount: Float) -> Vector3 {
        Vector3(Vector3Lerp(raw, other.raw, amount))
    }

    /// The vector rotated around an axis by an angle in radians.
    public func rotated(around axis: Vector3, by radians: Float) -> Vector3 {
        Vector3(Vector3RotateByAxisAngle(raw, axis.raw, radians))
    }

    /// The vector reflected off a surface with the given normal.
    public func reflected(normal: Vector3) -> Vector3 {
        Vector3(Vector3Reflect(raw, normal.raw))
    }

    /// The vector transformed by a matrix.
    public func transformed(by matrix: Matrix) -> Vector3 {
        Vector3(Vector3Transform(raw, matrix.raw))
    }

    /// Component-wise sum.
    public static func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    /// Component-wise difference.
    public static func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    /// Component-wise product.
    public static func * (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z)
    }

    /// Scales by a scalar.
    public static func * (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    /// Scales by a scalar.
    public static func * (lhs: Float, rhs: Vector3) -> Vector3 {
        Vector3(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    }

    /// Divides by a scalar.
    public static func / (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }

    /// Negation.
    public static prefix func - (vector: Vector3) -> Vector3 {
        Vector3(-vector.x, -vector.y, -vector.z)
    }

    /// Adds in place.
    public static func += (lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs + rhs
    }

    /// Subtracts in place.
    public static func -= (lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs - rhs
    }

    /// Scales in place.
    public static func *= (lhs: inout Vector3, rhs: Float) {
        lhs = lhs * rhs
    }
}
