import CRaylib
import CRaylibShims

/// The application window and its OpenGL context. raylib has exactly one, so create one `Window`
/// and keep it alive for as long as you draw; it closes when it goes out of scope.
///
/// Two environment variables make any program checkable without a person watching:
/// `SWAYLIB_FRAMES=<n>` makes ``shouldClose`` turn true after `n` frames drawn with ``drawing(_:)``,
/// and `SWAYLIB_SCREENSHOT=<file.png>` saves the last of those frames.
@MainActor
public struct Window: ~Copyable {
    /// The title, shown in the title bar.
    public var title: String {
        didSet { SetWindowTitle(title) }
    }

    /// The frame rate raylib waits for at the end of each ``drawing(_:)`` block; 0 means no limit.
    /// Every new window starts at 0, even if an earlier one set a limit.
    public var targetFPS: Int = 0 {
        didSet { SetTargetFPS(Int32(targetFPS)) }
    }

    /// Opens the window and creates its OpenGL context.
    ///
    /// - Parameters:
    ///   - width: The width in screen pixels.
    ///   - height: The height in screen pixels.
    ///   - title: The window title.
    ///   - flags: raylib config flags applied before the window opens, such as
    ///     ``ConfigFlags/windowResizable`` or ``ConfigFlags/vsyncHint``. raylib keeps them for the
    ///     rest of the process, so a later window inherits the flags of an earlier one; use
    ///     ``clearState(_:)`` after opening to turn one off.
    /// - Throws: ``SwaylibError/windowAlreadyOpen`` if another `Window` is still open, without
    ///   touching it, or ``SwaylibError/windowFailed`` if the window or context could not be
    ///   created.
    public init(width: Int, height: Int, title: String, flags: ConfigFlags = []) throws(SwaylibError) {
        guard !IsWindowReady() else { throw .windowAlreadyOpen }
        if !flags.isEmpty {
            SetConfigFlags(flags.rawValue)
        }
        // raylib on macOS moves the working directory next to the executable while opening the
        // window, so unattended-run paths from the environment are resolved before that.
        Headless.configure(workingDirectory: String(cString: GetWorkingDirectory()))
        InitWindow(Int32(width), Int32(height), title)
        guard IsWindowReady() else { throw .windowFailed }
        swaylibPlatformWindowOpened()
        self.title = title
        // raylib keeps the frame target across CloseWindow and InitWindow; match the property.
        SetTargetFPS(0)
        // raylib resets these when it opens a window; keep what the program chose.
        SetExitKey(Keyboard.storedExitKey.rawValue)
        SetMouseCursor(Mouse.storedCursor.rawValue)
    }

    deinit {
        swaylibPlatformWindowClosing()
        CloseWindow()
        swaylibPlatformWindowClosed()
    }

    /// Whether the user asked to close the window (close button or the exit key), or the
    /// `SWAYLIB_FRAMES` budget ran out. The main loop runs while this is false.
    public var shouldClose: Bool {
        WindowShouldClose() || Headless.budgetExhausted
    }

    /// The width in screen pixels.
    public var width: Int {
        Int(GetScreenWidth())
    }

    /// The height in screen pixels.
    public var height: Int {
        Int(GetScreenHeight())
    }

    /// The width and height in screen pixels.
    public var size: Vector2 {
        Vector2(Float(GetScreenWidth()), Float(GetScreenHeight()))
    }

    /// The size of the framebuffer, which differs from ``size`` on high DPI displays.
    public var renderSize: Vector2 {
        Vector2(Float(GetRenderWidth()), Float(GetRenderHeight()))
    }

    /// The whole window as a rectangle at the origin.
    public var bounds: Rectangle {
        Rectangle(origin: .zero, size: size)
    }

    /// The position on the desktop.
    public var position: Vector2 {
        get { Vector2(GetWindowPosition()) }
        set { SetWindowPosition(Int32(newValue.x), Int32(newValue.y)) }
    }

    /// The DPI scale factor of the monitor the window is on.
    public var scaleDPI: Vector2 {
        Vector2(GetWindowScaleDPI())
    }

    /// Whether the window is fullscreen.
    public var isFullscreen: Bool {
        IsWindowFullscreen()
    }

    /// Whether the window is hidden.
    public var isHidden: Bool {
        IsWindowHidden()
    }

    /// Whether the window is minimized.
    public var isMinimized: Bool {
        IsWindowMinimized()
    }

    /// Whether the window is maximized.
    public var isMaximized: Bool {
        IsWindowMaximized()
    }

    /// Whether the window has input focus.
    public var isFocused: Bool {
        IsWindowFocused()
    }

    /// Whether the window was resized during the last frame.
    public var wasResized: Bool {
        IsWindowResized()
    }

    /// Whether a config flag is currently set.
    public func hasState(_ flag: ConfigFlags) -> Bool {
        IsWindowState(flag.rawValue)
    }

    /// Sets config flags on the open window, such as ``ConfigFlags/windowResizable``.
    public func setState(_ flags: ConfigFlags) {
        SetWindowState(flags.rawValue)
    }

    /// Clears config flags on the open window.
    public func clearState(_ flags: ConfigFlags) {
        ClearWindowState(flags.rawValue)
    }

    /// Resizes the window.
    public func resize(width: Int, height: Int) {
        SetWindowSize(Int32(width), Int32(height))
    }

