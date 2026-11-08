import CRaylib

/// An axis-aligned rectangle with its origin at the top left. Same layout as raylib's `Rectangle`.
public struct Rectangle: Hashable, Sendable {
    /// The left edge.
    public var x: Float
    /// The top edge.
    public var y: Float
    /// The width.
    public var width: Float
    /// The height.
    public var height: Float

    /// Creates a rectangle from its edges and size.
    public init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Creates a rectangle from its top left corner and size.
    public init(origin: Vector2, size: Vector2) {
        self.init(x: origin.x, y: origin.y, width: size.x, height: size.y)
    }

    init(_ raw: CRaylib.Rectangle) {
        self.init(x: raw.x, y: raw.y, width: raw.width, height: raw.height)
    }

    var raw: CRaylib.Rectangle {
        CRaylib.Rectangle(x: x, y: y, width: width, height: height)
    }

    /// The top left corner.
    public var origin: Vector2 {
        get { Vector2(x, y) }
        set {
            x = newValue.x
            y = newValue.y
        }
    }

    /// The width and height.
    public var size: Vector2 {
        get { Vector2(width, height) }
        set {
            width = newValue.x
            height = newValue.y
        }
    }

    /// The center point.
    public var center: Vector2 {
        Vector2(x + width / 2, y + height / 2)
    }

    /// Whether the point is inside.
    public func contains(_ point: Vector2) -> Bool {
        CheckCollisionPointRec(point.raw, raw)
    }

    /// Whether the two rectangles overlap.
    public func intersects(_ other: Rectangle) -> Bool {
        CheckCollisionRecs(raw, other.raw)
    }

    /// Whether the rectangle overlaps a circle.
    public func intersects(circleAt center: Vector2, radius: Float) -> Bool {
        CheckCollisionCircleRec(center.raw, radius, raw)
    }

    /// The overlapping area, or nil if the rectangles do not overlap.
    public func intersection(with other: Rectangle) -> Rectangle? {
        guard intersects(other) else { return nil }
        return Rectangle(GetCollisionRec(raw, other.raw))
    }
}
