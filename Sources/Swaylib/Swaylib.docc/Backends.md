# Backends

How Swaylib talks to the GPU, and how to pick between native OpenGL, ANGLE and Metal.

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
`rlgl` calls the `gl*` functions directly on this path, so `libGLESv2` is linked into the
program. Pointing it at ANGLE works like this:

- On Windows, link against ANGLE's `libGLESv2` and put its `libEGL.dll` and `libGLESv2.dll` next
  to the executable.
- On Linux, link against ANGLE too, with `-Xlinker -L<dir>` where `<dir>` holds ANGLE's
  `libEGL.so` and `libGLESv2.so`. The program records the name of the library it was linked
  against, and ANGLE's is `libGLESv2.so`. Linked against `libgles-dev` instead, it records
  `libGLESv2.so.2`, which ANGLE does not provide, so it keeps using the system's GL functions even
  with ANGLE on the library path, and they do not work with ANGLE's context. Then the dynamic
  loader has to find ANGLE at run time: link with a runpath (`-Xlinker -rpath -Xlinker <dir>`, or
  `'$ORIGIN'` for the executable's own directory) or set `LD_LIBRARY_PATH`. Next to the executable
  is not enough without a runpath:

  ```
  swift build --traits ANGLE -Xlinker -L<dir> -Xlinker -rpath -Xlinker <dir>
  ```

  Under the trait GLFW asks for `libEGL.so` and `libGLESv2.so`, ANGLE's names, rather than Mesa's
  `libEGL.so.1`. With no ANGLE present, those names come from `libegl-dev` and `libgles-dev`,
  which is how CI runs the trait on Mesa.
- On macOS the trait is not supported yet and the build stops with an error: raylib's RGFW
  platform, which Swaylib uses there, only creates native OpenGL contexts, never EGL ones.

Which ANGLE backend is used is up to the ANGLE build and its defaults, and on Linux and Windows can
be overridden with `ANGLE_DEFAULT_PLATFORM` (`vulkan`, `gl`, `d3d11`, `swiftshader`). Its software
renderer, SwiftShader, only works with a build that includes SwiftShader's window system support
for the platform.

Prebuilt ANGLE for Linux, Windows and macOS comes from
[swift-gamedev/angle-prebuilt](https://github.com/swift-gamedev/angle-prebuilt). Each release has a
`SHA256SUMS` file to check the archives against, and its Linux SwiftShader can draw to X11
windows. Swaylib has been run on those binaries on Linux with ANGLE's OpenGL, Vulkan and
SwiftShader backends. CI runs the trait against Mesa's EGL and GLES, not ANGLE itself. Swaylib
does not yet fetch ANGLE binaries for you, and choosing the ANGLE platform from Swift is still on
the <doc:Roadmap>. Until then, treat it as experimental.

### Shaders

Shader source differs between the two: desktop OpenGL 3.3 takes GLSL 330 and ANGLE takes GLSL ES
300. A program that ships custom shaders needs both versions and picks one at run time with
``Shader/language``:

```swift
let directory = Shader.language == .glslES300 ? "glsl300es" : "glsl330"
let shader = try Shader(vertexPath: nil, fragmentPath: "shaders/\(directory)/blur.fs")
```

`#if ANGLE` does not work for this in your own package. A package trait only defines its
compilation condition inside the package that declares it, so enabling `ANGLE` on the Swaylib
dependency leaves your code compiling as if it were off. Code inside Swaylib, including its
examples and tests, can use `#if ANGLE`.

## Metal (experimental)

The `Metal` trait replaces raylib's OpenGL layer with `rlmt`, a Metal implementation of the same
functions from [raylib-backends](https://github.com/raythings/raylib-backends). It only works on
macOS; elsewhere the trait has no effect and the compiler warns about it. It has not been run on a
Mac yet, so expect it to be broken:

```
swift build --traits Metal
```

Custom shaders do not work under this trait. `rlmt` can only compile GLSL with glslang and
SPIRV-Cross, which Swaylib does not build, so loading a ``Shader`` throws. Drawing that uses
raylib's default shader is not affected.

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
