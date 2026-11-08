# Architecture

How the package is put together, from raylib's C source up to the Swift API.

## Overview

The package has three layers, each a SwiftPM target, plus the generator that writes the mechanical
parts of the top one.

## CRaylib

raylib's own repository is a git submodule at a tagged release under `Sources/CRaylib/raylib/`,
so its files are never touched and the pinned commit is the version. SwiftPM never compiles the
submodule directly. Instead, wrapper files at the top of the target (`rcore.c`, `rshapes.c`, and
so on) each include one raylib module from `raylib/src/`, and `rglfw.c` includes GLFW on Linux and
Windows. On macOS raylib uses its RGFW platform instead, which is plain C. GLFW's Cocoa code is
Objective-C without ARC, and SwiftPM compiles Objective-C with ARC on. The only way to turn it off
for a target is `unsafeFlags(["-fno-objc-arc"])`, and SwiftPM refuses packages with unsafe flags
as dependencies, so Swaylib could not be used from other packages.

Compile settings in `Package.swift` select raylib's GLFW desktop platform on Linux and Windows and
RGFW on macOS, X11 on Linux, and OpenGL ES 3 when the `ANGLE` trait is on. The umbrella header
`include/CRaylib.h` exposes `raylib.h`, `raymath.h` and `rlgl.h` to Swift as one module.

A second submodule, `Sources/CRaylib/miniaudio/`, holds miniaudio 0.11.26, newer than the
0.11.25 raylib 6.2 bundles. That one cannot open a PulseAudio device whose native format it does
not handle, which is common with PipeWire. On Linux and macOS the `raudio.c` wrapper includes the
newer miniaudio before raylib's audio module, with the same settings, so the include guards skip
raylib's copy. Windows keeps raylib's copy, because raylib has to prepare `windows.h` before
miniaudio includes it, and the bug is in the PulseAudio code only.

Updating raylib means moving the submodule to the new tag, regenerating, and fixing whatever
changed. If the new release bundles miniaudio 0.11.26 or newer, also remove the miniaudio
submodule and go back to the one-line `raudio.c` wrapper. Otherwise Swaylib would keep building
the older copy.

## CRaylibShims

A few C functions for things Swift cannot call: raylib's log callback takes a `va_list`, so the
shim formats the message and hands Swift a plain string, and `TraceLog` is variadic, so the shim
logs one preformatted line. It also holds the macOS keep-alive for RGFW.

## Swaylib

The Swift API. Three kinds of type:

- Value types (``Vector2``, ``Vector3``, ``Vector4``, ``Matrix``, ``Rectangle``, ``Color``,
  ``Camera2D``) have the same memory layout as raylib's structs and convert for free. They are
  `Sendable` and not actor isolated. ``Camera3D`` converts field by field because its projection
  is a Swift enum.
- Resource types (``Image``, ``Texture``, ``RenderTexture``, ``Font``, ``Shader``, ``Sound``,
  ``Music``, ``AudioDevice``, ``Window``) are noncopyable structs that own a raylib handle and
  unload it in `deinit`. Loading is a throwing initializer that checks raylib's `Is...Valid`.
- Namespaces (``Draw``, ``Keyboard``, ``Mouse``, ``Time``, ``Log``, ``Random``) group raylib's
  free functions.

Everything that touches raylib's global state is `@MainActor`, because raylib is single threaded.
raylib's `Begin`/`End` pairs are closure-taking functions such as ``drawing(_:)`` and
``textureMode(_:_:)``, so an unmatched `End` cannot be written.

`Sources/Swaylib/Generated/` holds the enums, option sets and named colors written by the
generator. Everything else is by hand.

## The generator

`swift run swaylib-generate` reads `raylib_api.json`, the parser output raylib ships, from the
submodule (`tools/rlparser/output/`), so it always describes the raylib being built, and writes the generated Swift plus the <doc:APICoverage> page from `Tools/Generate/wrapped.txt`,
the list of raylib functions that have a Swift counterpart. With `--check` it only reports whether
the committed files are up to date, which CI uses.
