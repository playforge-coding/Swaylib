# Swaylib

Idiomatic Swift bindings for [raylib](https://www.raylib.com), for Linux, Windows and macOS.

raylib is compiled into your program by Swift Package Manager, along with its windowing layer
(GLFW on Linux and Windows, RGFW on macOS), so raylib itself needs no install. You need a Swift
toolchain, plus the X11 and OpenGL headers on Linux, or the MSVC build tools and Windows SDK on
Windows. Rendering uses the system's OpenGL by default. On Linux and Windows the `ANGLE` package
trait switches to OpenGL ES through [ANGLE](https://chromium.googlesource.com/angle/angle); macOS
does not support it yet.

```swift
import Swaylib

var window = try Window(width: 800, height: 450, title: "Hello")
window.targetFPS = 60

while !window.shouldClose {
    drawing {
        Draw.clearBackground(.rayWhite)
        Draw.circle(center: Mouse.position, radius: 30, color: .maroon)
        Draw.text("Hello from Swift", x: 190, y: 200, color: .lightGray)
    }
}
```

Resources unload themselves when they go out of scope, loading throws instead of handing back
something to check, `Begin`/`End` pairs are closures, and everything that touches the window runs on
the main actor. The names follow raylib's, so its cheatsheet still applies.

## Use it

```swift
dependencies: [
    .package(url: "https://github.com/swift-gamedev/Swaylib.git", branch: "main"),
],
```

Needs Swift 6.2 or newer, and on macOS `platforms: [.macOS(.v15)]` in your package. On Debian or
Ubuntu, first:

```
sudo apt install libx11-dev libxrandr-dev libxi-dev libxcursor-dev libxinerama-dev libgl1-mesa-dev
```

On Windows, install the Visual Studio components that the
[Swift installation instructions](https://www.swift.org/install/windows/) list.

## Try the examples

raylib is a git submodule, so clone with `--recurse-submodules` (SwiftPM does that for you when
Swaylib is a dependency). Then:

```
swift run BasicWindow
swift run BouncingBall
swift run RenderTextures
swift run Camera3D
```

Set `SWAYLIB_FRAMES=60 SWAYLIB_SCREENSHOT=out.png` to have any of them draw 60 frames, save a
screenshot and exit.

## Documentation

Read it at [swift-gamedev.github.io/Swaylib](https://swift-gamedev.github.io/Swaylib/), published
from `main` on every push. The DocC catalog in `Sources/Swaylib/Swaylib.docc/` has a getting
started guide, the backend and platform notes, the architecture, a roadmap, and a generated page
listing which of raylib's functions are wrapped (260 of 619 so far). Build it locally with
`swift package generate-documentation --target Swaylib`.

## Status

An MVP. The core of raylib is wrapped and tested on Linux; Windows and macOS build on CI but have
not been checked by a person yet. ANGLE compiles but Swaylib does not ship its binaries. See the
roadmap in the docs.

## License

zlib, like raylib. See `LICENSE`. raylib's own license is in its submodule under
`Sources/CRaylib/raylib/`, and miniaudio's (public domain or MIT No Attribution) under
`Sources/CRaylib/miniaudio/`.
