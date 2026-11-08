# Backends

How Swaylib talks to the GPU, and how to pick between native OpenGL and ANGLE.

## Overview

raylib renders through its own OpenGL layer, `rlgl`, which is compiled for one OpenGL flavor.
Swaylib exposes that choice as Swift Package Manager traits on the package, so a program picks a
backend in its `Package.swift` rather than in code. The Swift API is the same on every backend.

## Native OpenGL (the default)

With no trait enabled, raylib is built for desktop OpenGL 3.3 and uses the OpenGL driver the
operating system provides. This is the right choice on Linux and Windows, and it works on macOS as
long as Apple keeps shipping its deprecated OpenGL implementation.

## ANGLE

[ANGLE](https://chromium.googlesource.com/angle/angle) translates OpenGL ES to Vulkan, Direct3D 11
and Metal. With the `ANGLE` trait, raylib is built for OpenGL ES 3 and GLFW creates its context
through EGL instead of the platform's native OpenGL API:

```swift
.package(url: "https://github.com/swift-gamedev/Swaylib.git", branch: "main", traits: ["ANGLE"]),
```

Two libraries are involved. GLFW loads `libEGL` at run time to create the context. raylib's
`rlgl` calls the `gl*` functions directly on this path, so `libGLESv2` is linked: at build time
the linker needs a `GLESv2` library (`libgles-dev` on Debian and Ubuntu, or ANGLE's own
`libGLESv2` on Windows and macOS), and at run time the program loads whichever `libGLESv2` it
finds first, which is how you point it at ANGLE: next to the executable on Windows, on the library
path on Linux, or in the app bundle on macOS. Which ANGLE backend is used (Vulkan, D3D11, Metal)
is up to the ANGLE build you ship and its defaults.

CI builds the trait on Linux against Mesa's GLES library. Swaylib does not yet fetch ANGLE
binaries for you, and choosing the ANGLE platform from Swift is still on the <doc:Roadmap>. Until
then, treat it as experimental.

### Shaders

Shader source differs between the two: desktop OpenGL 3.3 takes GLSL 330 and ANGLE takes GLSL ES
300. A program that ships custom shaders needs both versions. The `ANGLE` trait is visible to Swift
code as a compilation condition, so the choice can be made where the shader is loaded:

```swift
#if ANGLE
let shader = try Shader(vertexPath: nil, fragmentPath: "shaders/glsl300es/blur.fs")
#else
let shader = try Shader(vertexPath: nil, fragmentPath: "shaders/glsl330/blur.fs")
#endif
```

## Why not a system raylib

Swaylib always compiles raylib from its submodule and has no option to link one that is already
installed. The backend is chosen when raylib is compiled, so a prebuilt library would fix it, and
the generated enums and wrappers follow one exact raylib release, which is rarely the one a
distribution or Homebrew ships.

## Zink

[Zink](https://docs.mesa3d.org/drivers/zink.html) is Mesa's OpenGL implementation on top of
Vulkan. It needs no changes in Swaylib: the native OpenGL build runs on Zink when Mesa is told to
use it, for example with `MESA_LOADER_DRIVER_OVERRIDE=zink` on Linux. Packaging Mesa so that this
works everywhere is a later goal and the lowest priority of the three backends.
