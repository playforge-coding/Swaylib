import CRaylib

/// A font rasterized into a glyph atlas on the GPU. Unloaded when it goes out of scope.
@MainActor
public struct Font: ~Copyable {
    var raw: CRaylib.Font
    private let owned: Bool
    private let context = GraphicsContext.generation

    /// raylib's built-in font, which needs no file. raylib owns it, so this never unloads it.
    public static var `default`: Font {
        Font(raw: GetFontDefault(), owned: false)
    }

    private init(raw: CRaylib.Font, owned: Bool) {
        self.raw = raw
        self.owned = owned
    }

    /// Loads a font file (TTF, OTF, BDF, an image font, or a raylib `.fnt` sprite font) at its
    /// default size.
    ///
    /// - Throws: ``SwaylibError/loadFailed(_:source:)`` if the file cannot be read or its format is
    ///   not supported. (raylib itself returns its default font then.)
    public init(path: String) throws(SwaylibError) {
        let raw = LoadFont(path)
        guard Self.isLoaded(raw) else { throw .loadFailed(.font, source: path) }
        self.init(raw: raw, owned: true)
    }

    /// Loads a TTF or OTF font rasterized at `size` pixels, with the given characters or the
    /// default ASCII set.
    ///
    /// - Throws: ``SwaylibError/loadFailed(_:source:)`` if the file cannot be read or its format is
    ///   not supported.
    public init(path: String, size: Int, codepoints: [Unicode.Scalar]? = nil) throws(SwaylibError) {
        var values = (codepoints ?? []).map { Int32($0.value) }
        let raw = values.withUnsafeMutableBufferPointer {
            LoadFontEx(path, Int32(size), $0.count == 0 ? nil : $0.baseAddress, Int32($0.count))
        }
        guard Self.isLoaded(raw) else { throw .loadFailed(.font, source: path) }
        self.init(raw: raw, owned: true)
    }

    /// raylib falls back to its default font when loading fails. That one is not ours to unload.
    private static func isLoaded(_ raw: CRaylib.Font) -> Bool {
        IsFontValid(raw) && raw.texture.id != GetFontDefault().texture.id
    }

    deinit {
        guard owned else { return }
        if GraphicsContext.isCurrent(context) {
            flushPendingDraws()
            UnloadFont(raw)
        } else {
            // The atlas texture went with its window's context; only the CPU side is left.
            UnloadFontData(raw.glyphs, raw.glyphCount)
            MemFree(raw.recs)
        }
    }

    /// The size the glyphs were rasterized at, in pixels.
    public var baseSize: Int {
        Int(raw.baseSize)
    }

    /// The number of glyphs in the atlas.
    public var glyphCount: Int {
        Int(raw.glyphCount)
    }

    /// How the atlas is sampled when text is scaled. Bilinear makes scaled text smoother.
    public func setFilter(_ filter: TextureFilter) {
        SetTextureFilter(raw.texture, filter.rawValue)
    }

    /// The width and height `text` would take at a font size, with `spacing` extra pixels between
    /// characters.
    public func measure(_ text: String, fontSize: Float, spacing: Float = 1) -> Vector2 {
        Vector2(MeasureTextEx(raw, text, fontSize, spacing))
    }
}
