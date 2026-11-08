/// Everything Swaylib can throw.
public enum SwaylibError: Error, Equatable, Sendable {
    /// The kinds of resource that can fail to load.
    public enum Resource: String, Sendable {
        /// A CPU-side image.
        case image
        /// A GPU texture.
        case texture
        /// A render texture (framebuffer).
        case renderTexture
        /// A font.
        case font
        /// A shader program.
        case shader
        /// A sound loaded fully into memory.
        case sound
        /// A streamed music file.
        case music
    }

    /// The window or its OpenGL context could not be created. raylib logs the reason.
    case windowFailed
    /// A ``Window`` is already open. raylib has a single global window, so a second one would take
    /// it over and the first one's `deinit` would close it.
    case windowAlreadyOpen
    /// A resource could not be loaded from `source` (a file path, or a short description).
    case loadFailed(Resource, source: String)
    /// A file could not be written.
    case exportFailed(path: String)
    /// The audio device could not be opened.
    case audioDeviceFailed
}
