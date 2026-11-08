import Foundation
import Swaylib
import Synchronization
import Testing

// These open a hidden window, so they need a display: X11 on Linux (DISPLAY set), always on
// macOS, and opt in with SWAYLIB_WINDOW_TESTS=1 elsewhere. SWAYLIB_WINDOW_TESTS=0 skips them.
private func hasDisplay() -> Bool {
    if let override = ProcessInfo.processInfo.environment["SWAYLIB_WINDOW_TESTS"] {
        return override == "1"
    }
    #if os(Linux)
    return ProcessInfo.processInfo.environment["DISPLAY"] != nil
    #elseif os(macOS)
    return true
    #else
    return false
    #endif
}

// #expect cannot expand member accesses on noncopyable values (Window, Image, Texture), so the
// tests read those into locals first.
@Suite("Window", .serialized, .enabled(if: hasDisplay()))
@MainActor
struct WindowTests {
    static let scratch: URL = {
        let name = "SwaylibTests-\(ProcessInfo.processInfo.processIdentifier)"
        let url = FileManager.default.temporaryDirectory.appending(path: name)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    init() {
        Log.setLevel(.warning)
    }

    private func openWindow() throws -> Window {
        try Window(width: 320, height: 240, title: "test", flags: [.windowHidden])
    }

    @Test("Opens hidden with the requested size")
    func open() throws {
        var window = try openWindow()
        let (width, height, size) = (window.width, window.height, window.size)
        #expect(width == 320)
        #expect(height == 240)
        #expect(size == Vector2(320, 240))
        let (hidden, shouldClose) = (window.isHidden, window.shouldClose)
        #expect(hidden)
        #expect(!shouldClose)
        window.title = "renamed"
        window.targetFPS = 30
        let (title, targetFPS) = (window.title, window.targetFPS)
        #expect(title == "renamed")
        #expect(targetFPS == 30)
    }

    @Test("A second window is refused while one is open")
    func secondWindow() throws {
        let window = try openWindow()
        _ = window
        #expect(throws: SwaylibError.windowAlreadyOpen) {
            _ = try openWindow()
        }
        // The first window is untouched.
        let width = window.width
        #expect(width == 320)
    }

    @Test("The cursor can be set before a window exists")
    func cursorBeforeWindow() throws {
        Mouse.cursor = .pointingHand
        defer { Mouse.cursor = .default }
        let window = try openWindow()
        _ = window
        #expect(Mouse.cursor == .pointingHand)
    }

    @Test("Draws shapes into a render texture and reads them back")
    func renderTexture() throws {
        let window = try openWindow()
        _ = window
        let target = try RenderTexture(width: 64, height: 64)
        let targetSize = target.size
        #expect(targetSize == Vector2(64, 64))

        textureMode(target) {
            Draw.clearBackground(.red)
            Draw.rectangle(Rectangle(x: 0, y: 32, width: 64, height: 32), color: .blue)
            Draw.circle(center: Vector2(16, 16), radius: 8, color: .green)
        }
        drawing {
            Draw.clearBackground(.black)
            target.draw(at: .zero)
        }

        let image = target.image()
        let (width, height) = (image.width, image.height)
        #expect(width == 64)
        #expect(height == 64)
        let pixels = [
            image.color(atX: 60, y: 4), image.color(atX: 16, y: 16), image.color(atX: 32, y: 48),
            image.color(atX: 32, y: 16),
        ]
        #expect(pixels == [.red, .green, .blue, .red])

        // Drawing the render texture is the presentation path: it must come out the right way
        // up too, so draw it into a second one and check that.
        let presented = try RenderTexture(width: 64, height: 64)
        textureMode(presented) {
            Draw.clearBackground(.black)
            target.draw(at: .zero)
        }
        let shown = presented.image()
        let shownPixels = [shown.color(atX: 16, y: 16), shown.color(atX: 32, y: 48)]
        #expect(shownPixels == [.green, .blue])
    }

    @Test("Nested texture modes return to the outer target")
    func nestedTextureMode() throws {
        let window = try openWindow()
        _ = window
        let outer = try RenderTexture(width: 32, height: 32)
        let inner = try RenderTexture(width: 32, height: 32)
        textureMode(outer) {
            Draw.clearBackground(.red)
            textureMode(inner) {
                Draw.clearBackground(.blue)
            }
            Draw.rectangle(Rectangle(x: 0, y: 0, width: 16, height: 32), color: .green)
        }
        let outerImage = outer.image()
        let innerImage = inner.image()
        let pixels = [outerImage.color(atX: 4, y: 4), outerImage.color(atX: 28, y: 4), innerImage.color(atX: 28, y: 4)]
        #expect(pixels == [.green, .red, .blue])
    }

