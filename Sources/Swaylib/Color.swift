import CRaylib

/// An RGBA color with 8 bits per channel. Same layout as raylib's `Color`.
///
/// raylib's named colors are available as static members, such as ``rayWhite`` and ``lightGray``.
public struct Color: Hashable, Sendable {
    /// The red channel, 0 to 255.
    public var red: UInt8
    /// The green channel, 0 to 255.
    public var green: UInt8
    /// The blue channel, 0 to 255.
    public var blue: UInt8
    /// The alpha channel, 0 (transparent) to 255 (opaque).
    public var alpha: UInt8

    /// Creates a color from its channels.
    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Creates a color from a hex value in `0xRRGGBBAA` form.
    public init(hex: UInt32) {
        self.init(GetColor(hex))
    }

    /// Creates a color from hue (0 to 360), saturation (0 to 1) and value (0 to 1).
    public init(hue: Float, saturation: Float, value: Float) {
        self.init(ColorFromHSV(hue, saturation, value))
    }

    /// Creates a color from channels in the 0 to 1 range.
    public init(normalized: Vector4) {
        self.init(ColorFromNormalized(normalized.raw))
    }

    init(_ raw: CRaylib.Color) {
        self.init(red: raw.r, green: raw.g, blue: raw.b, alpha: raw.a)
    }

    var raw: CRaylib.Color {
        CRaylib.Color(r: red, g: green, b: blue, a: alpha)
    }

    /// The color as a hex value in `0xRRGGBBAA` form.
    public var hex: UInt32 {
        UInt32(bitPattern: ColorToInt(raw))
    }

    /// The channels in the 0 to 1 range.
    public var normalized: Vector4 {
        Vector4(ColorNormalize(raw))
    }

    /// Hue (0 to 360), saturation (0 to 1) and value (0 to 1).
    public var hsv: Vector3 {
        Vector3(ColorToHSV(raw))
    }

    /// The same color with its alpha set to `alpha` in the 0 to 1 range.
    public func withAlpha(_ alpha: Float) -> Color {
        Color(ColorAlpha(raw, alpha))
    }

    /// The color multiplied by `tint`.
    public func tinted(_ tint: Color) -> Color {
        Color(ColorTint(raw, tint.raw))
    }

    /// The color brightened (`factor` 0 to 1) or darkened (`factor` -1 to 0).
    public func brightness(_ factor: Float) -> Color {
        Color(ColorBrightness(raw, factor))
    }

    /// The color with its contrast changed (`contrast` -1 to 1).
    public func contrast(_ contrast: Float) -> Color {
        Color(ColorContrast(raw, contrast))
    }

    /// Linear interpolation toward `other`; `amount` 0 gives self, 1 gives `other`.
    public func lerp(to other: Color, amount: Float) -> Color {
        Color(ColorLerp(raw, other.raw, amount))
    }

    /// `source` alpha-blended onto this color, with `source` multiplied by `tint` first.
    public func blended(with source: Color, tint: Color = .white) -> Color {
        Color(ColorAlphaBlend(raw, source.raw, tint.raw))
    }
}
