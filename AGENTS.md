# Swaylib

## Overview

Swaylib is a set of idiomatic Swift bindings for [raylib](https://github.com/raysan5/raylib). It is cross platform first: Linux, Windows and macOS are all first-class targets, and nothing may assume Apple frameworks or Darwin APIs. Swift Package Manager is the only build system. Rendering goes through raylib's own OpenGL layer (`rlgl`), either on the system's native OpenGL driver or on [ANGLE](https://chromium.googlesource.com/angle/angle), which translates OpenGL ES to Vulkan, Direct3D 11 or Metal. [Zink](https://docs.mesa3d.org/drivers/zink.html) (Mesa's OpenGL on Vulkan) is planned for later and is low priority. License: zlib, the same as raylib (`LICENSE` at the root). Vendored third-party code keeps its own license file next to it, and nothing under a stricter license (GPL, LGPL) may be added.

**Status:** nothing is built yet. This file describes the plan. When code lands and differs from what is written here, update this file in the same change.

Goals:

- Swift that reads like Swift, not like C with a Swift accent. Users should not need to know raylib's C API to use Swaylib, but someone who knows raylib should find every function where they expect it.
- Full coverage of raylib's modules (`rcore`, `rshapes`, `rtextures`, `rtext`, `rmodels`, `raudio`) plus `raymath`. `rlgl` is exposed for advanced users but stays out of the main API.
- The same Swift code builds and runs on every supported platform with no `#if os(...)` in user code.
- Choosing a graphics backend is a package configuration, not a code change.

Non-goals (for now): mobile, the web (Emscripten), and replacing raylib's C code with Swift. Swaylib wraps raylib; it does not reimplement it.

## Planned layout

- `Sources/CRaylib/`: raylib's C source, vendored at a tagged release, compiled by SwiftPM as a C target. raylib's `rglfw.c` builds GLFW in the same target, so no CMake and no system GLFW are needed. Keep raylib's files unmodified. Anything we need to change goes into a separate shim file or a `config.h` override, so updating raylib is a copy plus a diff review. Record the vendored version and commit in `Sources/CRaylib/VERSION`.
- `Sources/CRaylibShims/`: small C helpers for things Swift cannot call directly, such as raylib's `va_list` log callback and macros that do not import.
- `Sources/Swaylib/`: the Swift API. This is the module users import.
- `Sources/SwaylibMath/` (maybe folded into `Swaylib`): vectors, matrices, quaternions and `raymath` operations as Swift operators and methods.
- `Plugins/` and `Tools/`: the binding generator (see below) and any build tool plugins.
- `Examples/`: ports of raylib's examples as executable targets. Each one is also a smoke test.
- `Tests/`: Swift Testing suites, including render tests that compare against reference images.
- `Sources/Swaylib/Swaylib.docc/`: the DocC catalog with the articles and tutorials. There is no separate docs site.

Generated code is committed. The generator reads raylib's `parser/output/raylib_api.json` (shipped with raylib) and emits the mechanical parts: enums (keys, mouse buttons, gamepad axes, config flags, blend modes, pixel formats), constants and the raw function list used to check coverage. Hand-written Swift sits on top of that. CI regenerates and fails if the output differs from what is committed.

## Graphics backends

raylib picks its graphics API when it is compiled (`GRAPHICS_API_OPENGL_33`, `GRAPHICS_API_OPENGL_ES3` and so on), not at runtime. So does Swaylib. Backends are SwiftPM package traits that set the C defines on `CRaylib`:

- `OpenGL` (native desktop OpenGL 3.3): default on Linux and Windows.
- `ANGLE`: raylib built for OpenGL ES 3, with GLFW told to create an EGL context. GLFW loads `libEGL` and `libGLESv2` at runtime, so ANGLE ships as shared libraries next to the executable instead of being linked. ANGLE's own backend (Vulkan, D3D11, Metal, OpenGL) is chosen at window creation through GLFW's `GLFW_ANGLE_PLATFORM_TYPE` hint and exposed in Swift as a window option. Planned default on macOS, where Apple's OpenGL is deprecated.
- `Zink` (later): native OpenGL path pointed at a Mesa build with the Zink driver. Do not spend time on this until the other two are solid, and do not let Zink concerns shape the API.

Rules:

- The Swift API must be identical under every backend. If a feature only exists on one (for example a desktop OpenGL extension), it gets a runtime capability check, not a separate API.
- Shader code differs between GLSL 330 and GLSL ES 300. Examples and tests that use shaders ship both, picked by the active backend.
- Getting ANGLE binaries is the hard part. Prefer prebuilt, versioned ANGLE releases fetched by a script with checksums. Never require users to install depot_tools to build Swaylib.

## Platform support

- Linux: X11 and Wayland, both through GLFW. Wayland needs the protocol headers that GLFW generates with `wayland-scanner`; check how the vendored raylib version handles this before assuming it works.
- Windows: MSVC toolchain through the Swift for Windows installer. Links `opengl32`, `gdi32` and `winmm`.
- macOS: Cocoa through GLFW. Native OpenGL works but is deprecated, which is why ANGLE on Metal is the intended default there.

Platform-specific linker and define settings live in `Package.swift` with `.when(platforms:)`. Platform checks in Swift source are allowed only inside `Swaylib`, never in examples, and should be rare.

## API design rules

- raylib is single threaded and not reentrant. Every public API that touches the window, input, audio device or GPU is `@MainActor`. The package builds in the Swift 6 language mode with complete concurrency checking. Pure value types (vectors, colors, rectangles, math) are `Sendable` and not actor isolated.
- GPU and audio resources (`Texture`, `RenderTexture`, `Shader`, `Font`, `Model`, `Mesh`, `Sound`, `Music`, `Image`) own their raylib handle and unload it in `deinit`. Use noncopyable types (`~Copyable`) where shared ownership would be wrong, and a final class only when the resource really needs to be shared. Never leave unloading to the user.
- Loading functions `throw` a typed error instead of returning a struct the caller has to check with `IsTextureValid` and friends.
- Paired `Begin`/`End` calls become scoped closures: `drawing { }`, `mode2D(camera) { }`, `textureMode(target) { }`, `shaderMode(shader) { }`, `blendMode(.additive) { }`, `scissor(rect) { }`. A mismatched `End` must be impossible to write.
- C enums and flag sets become Swift enums and `OptionSet`s. Integers that mean a key or a button never appear in the public API.
- Use Swift naming: `Window.shouldClose`, `texture.draw(at:tint:)`, `Color.rayWhite`. Keep raylib's terminology (texture, render texture, mode 2D) so its docs and cheatsheet still help.
- Math types support the operators you would expect (`+`, `-`, `*`, scalar multiply, dot and cross as methods) and are layout compatible with raylib's C structs so passing them across costs nothing. Check that compatibility with tests, not comments.
- Strings go in as Swift `String`; no `UnsafePointer<CChar>` in the public API. Same for arrays and buffers: offer `Span`/`[T]` based API, keep raw pointers internal or behind clearly named `unsafe` entry points.
- Do not hide raylib behind a game engine. No entity systems, scene graphs or app frameworks in `Swaylib`. A thin optional `Game` protocol for the main loop is fine if it stays optional.

## Building and testing

These are the intended commands. Fix this section once they actually exist.

- `swift build` builds everything with the default backend. `swift build --traits ANGLE` builds the ANGLE variant.
- `swift test` runs the Swift Testing suites. Render tests draw into a `RenderTexture`, read it back and compare against reference PNGs in `Tests/.../Resources/` with a small tolerance. On CI they run under ANGLE's SwiftShader (CPU Vulkan) or Mesa's llvmpipe, so no GPU is needed. Update reference images only on purpose, and say so in the commit.
- `swift run <Example>` runs an example. Examples should accept an environment variable that renders a fixed number of frames, saves a screenshot and exits, so they can be checked without a person watching.
- CI builds and tests on Linux, Windows and macOS, with every backend that platform supports. A change that only builds on the platform you happen to be on is not done.
- When adding raylib API: regenerate if it touches generated code, write the Swift wrapper, cover it with a test or an example, and update the coverage list in the docs.

## Searching the Codebase

Use fast, modern tools instead of the slow defaults:

- [`rg`](https://github.com/BurntSushi/ripgrep) (ripgrep) for text search, not `grep`. It respects `.gitignore` for you. **NOTE**: Prefer to use [`ast-grep`](https://ast-grep.github.io) when applicable as it uses the structure of the code instead.
- [`fd`](https://github.com/sharkdp/fd) for finding files by name, not `find`.
- [`ast-grep`](https://ast-grep.github.io) for structural searches and rewrites, like finding every call to a function or every type that conforms to a protocol. It supports both Swift and C. Call it as `ast-grep`. The `sg` alias is deprecated, so don't use it.
- `jq` for reading and querying JSON, including `raylib_api.json`.

If your harness has dedicated search or file tools that already wrap these, those are fine too.

## Code Quality

Always lint and format:

- `swift format` (ships with the toolchain) formats and lints. Config lives in `.swift-format` at the root. `swift format --in-place --recursive Sources Tests Examples` fixes, `swift format lint --strict --recursive Sources Tests Examples` reports. CI runs the lint.
- `.editorconfig`: UTF-8, LF, 4 spaces, 120 columns for Swift; 2 spaces for Markdown, TOML, YAML and JSON.
- Do not format or lint the vendored raylib source.

Use modern code practices:

- The latest stable Swift 6 release, Swift 6 language mode, complete strict concurrency. Pin the toolchain in `.swift-version` (read by swiftly).
- Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest.
- Typed throws, noncopyable types, `Span` and package traits are all fair game. Use them where they make the API better, not to show off.
- Use Foundation sparingly. It is fine for tests and tools, but `Swaylib` itself should not need it, which keeps binaries small on Linux and Windows.
- No dependency gets added without a reason. Use the standard library and raylib first.

## Docs (IMPORTANT!!!)

Always update the docs if necessary when changing or adding code. If the docs already contain outdated information, expand your scope to cover that info too.

The docs are DocC only. Every public symbol gets a `///` doc comment, and longer material is written as articles in `Sources/Swaylib/Swaylib.docc/`. Build and check them with the [Swift-DocC plugin](https://github.com/swiftlang/swift-docc-plugin) (`swift package generate-documentation --target Swaylib --warnings-as-errors`), which CI runs, so broken symbol links fail the build. Planned articles: `GettingStarted.md`, `Backends.md` (native OpenGL, ANGLE, Zink, and how to pick one), `Platforms.md`, `APICoverage.md` (which raylib functions are wrapped, kept in step with the generator), `Architecture.md`, `Development.md`, `Roadmap.md`. Topic groups in `Swaylib.md` (the catalog's landing page) must list every public type, so nothing ends up in an unsorted "Other" section.

When a roadmap item is finished, check it off (`- [x]`) where it is. DO NOT move it into an earlier section like "Done: the MVP". The roadmap shows how each goal is progressing, so finished items stay with the section they belong to.

## Diagrams as Mermaid, not ASCII art

Never draw a flow, pipeline or architecture picture out of characters in a code block. Make a Mermaid diagram instead. DocC cannot render Mermaid itself, so keep the `.mmd` source in the catalog's `Resources/`, render it to SVG with [mermaid-cli](https://github.com/mermaid-js/mermaid-cli) (a light and a `~dark` variant, which DocC picks between), and commit both the source and the SVGs. Edit the source and rerender; never hand-edit the SVG.

## Outdated packages

PLEASE, PLEASE do not use a package that is old or deprecated. EVEN IF IT IS "INDUSTRY STANDARD" THAT DOES NOT MEAN IT IS GOOD!!! USE THE BEST PACKAGE AND LATEST VERSION LIKE A NORMAL PERSON WOULD!

Before adding or bumping a Swift package, check its latest release on GitHub or the [Swift Package Index](https://swiftpackageindex.com). Before bumping raylib or ANGLE, read their release notes and changelog for breaking changes. Toolchain versions come from [swift.org](https://www.swift.org/install/).

## Keep things human

Do no use em dashes or other special symbols not normally found in writing. Do not word things in a weird way. Keep it looking human. If you need to use, for example, an arrow icon, use an SVG instead.

Replacing an em dash with a hyphen is NOT a fix. A spaced hyphen doing an em dash's job ("the limit - 4 bytes", "fast - but wrong") is the same tic with a different character. Reword the sentence instead: use a comma, a colon, parentheses, or the actual word ("minus", "to", "through"). Plain hyphens in compound words and numeric ranges like 0-1 are fine.

## Use American spelling

It's fine to be British in the chat if the person is actually in a region where its spelled like that. But if not just use American spelling. The thing itself MUST use American spelling.
