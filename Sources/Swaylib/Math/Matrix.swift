import CRaylib

/// A 4 by 4 matrix of floats, stored column major like raylib's `Matrix` so it can be bit cast.
public struct Matrix: Hashable, Sendable {
    /// Row 1, column 1.
    public var m0: Float
    /// Row 1, column 2.
    public var m4: Float
    /// Row 1, column 3.
    public var m8: Float
    /// Row 1, column 4.
    public var m12: Float
    /// Row 2, column 1.
    public var m1: Float
    /// Row 2, column 2.
    public var m5: Float
    /// Row 2, column 3.
    public var m9: Float
    /// Row 2, column 4.
    public var m13: Float
    /// Row 3, column 1.
    public var m2: Float
    /// Row 3, column 2.
    public var m6: Float
    /// Row 3, column 3.
    public var m10: Float
    /// Row 3, column 4.
    public var m14: Float
    /// Row 4, column 1.
    public var m3: Float
    /// Row 4, column 2.
    public var m7: Float
    /// Row 4, column 3.
    public var m11: Float
    /// Row 4, column 4.
    public var m15: Float

    init(_ raw: CRaylib.Matrix) {
        self = unsafeBitCast(raw, to: Matrix.self)
    }

    var raw: CRaylib.Matrix {
        unsafeBitCast(self, to: CRaylib.Matrix.self)
    }

    /// The identity matrix.
    public static let identity = Matrix(MatrixIdentity())

    /// A translation.
    public static func translation(_ offset: Vector3) -> Matrix {
        Matrix(MatrixTranslate(offset.x, offset.y, offset.z))
    }

    /// A non-uniform scale.
    public static func scale(_ factors: Vector3) -> Matrix {
        Matrix(MatrixScale(factors.x, factors.y, factors.z))
    }

    /// A rotation of `radians` around `axis`.
    public static func rotation(axis: Vector3, radians: Float) -> Matrix {
        Matrix(MatrixRotate(axis.raw, radians))
    }

    /// A rotation around the x axis.
    public static func rotationX(_ radians: Float) -> Matrix {
        Matrix(MatrixRotateX(radians))
    }

    /// A rotation around the y axis.
    public static func rotationY(_ radians: Float) -> Matrix {
        Matrix(MatrixRotateY(radians))
    }

    /// A rotation around the z axis.
    public static func rotationZ(_ radians: Float) -> Matrix {
        Matrix(MatrixRotateZ(radians))
    }

    /// A perspective projection; `fovY` is in radians.
    public static func perspective(fovY: Double, aspect: Double, near: Double, far: Double) -> Matrix {
        Matrix(MatrixPerspective(fovY, aspect, near, far))
    }

    /// An orthographic projection.
    public static func orthographic(
        left: Double, right: Double, bottom: Double, top: Double, near: Double, far: Double
    ) -> Matrix {
        Matrix(MatrixOrtho(left, right, bottom, top, near, far))
    }

    /// A view matrix looking from `eye` at `target`.
    public static func lookAt(eye: Vector3, target: Vector3, up: Vector3) -> Matrix {
        Matrix(MatrixLookAt(eye.raw, target.raw, up.raw))
    }

    /// The determinant.
    public var determinant: Float {
        MatrixDeterminant(raw)
    }

    /// The transpose.
    public var transposed: Matrix {
        Matrix(MatrixTranspose(raw))
    }

    /// The inverse.
    public var inverted: Matrix {
        Matrix(MatrixInvert(raw))
    }

    /// The product, applying `lhs` first and then `rhs`, as raylib's `MatrixMultiply` does.
    public static func * (lhs: Matrix, rhs: Matrix) -> Matrix {
        Matrix(MatrixMultiply(lhs.raw, rhs.raw))
    }
}
