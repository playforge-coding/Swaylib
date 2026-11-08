import CRaylib

/// Pixels in CPU memory. Load one from a file or generate it, edit it, then make a ``Texture`` from it.
///
/// Owns its pixel data and frees it when it goes out of scope; use ``copy()`` to get a second one.
@MainActor
public struct Image: ~Copyable {
    var raw: CRaylib.Image

    init(raw: CRaylib.Image) {
        self.raw = raw
    }

    /// Loads an image file (PNG, BMP, TGA, JPG, GIF, QOI, PSD, DDS, HDR, KTX, ASTC, PKM, PVR).
    public init(path: String) throws(SwaylibError) {
        let raw = LoadImage(path)
        guard IsImageValid(raw) else { throw .loadFailed(.image, source: path) }
        self.raw = raw
    }

    /// Decodes an image from the bytes of a file. `fileType` is the extension, such as `".png"`.
    public init(fileType: String, data: [UInt8]) throws(SwaylibError) {
        let raw = data.withUnsafeBufferPointer { LoadImageFromMemory(fileType, $0.baseAddress, Int32($0.count)) }
        guard IsImageValid(raw) else { throw .loadFailed(.image, source: "\(data.count) bytes of \(fileType)") }
        self.raw = raw
    }

    /// Generates an image filled with one color.
    public init(width: Int, height: Int, color: Color) {
        raw = GenImageColor(Int32(width), Int32(height), color.raw)
    }

    /// Generates a linear gradient; `direction` is in degrees, 0 being top to bottom.
    public init(width: Int, height: Int, gradientFrom start: Color, to end: Color, direction: Int = 0) {
        raw = GenImageGradientLinear(Int32(width), Int32(height), Int32(direction), start.raw, end.raw)
    }

    /// Generates a checkerboard of `checksX` by `checksY` pixel squares.
    ///
    /// - Precondition: `checksX` and `checksY` are greater than zero; raylib divides by them.
    public init(width: Int, height: Int, checksX: Int, checksY: Int, _ first: Color, _ second: Color) {
        precondition(checksX > 0 && checksY > 0, "checker sizes must be greater than zero")
        raw = GenImageChecked(Int32(width), Int32(height), Int32(checksX), Int32(checksY), first.raw, second.raw)
    }

    /// Renders text with the default font into a new image.
    public init(text: String, fontSize: Int, color: Color) {
        raw = ImageText(text, Int32(fontSize), color.raw)
    }

    deinit {
        UnloadImage(raw)
    }

    /// The width in pixels.
    public var width: Int {
        Int(raw.width)
    }

    /// The height in pixels.
    public var height: Int {
        Int(raw.height)
    }

    /// The pixel format, or nil for a format value raylib defines but ``PixelFormat`` does not know.
    public var format: PixelFormat? {
        PixelFormat(rawValue: raw.format)
    }

    /// The number of mipmap levels, 1 for none.
    public var mipmaps: Int {
        Int(raw.mipmaps)
    }

    /// The whole image as a rectangle at the origin.
    public var bounds: Rectangle {
        Rectangle(x: 0, y: 0, width: Float(raw.width), height: Float(raw.height))
    }

    /// A deep copy.
    public func copy() -> Image {
        Image(raw: ImageCopy(raw))
    }

    /// A copy of a region.
    public func cropped(to area: Rectangle) -> Image {
        Image(raw: ImageFromImage(raw, area.raw))
    }

    /// The color of one pixel.
    public func color(atX x: Int, y: Int) -> Color {
        Color(GetImageColor(raw, Int32(x), Int32(y)))
    }

    /// Every pixel as RGBA, row by row from the top left.
    public var colors: [Color] {
        guard let pointer = LoadImageColors(raw) else { return [] }
        defer { UnloadImageColors(pointer) }
        let count = width * height
        return UnsafeBufferPointer(start: pointer, count: count).map(Color.init)
    }

