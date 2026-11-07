import CRaylib

/// A 2D vector or point. Same layout as raylib's `Vector2`.
public struct Vector2: Hashable, Sendable {
    /// The x component.
    public var x: Float
    /// The y component.
    public var y: Float

    /// Creates a vector from its components.
    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    /// Creates a vector from its components, unlabeled.
    public init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }

    /// (0, 0).
    public static let zero = Vector2(0, 0)
    /// (1, 1).
    public static let one = Vector2(1, 1)

    init(_ raw: CRaylib.Vector2) {
        self.init(raw.x, raw.y)
    }

    var raw: CRaylib.Vector2 {
        CRaylib.Vector2(x: x, y: y)
    }

    /// The length (magnitude).
    public var length: Float {
        (x * x + y * y).squareRoot()
    }

    /// The length squared, which avoids the square root when only comparing lengths.
    public var lengthSquared: Float {
        x * x + y * y
    }

    /// The vector scaled to length 1, or zero if it has no length.
    public var normalized: Vector2 {
        Vector2(Vector2Normalize(raw))
    }

    /// The dot product.
    public func dot(_ other: Vector2) -> Float {
        x * other.x + y * other.y
    }

    /// The 2D cross product (the z component of the 3D cross product).
    public func cross(_ other: Vector2) -> Float {
        x * other.y - y * other.x
    }

    /// The distance to another point.
    public func distance(to other: Vector2) -> Float {
        (other - self).length
    }

    /// The angle in radians from this vector to another.
    public func angle(to other: Vector2) -> Float {
        Vector2Angle(raw, other.raw)
    }

    /// Linear interpolation toward `other`; `amount` 0 gives self, 1 gives `other`.
    public func lerp(to other: Vector2, amount: Float) -> Vector2 {
        Vector2(Vector2Lerp(raw, other.raw, amount))
    }

    /// The vector rotated by an angle in radians.
    public func rotated(by radians: Float) -> Vector2 {
        Vector2(Vector2Rotate(raw, radians))
    }

    /// The vector reflected off a surface with the given normal.
    public func reflected(normal: Vector2) -> Vector2 {
        Vector2(Vector2Reflect(raw, normal.raw))
    }

    /// Moves toward `target` by at most `maxDistance`.
    public func moved(toward target: Vector2, maxDistance: Float) -> Vector2 {
        Vector2(Vector2MoveTowards(raw, target.raw, maxDistance))
    }

    /// Each component clamped to the matching component of `min` and `max`.
    public func clamped(min: Vector2, max: Vector2) -> Vector2 {
        Vector2(Vector2Clamp(raw, min.raw, max.raw))
    }

    /// The vector transformed by a matrix.
    public func transformed(by matrix: Matrix) -> Vector2 {
        Vector2(Vector2Transform(raw, matrix.raw))
    }

    /// Component-wise sum.
    public static func + (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    /// Component-wise difference.
    public static func - (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    /// Component-wise product.
    public static func * (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x * rhs.x, lhs.y * rhs.y)
    }

    /// Component-wise quotient.
    public static func / (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x / rhs.x, lhs.y / rhs.y)
    }

    /// Scales by a scalar.
    public static func * (lhs: Vector2, rhs: Float) -> Vector2 {
        Vector2(lhs.x * rhs, lhs.y * rhs)
    }

    /// Scales by a scalar.
    public static func * (lhs: Float, rhs: Vector2) -> Vector2 {
        Vector2(lhs * rhs.x, lhs * rhs.y)
    }

    /// Divides by a scalar.
    public static func / (lhs: Vector2, rhs: Float) -> Vector2 {
        Vector2(lhs.x / rhs, lhs.y / rhs)
    }

    /// Negation.
    public static prefix func - (vector: Vector2) -> Vector2 {
        Vector2(-vector.x, -vector.y)
    }

    /// Adds in place.
    public static func += (lhs: inout Vector2, rhs: Vector2) {
        lhs = lhs + rhs
    }

    /// Subtracts in place.
    public static func -= (lhs: inout Vector2, rhs: Vector2) {
        lhs = lhs - rhs
    }

    /// Scales in place.
    public static func *= (lhs: inout Vector2, rhs: Float) {
        lhs = lhs * rhs
    }

    /// Divides in place.
    public static func /= (lhs: inout Vector2, rhs: Float) {
        lhs = lhs / rhs
    }
}
