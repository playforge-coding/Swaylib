import CRaylib

/// An image uploaded to the GPU. Unloaded when it goes out of scope.
@MainActor
public struct Texture: ~Copyable {
    var raw: CRaylib.Texture2D
    let context = GraphicsContext.generation

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
        guard GraphicsContext.isCurrent(context) else { return }
        flushPendingDraws()
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

    /// The pixel format, or nil for a format value raylib defines but ``PixelFormat`` does not know.
    public var format: PixelFormat? {
        PixelFormat(rawValue: raw.format)
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
        precondition(
            raw.format == PixelFormat.uncompressedR8G8B8A8.rawValue, "update(pixels:) needs an RGBA texture")
        precondition(pixels.count == width * height, "pixels must cover the whole texture")
        // Draws of the old pixels that raylib has not submitted yet would otherwise show the new ones.
        flushPendingDraws()
        pixels.withUnsafeBytes { UpdateTexture(raw, $0.baseAddress) }
    }

    /// Reads the pixels back from the GPU, including anything drawn into it this frame.
    public func image() -> Image {
        Image(raw: readPixels(raw))
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

/// Submits raylib's pending draw batch. raylib batches draws and only sends them to the GPU later
/// (at the end of a frame or a mode), still referring to textures by id. A texture that goes out of
/// scope inside ``drawing(_:)`` has to wait for its draws before it is deleted, or the frame shows
/// the wrong texture or none. Not actor isolated because `deinit` is not; like the unload calls it
/// sits next to, it runs wherever the owning resource is released, which is the main actor.
func flushPendingDraws() {
    if IsWindowReady() {
        rlDrawRenderBatchActive()
    }
}

/// Reads a texture's pixels after submitting the pending draws, so the image has them. On OpenGL ES
/// raylib reads through a temporary framebuffer and then binds the screen's, so the render texture
/// of an open ``textureMode(_:_:)`` is bound again afterwards.
@MainActor
func readPixels(_ texture: CRaylib.Texture2D) -> CRaylib.Image {
    flushPendingDraws()
    let image = LoadImageFromTexture(texture)
    if let target = DrawingState.targets.last {
        rlEnableFramebuffer(target.id)
    }
    return image
}

/// Which window's OpenGL context is current. Every ``Window`` creates a new context, and closing it
/// deletes the GPU objects made in it. A resource that outlives its window must not unload them
/// again: there is no context then, or a later window's context, where the same ids may name other
/// objects. Not actor isolated because `deinit` is not; it only runs on the main actor, where the
/// resources live.
enum GraphicsContext {
    /// Increased by every window that opens; 0 before the first.
    nonisolated(unsafe) static var generation = 0

    /// Whether a resource created under `generation` belongs to the open window's context.
    static func isCurrent(_ generation: Int) -> Bool {
        IsWindowReady() && generation == self.generation
    }
}

/// A texture you can draw into with ``textureMode(_:_:)``, for off-screen rendering.
///
/// OpenGL framebuffers are stored upside down. The `draw` methods here flip the texture so it
/// appears the right way up; ``image()`` does the same.
@MainActor
public struct RenderTexture: ~Copyable {
    var raw: CRaylib.RenderTexture2D
    let context = GraphicsContext.generation

    /// Creates a framebuffer with a color texture and a depth buffer of the given size.
    public init(width: Int, height: Int) throws(SwaylibError) {
        let raw = LoadRenderTexture(Int32(width), Int32(height))
        guard IsRenderTextureValid(raw) else { throw .loadFailed(.renderTexture, source: "\(width)x\(height)") }
        self.raw = raw
    }

    deinit {
        guard GraphicsContext.isCurrent(context) else { return }
        flushPendingDraws()
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

    /// Reads the pixels back from the GPU, the right way up, including anything drawn into it this
    /// frame. Inside ``textureMode(_:_:)`` drawing carries on into the same target afterwards.
    public func image() -> Image {
        var image = Image(raw: readPixels(raw.texture))
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