    /// Writes the image to a file; the extension picks the format (PNG, BMP, TGA, JPG, QOI, HDR, KTX).
    public func export(to path: String) throws(SwaylibError) {
        guard ExportImage(raw, path) else { throw .exportFailed(path: path) }
    }

    /// Converts the pixels to another format.
    public mutating func convert(to format: PixelFormat) {
        ImageFormat(&raw, format.rawValue)
    }

    /// Scales with bicubic filtering.
    public mutating func resize(width: Int, height: Int) {
        ImageResize(&raw, Int32(width), Int32(height))
    }

    /// Scales with nearest neighbor filtering, which keeps pixel art crisp.
    public mutating func resizeNearestNeighbor(width: Int, height: Int) {
        ImageResizeNN(&raw, Int32(width), Int32(height))
    }

    /// Cuts the image down to a region.
    public mutating func crop(to area: Rectangle) {
        ImageCrop(&raw, area.raw)
    }

    /// Mirrors top to bottom.
    public mutating func flipVertically() {
        ImageFlipVertical(&raw)
    }

    /// Mirrors left to right.
    public mutating func flipHorizontally() {
        ImageFlipHorizontal(&raw)
    }

    /// Rotates by degrees, -359 to 359.
    public mutating func rotate(degrees: Int) {
        ImageRotate(&raw, Int32(degrees))
    }

    /// Multiplies every pixel by a color.
    public mutating func tint(_ color: Color) {
        ImageColorTint(&raw, color.raw)
    }

    /// Inverts the colors.
    public mutating func invert() {
        ImageColorInvert(&raw)
    }

    /// Converts to grayscale.
    public mutating func grayscale() {
        ImageColorGrayscale(&raw)
    }

    /// Uses another image's brightness as this image's alpha.
    public mutating func applyAlphaMask(_ mask: borrowing Image) {
        ImageAlphaMask(&raw, mask.raw)
    }

    /// Fills the whole image with a color.
    public mutating func clear(_ color: Color) {
        ImageClearBackground(&raw, color.raw)
    }

    /// Sets one pixel.
    public mutating func drawPixel(at position: Vector2, color: Color) {
        ImageDrawPixelV(&raw, position.raw, color.raw)
    }

    /// Draws a line with a thickness.
    public mutating func drawLine(from start: Vector2, to end: Vector2, thickness: Int = 1, color: Color) {
        ImageDrawLineEx(&raw, start.raw, end.raw, Int32(thickness), color.raw)
    }

    /// Draws a filled circle.
    public mutating func drawCircle(center: Vector2, radius: Int, color: Color) {
        ImageDrawCircleV(&raw, center.raw, Int32(radius), color.raw)
    }

    /// Draws a filled rectangle.
    public mutating func drawRectangle(_ rectangle: Rectangle, color: Color) {
        ImageDrawRectangleRec(&raw, rectangle.raw, color.raw)
    }

    /// Draws a rectangle outline.
    public mutating func drawRectangleLines(_ rectangle: Rectangle, thickness: Int = 1, color: Color) {
        ImageDrawRectangleLinesEx(&raw, rectangle.raw, Int32(thickness), color.raw)
    }

    /// Draws a region of another image, scaled into `destination`, rotated by degrees around
    /// `origin` and multiplied by `tint`.
    public mutating func draw(
        _ source: borrowing Image, from area: Rectangle, to destination: Rectangle, origin: Vector2 = .zero,
        rotation: Float = 0, tint: Color = .white
    ) {
        ImageDrawImagePro(&raw, source.raw, area.raw, destination.raw, origin.raw, rotation, tint.raw)
    }

    /// Draws text with the default font.
    public mutating func drawText(_ text: String, x: Int, y: Int, fontSize: Int, color: Color) {
        ImageDrawText(&raw, text, Int32(x), Int32(y), Int32(fontSize), color.raw)
    }
}
