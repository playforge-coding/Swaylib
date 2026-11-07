# Architecture

How the package is put together, from raylib's C source up to the Swift API.

## Overview

The package has three layers, each a SwiftPM target, plus the generator that writes the mechanical
parts of the top one.

## CRaylib

raylib's `src/` directory, vendored unmodified at a tagged release under `Sources/CRaylib/raylib/`
with the release recorded in `Sources/CRaylib/VERSION`. SwiftPM never compiles that directory
directly. Instead, wrapper files at the top of the target (`rcore.c`, `rshapes.c`, and so on) each
include one raylib module, and `rglfw.c` includes GLFW on Linux and Windows. On macOS raylib uses
its RGFW platform instead, which is plain C: GLFW's Cocoa code is Objective-C without ARC, and
SwiftPM compiles Objective-C with ARC on with no way to turn it off.

Compile settings in `Package.swift` select raylib's GLFW desktop platform on Linux and Windows and
RGFW on macOS, X11 on Linux, and OpenGL ES 3 when the `ANGLE` trait is on. The umbrella header `include/CRaylib.h` exposes
`raylib.h`, `raymath.h` and `rlgl.h` to Swift as one module.

Updating raylib means replacing the vendored directory with the new release's `src/`, updating
`VERSION` and `Tools/Generate/raylib_api.json`, regenerating, and fixing whatever changed.

## CRaylibShims

A few C functions for things Swift cannot call: raylib's log callback takes a `va_list`, so the
shim formats the message and hands Swift a plain string, and `TraceLog` is variadic, so the shim
logs one preformatted line.

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

`swift run swaylib-generate` reads `Tools/Generate/raylib_api.json`, the parser output raylib ships,
and writes the generated Swift plus the <doc:APICoverage> page from `Tools/Generate/wrapped.txt`,
the list of raylib functions that have a Swift counterpart. With `--check` it only reports whether
the committed files are up to date, which CI uses.