    @Test("A texture dropped mid-frame still draws")
    func textureDroppedMidFrame() throws {
        let window = try openWindow()
        _ = window
        let target = try RenderTexture(width: 16, height: 16)
        textureMode(target) {
            Draw.clearBackground(.black)
            // The texture goes out of scope before the batch holding its draw is submitted.
            if let texture = try? Texture(image: Image(width: 16, height: 16, color: .lime)) {
                texture.draw(at: .zero)
            }
        }
        let pixel = target.image().color(atX: 8, y: 8)
        #expect(pixel == .lime)
    }

    @Test("A shader file that cannot be read is a load failure")
    func missingShaderFile() throws {
        let window = try openWindow()
        _ = window
        #expect(throws: SwaylibError.loadFailed(.shader, source: "/nonexistent.fs")) {
            _ = try Shader(vertexPath: nil, fragmentPath: "/nonexistent.fs")
        }
        // Asking for no stages at all is raylib's default shader, and fine.
        let defaultShader = try Shader(vertexCode: nil, fragmentCode: nil)
        _ = defaultShader
    }

    @Test("Text draws something")
    func text() throws {
        let window = try openWindow()
        _ = window
        let target = try RenderTexture(width: 128, height: 32)
        textureMode(target) {
            Draw.clearBackground(.white)
            Draw.text("Hello", x: 2, y: 2, fontSize: 20, color: .black)
        }
        let image = target.image()
        let darkPixels = image.colors.filter { $0.red < 128 }.count
        #expect(darkPixels > 20)
        let measured = Font.default.measure("Hello", fontSize: 20)
        #expect(measured.x > 20)
    }

    @Test("Round trips an image through a texture and a file")
    func textureRoundTrip() throws {
        let window = try openWindow()
        _ = window
        var image = Image(width: 8, height: 8, color: .magenta)
        image.drawPixel(at: Vector2(3, 5), color: .lime)
        let texture = try Texture(image: image)
        let textureWidth = texture.width
        #expect(textureWidth == 8)
        let readBack = texture.image()
        let (marked, background) = (readBack.color(atX: 3, y: 5), readBack.color(atX: 0, y: 0))
        #expect(marked == .lime)
        #expect(background == .magenta)

        let path = Self.scratch.appending(path: "round-trip.png").path()
        try readBack.export(to: path)
        let loaded = try Image(path: path)
        let loadedPixel = loaded.color(atX: 3, y: 5)
        #expect(loadedPixel == .lime)
        #expect(throws: SwaylibError.loadFailed(.image, source: "/nonexistent.png")) {
            _ = try Image(path: "/nonexistent.png")
        }
    }

    @Test("Image editing")
    func imageEditing() throws {
        let window = try openWindow()
        _ = window
        var image = Image(width: 4, height: 2, color: .white)
        image.drawPixel(at: Vector2(0, 0), color: .black)
        image.flipHorizontally()
        let flipped = image.color(atX: 3, y: 0)
        #expect(flipped == .black)
        image.resizeNearestNeighbor(width: 8, height: 4)
        let (width, scaled) = (image.width, image.color(atX: 7, y: 1))
        #expect(width == 8)
        #expect(scaled == .black)
        let copy = image.copy()
        image.clear(.red)
        let (copyPixel, clearedPixel, count) = (copy.color(atX: 7, y: 1), image.color(atX: 7, y: 1), image.colors.count)
        #expect(copyPixel == .black)
        #expect(clearedPixel == .red)
        #expect(count == 32)
    }

    @Test("Keyboard and mouse state is readable")
    func input() throws {
        let window = try openWindow()
        _ = window
        drawing { Draw.clearBackground(.white) }
        #expect(!Keyboard.isDown(.space))
        #expect(Keyboard.nextPressedKey() == nil)
        #expect(!Mouse.isDown(.left))
        #expect(!Gamepad(0).isAvailable || !Gamepad(0).name.isEmpty)
        Keyboard.exitKey = .null
        #expect(Keyboard.exitKey == .null)
        Keyboard.exitKey = .escape
    }

    @Test("Log handler receives raylib's messages")
    func log() throws {
        let messages = Messages()
        Log.setHandler { level, message in messages.append(level, message) }
        defer { Log.setHandler(nil) }
        Log.log(.warning, "hello from the test")
        #expect(messages.lines.contains { $0.level == .warning && $0.message == "hello from the test" })
        // Longer than the shim's stack buffer, which used to truncate it.
        let long = String(repeating: "abcdefghij", count: 300)
        Log.log(.warning, long)
        #expect(messages.lines.contains { $0.message == long })
        #expect(throws: SwaylibError.loadFailed(.texture, source: "/nonexistent.png")) {
            let window = try openWindow()
            _ = window
            _ = try Texture(path: "/nonexistent.png")
        }
        #expect(messages.lines.contains { $0.message.contains("nonexistent.png") })
    }
}

private final class Messages: Sendable {
    private let storage = Mutex<[(level: TraceLogLevel, message: String)]>([])

    var lines: [(level: TraceLogLevel, message: String)] {
        storage.withLock { $0 }
    }

    func append(_ level: TraceLogLevel, _ message: String) {
        storage.withLock { $0.append((level, message)) }
    }
}
