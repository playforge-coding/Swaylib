# Getting Started

Add Swaylib to a package, open a window, draw something and read input.

## Add the package

In `Package.swift`, depend on Swaylib and add it to an executable target:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyGame",
    dependencies: [
        .package(url: "https://github.com/playforge-coding/Swaylib.git", branch: "main"),
    ],
    targets: [
        .executableTarget(name: "MyGame", dependencies: ["Swaylib"]),
    ]
)
```

raylib is compiled from source as part of the build (SwiftPM fetches it as a git submodule of
Swaylib). On Linux that needs the X11 development headers and OpenGL headers; see <doc:Platforms>
for the package names.

## Open a window and draw

Put this in `Sources/MyGame/main.swift`. Top-level code in `main.swift` runs on the main actor,
which is where Swaylib wants to be called from.

```swift
import Swaylib

var window = try Window(width: 800, height: 450, title: "My game")
window.targetFPS = 60

var position = Vector2(400, 225)

while !window.shouldClose {
    if Keyboard.isDown(.right) { position.x += 200 * Time.frame }
    if Keyboard.isDown(.left) { position.x -= 200 * Time.frame }

    drawing {
        Draw.clearBackground(.rayWhite)
        Draw.circle(center: position, radius: 30, color: .maroon)
        Draw.text("Move with the arrow keys", x: 10, y: 10, color: .darkGray)
    }
}
```

`swift run` builds raylib the first time, which takes a little while, and opens the window.

Everything drawn inside ``drawing(_:)`` appears when the block ends. The window closes when
``Window/shouldClose`` turns true, which happens on the close button or the escape key (change that
with ``Keyboard/exitKey``), and when `window` itself goes out of scope.

## Load a texture

Resources are loaded with throwing initializers and unload themselves:

```swift
let texture = try Texture(path: "assets/player.png")

drawing {
    Draw.clearBackground(.rayWhite)
    texture.draw(at: Vector2(100, 100))
}
```

Paths are relative to the working directory, like raylib. ``Image`` is the CPU-side version: load
or generate one, edit it, then make a ``Texture`` from it with ``Texture/init(image:)``.

## Run without a display

Set `SWAYLIB_FRAMES=60 SWAYLIB_SCREENSHOT=out.png` in the environment and any Swaylib program
draws 60 frames, saves the last one to `out.png` and exits. The examples in the repository use
this on CI; it is handy for checking your own program too.
