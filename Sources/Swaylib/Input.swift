import CRaylib

/// Keyboard state for the current frame. raylib updates it at the end of each ``drawing(_:)`` block.
@MainActor
public enum Keyboard {
    /// The key that makes ``Window/shouldClose`` turn true. raylib's default is ``KeyboardKey/escape``;
    /// ``KeyboardKey/null`` disables it. Opening a ``Window`` applies the current value.
    public static var exitKey: KeyboardKey {
        get { storedExitKey }
        set {
            storedExitKey = newValue
            SetExitKey(newValue.rawValue)
        }
    }

    static var storedExitKey: KeyboardKey = .escape

    /// Whether the key went down this frame.
    public static func isPressed(_ key: KeyboardKey) -> Bool {
        IsKeyPressed(key.rawValue)
    }

    /// Whether the key went down this frame, or is being held and repeated.
    public static func isPressedRepeat(_ key: KeyboardKey) -> Bool {
        IsKeyPressedRepeat(key.rawValue)
    }

    /// Whether the key is down.
    public static func isDown(_ key: KeyboardKey) -> Bool {
        IsKeyDown(key.rawValue)
    }

    /// Whether the key went up this frame.
    public static func isReleased(_ key: KeyboardKey) -> Bool {
        IsKeyReleased(key.rawValue)
    }

    /// Whether the key is up.
    public static func isUp(_ key: KeyboardKey) -> Bool {
        IsKeyUp(key.rawValue)
    }

    /// The next key pressed this frame, or nil when the queue is empty. Call repeatedly to drain it.
    /// Key codes raylib has no name for (some layout-specific keys) are skipped.
    public static func nextPressedKey() -> KeyboardKey? {
        while true {
            let key = GetKeyPressed()
            guard key != 0 else { return nil }
            if let known = KeyboardKey(rawValue: key) {
                return known
            }
        }
    }

    /// The next character typed this frame, or nil when the queue is empty. Call repeatedly to drain it.
    public static func nextTypedCharacter() -> Character? {
        let codepoint = GetCharPressed()
        guard codepoint != 0, let scalar = Unicode.Scalar(UInt32(codepoint)) else { return nil }
        return Character(scalar)
    }
}

/// Mouse state for the current frame.
@MainActor
public enum Mouse {
    /// Whether the button went down this frame.
    public static func isPressed(_ button: MouseButton) -> Bool {
        IsMouseButtonPressed(button.rawValue)
    }

    /// Whether the button is down.
    public static func isDown(_ button: MouseButton) -> Bool {
        IsMouseButtonDown(button.rawValue)
    }

    /// Whether the button went up this frame.
    public static func isReleased(_ button: MouseButton) -> Bool {
        IsMouseButtonReleased(button.rawValue)
    }

    /// Whether the button is up.
    public static func isUp(_ button: MouseButton) -> Bool {
        IsMouseButtonUp(button.rawValue)
    }

    /// The pointer position in screen pixels. Setting it moves the pointer.
    public static var position: Vector2 {
        get { Vector2(GetMousePosition()) }
        set { SetMousePosition(Int32(newValue.x), Int32(newValue.y)) }
    }

    /// How far the pointer moved this frame.
    public static var delta: Vector2 {
        Vector2(GetMouseDelta())
    }

    /// The scroll wheel movement this frame, the larger of the two axes.
    public static var wheelMove: Float {
        GetMouseWheelMove()
    }

    /// The scroll wheel movement this frame on both axes.
    public static var wheelMoveV: Vector2 {
        Vector2(GetMouseWheelMoveV())
    }

    /// An offset added to the reported position.
    public static func setOffset(_ offset: Vector2) {
        SetMouseOffset(Int32(offset.x), Int32(offset.y))
    }

    /// A scale applied to the reported position.
    public static func setScale(_ scale: Vector2) {
        SetMouseScale(scale.x, scale.y)
    }

    /// The pointer shape. Opening a ``Window`` applies the current value.
    public static var cursor: MouseCursor {
        get { storedCursor }
        set {
            storedCursor = newValue
            SetMouseCursor(newValue.rawValue)
        }
    }

    static var storedCursor: MouseCursor = .default

    /// Whether the pointer is hidden.
    public static var isCursorHidden: Bool {
        IsCursorHidden()
    }

    /// Whether the pointer is over the window.
    public static var isCursorOnScreen: Bool {
        IsCursorOnScreen()
    }

    /// Shows the pointer.
    public static func showCursor() {
        ShowCursor()
    }

    /// Hides the pointer.
    public static func hideCursor() {
        HideCursor()
    }

    /// Unlocks the pointer after ``disableCursor()``.
    public static func enableCursor() {
        EnableCursor()
    }

    /// Hides the pointer and locks it to the window, for first person style control.
    public static func disableCursor() {
        DisableCursor()
    }
}

/// One gamepad slot, whether or not a controller is plugged into it.
@MainActor
public struct Gamepad: Hashable, Sendable {
    /// The slot, starting at 0.
    public let index: Int

    /// Refers to a gamepad slot.
    public init(_ index: Int) {
        self.index = index
    }

    /// Whether a controller is connected in this slot.
    public var isAvailable: Bool {
        IsGamepadAvailable(Int32(index))
    }

    /// The controller's name.
    public var name: String {
        guard let name = GetGamepadName(Int32(index)) else { return "" }
        return String(cString: name)
    }

    /// Whether the button went down this frame.
    public func isPressed(_ button: GamepadButton) -> Bool {
        IsGamepadButtonPressed(Int32(index), button.rawValue)
    }

    /// Whether the button is down.
    public func isDown(_ button: GamepadButton) -> Bool {
        IsGamepadButtonDown(Int32(index), button.rawValue)
    }

    /// Whether the button went up this frame.
    public func isReleased(_ button: GamepadButton) -> Bool {
        IsGamepadButtonReleased(Int32(index), button.rawValue)
    }

    /// The position of an axis, -1 to 1.
    public func axis(_ axis: GamepadAxis) -> Float {
        GetGamepadAxisMovement(Int32(index), axis.rawValue)
    }

    /// The number of axes the controller has.
    public var axisCount: Int {
        Int(GetGamepadAxisCount(Int32(index)))
    }

    /// Runs the rumble motors for a duration in seconds.
    public func vibrate(leftMotor: Float, rightMotor: Float, duration: Float) {
        SetGamepadVibration(Int32(index), leftMotor, rightMotor, duration)
    }
}

/// Touch points, on platforms that have them.
@MainActor
public enum Touch {
    /// How many fingers are touching.
    public static var count: Int {
        Int(GetTouchPointCount())
    }

    /// The position of a touch point in screen pixels.
    public static func position(_ index: Int) -> Vector2 {
        Vector2(GetTouchPosition(Int32(index)))
    }
}

/// raylib's gesture recognizer, which also works from the mouse.
@MainActor
public enum Gestures {
    /// Which gestures to detect.
    public static func setEnabled(_ gestures: Gesture) {
        SetGesturesEnabled(gestures.rawValue)
    }

    /// Whether a gesture happened this frame.
    public static func isDetected(_ gesture: Gesture) -> Bool {
        IsGestureDetected(gesture.rawValue)
    }

    /// The gesture detected this frame, if any.
    public static var detected: Gesture {
        Gesture(rawValue: UInt32(GetGestureDetected()))
    }
}
