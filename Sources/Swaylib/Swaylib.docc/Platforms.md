# Platforms

What each operating system needs, and what is known to work.

## Overview

Swaylib builds raylib from source with Swift Package Manager on every platform, with GLFW compiled
in. No CMake, no system raylib and no system GLFW. The library code has no platform conditions in
its public API; your program should not need any either.

## Linux

Needs the X11 and OpenGL development headers to build. On Debian and Ubuntu:

```
sudo apt install libx11-dev libxrandr-dev libxi-dev libxcursor-dev libxinerama-dev libgl1-mesa-dev
```

The `ANGLE` trait also needs `libgles-dev`. At run time GLFW loads the X11 extension libraries, `libGL` and ALSA (for audio) dynamically, so
only the usual desktop packages are needed. Wayland sessions work through XWayland. A native
Wayland backend is on the <doc:Roadmap>; it needs protocol headers generated with
`wayland-scanner`, which the SwiftPM build cannot run yet.

Tested: Ubuntu 24.04 with Swift 6.4, on Mesa with Intel graphics and under Xvfb on CI.

## Windows

Needs the Swift toolchain for Windows, which brings the MSVC build tools it depends on. raylib
links `opengl32`, `gdi32`, `winmm`, `user32` and `shell32`, all part of Windows.

CI builds Swaylib on Windows and runs the tests that do not need a window. The window tests are
skipped there because the GitHub runners have no OpenGL 3.3 driver; set `SWAYLIB_WINDOW_TESTS=1`
to run them on a machine that has one. Treat Windows as building but not yet verified by a person.

## macOS

Needs macOS 15 or newer (for the standard library's `Mutex`) and the Swift toolchain, either
from Xcode or from swift.org. On macOS raylib
uses its RGFW platform rather than GLFW: GLFW's Cocoa code is Objective-C without ARC, SwiftPM
compiles Objective-C with ARC and cannot be told otherwise, and RGFW's macOS backend is plain C
over the Objective-C runtime. raylib links the AppKit, IOKit, CoreVideo, QuartzCore, OpenGL and
CoreAudio frameworks.

RGFW moves the working directory next to the executable (or into the bundle's resources) while
the window opens, like raylib's own macOS builds do. Load assets after creating the ``Window`` with
paths relative to the executable, or use absolute paths. Swaylib resolves `SWAYLIB_SCREENSHOT`
against the original working directory for you.

Apple's OpenGL is deprecated but still present, and that is what the default backend uses. ANGLE on
Metal is the intended default for macOS once Swaylib can ship ANGLE binaries; see <doc:Backends>.

## Running unattended

On any platform, `SWAYLIB_FRAMES=<n>` makes ``Window/shouldClose`` turn true after `n` frames and
`SWAYLIB_SCREENSHOT=<file.png>` saves the last one. That is how the examples are checked on CI.
