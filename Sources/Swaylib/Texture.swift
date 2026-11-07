import CRaylib

/// An image uploaded to the GPU. Unloaded when it goes out of scope.
@MainActor
public struct Texture: ~Copyable {
    var raw: CRaylib.Texture2D

    init(raw: CRaylib.Texture2D) {
        self.raw = raw
    }

    /// Loads an image file straight into a texture.
    public init(path: String) throws(SwaylibError) {
        let raw = LoadTexture(path)
        guard IsTextureValid(raw) else { throw .loadFailed(.texture, source: path) }
        self.raw = raw
    }

    /// Uploads an image.
    public init(image: borrowing Image) throws(SwaylibError) {
        let raw = LoadTextureFromImage(image.raw)
        guard IsTextureValid(raw) else { throw .loadFailed(.texture, source: "image \(image.width)x\(image.height)") }
        self.raw = raw
    }

    deinit {
        UnloadTexture(raw)
    }

    /// The OpenGL texture id.
    public var id: UInt32 {
        raw.id
    }

    /// The width in pixels.
    public var width: Int {
        Int(raw.width)
    }

    /// The height in pixels.
    public var height: Int {
        Int(raw.height)
    }

    /// The width and height in pixels.
    public var size: Vector2 {
        Vector2(Float(raw.width), Float(raw.height))
    }

    /// The whole texture as a rectangle at the origin, for use as a source rectangle.
    public var bounds: Rectangle {
        Rectangle(x: 0, y: 0, width: Float(raw.width), height: Float(raw.height))
    }

    /// The number of mipmap levels.
    public var mipmaps: Int {
        Int(raw.mipmaps)
    }

    /// The pixel format.
    public var format: PixelFormat {
        PixelFormat(rawValue: raw.format) ?? .uncompressedR8G8B8A8
    }

    /// How the texture is sampled when scaled.
    public func setFilter(_ filter: TextureFilter) {
        SetTextureFilter(raw, filter.rawValue)
    }

    /// What is sampled outside the 0 to 1 texture coordinates.
    public func setWrap(_ wrap: TextureWrap) {
        SetTextureWrap(raw, wrap.rawValue)
    }

    /// Generates mipmaps on the GPU.
    public mutating func generateMipmaps() {
        GenTextureMipmaps(&raw)
    }

    /// Replaces the pixels of an RGBA texture with new colors, row by row from the top left.
    ///
    /// Textures loaded from files may have another format (a JPEG loads as RGB); make those from an
    /// ``Image`` converted with ``Image/convert(to:)`` first.
    ///
    /// - Precondition: ``format`` is ``PixelFormat/uncompressedR8G8B8A8`` and `pixels.count` is
    ///   `width * height`.
    public func update(pixels: [Color]) {
        precondition(format == .uncompressedR8G8B8A8, "update(pixels:) needs an RGBA texture")
        precondition(pixels.count == width * height, "pixels must cover the whole texture")
        pixels.withUnsafeBytes { UpdateTexture(raw, $0.baseAddress) }
    }

    /// Reads the pixels back from the GPU.
    public func image() -> Image {
        Image(raw: LoadImageFromTexture(raw))
    }

    /// Draws the texture with its top left at a position.
    public func draw(at position: Vector2, tint: Color = .white) {
        DrawTextureV(raw, position.raw, tint.raw)
    }

    /// Draws the texture rotated by degrees around its top left and scaled.
    public func draw(at position: Vector2, rotation: Float, scale: Float, tint: Color = .white) {
        DrawTextureEx(raw, position.raw, rotation, scale, tint.raw)
    }

    /// Draws a region of the texture with its top left at a position.
    public func draw(region: Rectangle, at position: Vector2, tint: Color = .white) {
        DrawTextureRec(raw, region.raw, position.raw, tint.raw)
    }

    /// Draws a region of the texture scaled into `destination`, rotated by degrees around `origin`,
    /// which is relative to the destination's top left.
    public func draw(
        region: Rectangle, to destination: Rectangle, origin: Vector2 = .zero, rotation: Float = 0,
        tint: Color = .white
    ) {
        DrawTexturePro(raw, region.raw, destination.raw, origin.raw, rotation, tint.raw)
    }
}

/// A texture you can draw into with ``textureMode(_:_:)``, for off-screen rendering.
///
/// OpenGL framebuffers are stored upside down. The `draw` methods here flip the texture so it
/// appears the right way up; ``image()`` does the same.
@MainActor
public struct RenderTexture: ~Copyable {
    var raw: CRaylib.RenderTexture2D

    /// Creates a framebuffer with a color texture and a depth buffer of the given size.
    public init(width: Int, height: Int) throws(SwaylibError) {
        let raw = LoadRenderTexture(Int32(width), Int32(height))
        guard IsRenderTextureValid(raw) else { throw .loadFailed(.renderTexture, source: "\(width)x\(height)") }
        self.raw = raw
    }

    deinit {
        UnloadRenderTexture(raw)
    }

    /// The OpenGL framebuffer id.
    public var id: UInt32 {
        raw.id
    }

    /// The width in pixels.
    public var width: Int {
        Int(raw.texture.width)
    }

    /// The height in pixels.
    public var height: Int {
        Int(raw.texture.height)
    }

    /// The width and height in pixels.
    public var size: Vector2 {
        Vector2(Float(raw.texture.width), Float(raw.texture.height))
    }

    /// The whole texture as a rectangle, already flipped for use as a source rectangle.
    public var flippedBounds: Rectangle {
        Rectangle(x: 0, y: 0, width: Float(raw.texture.width), height: -Float(raw.texture.height))
    }

    /// How the color texture is sampled when scaled.
    public func setFilter(_ filter: TextureFilter) {
        SetTextureFilter(raw.texture, filter.rawValue)
    }

    /// Reads the pixels back from the GPU, the right way up.
    public func image() -> Image {
        var image = Image(raw: LoadImageFromTexture(raw.texture))
        image.flipVertically()
        return image
    }

    /// Draws the color texture with its top left at a position.
    public func draw(at position: Vector2, tint: Color = .white) {
        DrawTextureRec(raw.texture, flippedBounds.raw, position.raw, tint.raw)
    }

    /// Draws the color texture scaled into `destination`.
    public func draw(to destination: Rectangle, origin: Vector2 = .zero, rotation: Float = 0, tint: Color = .white) {
        DrawTexturePro(raw.texture, flippedBounds.raw, destination.raw, origin.raw, rotation, tint.raw)
    }
}