    /// Sets the smallest size the user can resize the window to.
    public func setMinimumSize(width: Int, height: Int) {
        SetWindowMinSize(Int32(width), Int32(height))
    }

    /// Sets the largest size the user can resize the window to.
    public func setMaximumSize(width: Int, height: Int) {
        SetWindowMaxSize(Int32(width), Int32(height))
    }

    /// Sets the window opacity, 0 to 1.
    public func setOpacity(_ opacity: Float) {
        SetWindowOpacity(opacity)
    }

    /// Sets the window icon from an RGBA image.
    public func setIcon(_ image: borrowing Image) {
        SetWindowIcon(image.raw)
    }

    /// Switches between fullscreen and windowed.
    public func toggleFullscreen() {
        ToggleFullscreen()
    }

    /// Switches between borderless windowed and windowed.
    public func toggleBorderlessWindowed() {
        ToggleBorderlessWindowed()
    }

    /// Maximizes the window, if it is resizable.
    public func maximize() {
        MaximizeWindow()
    }

    /// Minimizes the window, if it is resizable.
    public func minimize() {
        MinimizeWindow()
    }

    /// Restores the window from minimized or maximized.
    public func restore() {
        RestoreWindow()
    }

    /// Brings the window to the front and gives it focus.
    public func focus() {
        SetWindowFocused()
    }

    /// Saves what is on screen to a PNG file.
    public func takeScreenshot(to path: String) {
        TakeScreenshot(path)
    }

    /// The system clipboard as text.
    public var clipboard: String {
        get {
            guard let text = GetClipboardText() else { return "" }
            return String(cString: text)
        }
        nonmutating set { SetClipboardText(newValue) }
    }

    /// The number of monitors.
    public static var monitorCount: Int {
        Int(GetMonitorCount())
    }

    /// The monitor the window is on.
    public var currentMonitor: Int {
        Int(GetCurrentMonitor())
    }

    /// Moves the window to a monitor.
    public func setMonitor(_ monitor: Int) {
        SetWindowMonitor(Int32(monitor))
    }

    /// The size of a monitor in pixels.
    public static func monitorSize(_ monitor: Int) -> Vector2 {
        Vector2(Float(GetMonitorWidth(Int32(monitor))), Float(GetMonitorHeight(Int32(monitor))))
    }

    /// The refresh rate of a monitor in Hz.
    public static func monitorRefreshRate(_ monitor: Int) -> Int {
        Int(GetMonitorRefreshRate(Int32(monitor)))
    }

    /// The name of a monitor.
    public static func monitorName(_ monitor: Int) -> String {
        guard let name = GetMonitorName(Int32(monitor)) else { return "" }
        return String(cString: name)
    }
}

/// Frame timing. All of it is read from raylib, which measures the frames ``drawing(_:)`` draws.
@MainActor
public enum Time {
    /// The seconds the last frame took.
    public static var frame: Float {
        GetFrameTime()
    }

    /// The seconds since the window opened.
    public static var elapsed: Double {
        GetTime()
    }

    /// The current frames per second.
    public static var fps: Int {
        Int(GetFPS())
    }

    /// Sleeps for a number of seconds.
    public static func wait(seconds: Double) {
        WaitTime(seconds)
    }
}

/// raylib's random number generator, seeded from the clock when the window opens.
@MainActor
public enum Random {
    /// Seeds the generator.
    public static func seed(_ seed: UInt32) {
        SetRandomSeed(seed)
    }

    /// A random integer in the range, inclusive.
    public static func value(in range: ClosedRange<Int>) -> Int {
        Int(GetRandomValue(Int32(range.lowerBound), Int32(range.upperBound)))
    }
}

/// Frame budget and screenshot from the environment, for running programs unattended.
@MainActor
enum Headless {
    static var frameBudget: Int?
    static var screenshotPath: String?
    static var framesDrawn = 0

    static func configure(workingDirectory: String) {
        frameBudget = Platform.environment("SWAYLIB_FRAMES").flatMap { Int($0) }
        screenshotPath = Platform.environment("SWAYLIB_SCREENSHOT").map { path in
            isAbsolute(path) ? path : workingDirectory + "/" + path
        }
        framesDrawn = 0
    }

    /// `/x` on every platform; `C:\x`, `C:/x` and `\\server\x` on Windows.
    static func isAbsolute(_ path: String) -> Bool {
        if path.hasPrefix("/") || path.hasPrefix("\\") {
            return true
        }
        let characters = Array(path.utf8)
        return characters.count > 2 && characters[1] == UInt8(ascii: ":")
            && (characters[2] == UInt8(ascii: "/") || characters[2] == UInt8(ascii: "\\"))
    }

    static var budgetExhausted: Bool {
        guard let frameBudget else { return false }
        return framesDrawn >= frameBudget
    }

    /// Called at the end of each frame, before `EndDrawing` swaps buffers: after the swap the back
    /// buffer no longer reliably holds the frame. The pending draw batch is flushed first so the
    /// screenshot has everything in it.
    static func frameEnding() {
        framesDrawn += 1
        if framesDrawn == frameBudget, let screenshotPath {
            rlDrawRenderBatchActive()
            TakeScreenshot(screenshotPath)
        }
    }
}
