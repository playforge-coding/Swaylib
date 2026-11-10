# Swaylib

## Overview

Swaylib is a set of idiomatic Swift bindings for [raylib](https://github.com/raysan5/raylib). It is cross platform first: Linux, Windows and macOS are all first-class targets, and nothing may assume Apple frameworks or Darwin APIs. Swift Package Manager is the only build system. Rendering goes through raylib's own OpenGL layer (`rlgl`), either on the system's native OpenGL driver or on [ANGLE](https://chromium.googlesource.com/angle/angle), which translates OpenGL ES to Vulkan, Direct3D 11 or Metal. [Zink](https://docs.mesa3d.org/drivers/zink.html) (Mesa's OpenGL on Vulkan) is planned for later and is low priority. License: zlib, the same as raylib (`LICENSE` at the root). Third-party code comes in as a git submodule with its own license, never as a copy, and nothing under a stricter license (GPL, LGPL) may be added.

**Status:** an MVP exists. raylib 6.2 builds from a git submodule with SwiftPM, the core API is wrapped (260 of 619 raylib functions, see the generated API Coverage page), tests pass on Linux, and CI builds Windows and macOS. ANGLE compiles behind a trait but no binaries are shipped. The roadmap in `Sources/Swaylib/Swaylib.docc/Roadmap.md` tracks the rest. When code changes what this file says, update this file in the same change.

Goals:

- Swift that reads like Swift, not like C with a Swift accent. Users should not need to know raylib's C API to use Swaylib, but someone who knows raylib should find every function where they expect it.
- Full coverage of raylib's modules (`rcore`, `rshapes`, `rtextures`, `rtext`, `rmodels`, `raudio`) plus `raymath`. `rlgl` is exposed for advanced users but stays out of the main API.
- The same Swift code builds and runs on every supported platform with no `#if os(...)` in user code.
- Choosing a graphics backend is a package configuration, not a code change.
- Eventually, the web through Swift's Wasm SDK (see Platform support).

Non-goals (for now): mobile, and replacing raylib's C code with Swift. Swaylib wraps raylib; it does not reimplement it.

## Layout

- `Sources/CRaylib/`: raylib's repository as a shallow git submodule under `raylib/`, pinned to a release tag; the pinned commit is the version and the license is inside. Clone with `--recurse-submodules` (SwiftPM initializes submodules itself for dependents). SwiftPM never compiles `raylib/` directly: the wrapper files `rcore.c`, `rshapes.c`, `rtextures.c`, `rtext.c`, `rmodels.c`, `raudio.c` each include one raylib module from `raylib/src/`, and `rglfw.c` includes the bundled GLFW on Linux and Windows. macOS uses raylib's RGFW platform instead (plain C over the Objective-C runtime), because GLFW's Cocoa code is Objective-C without ARC and SwiftPM compiles Objective-C with ARC on, with no per-target switch short of `unsafeFlags`, which would stop the package from being used as a dependency. `include/CRaylib.h` is the umbrella header that exposes `raylib.h`, `raymath.h` and `rlgl.h`. Never modify the submodule; anything we need to change goes into a wrapper or a shim. `miniaudio/` is a second shallow submodule, miniaudio 0.11.26, because raylib 6.2's bundled 0.11.25 cannot open a PulseAudio device whose native format is s24_32 (common on PipeWire). On Linux and macOS `raudio.c` includes it first with raudio.c's exact `MA_*` settings, so the include guards skip raylib's copy. Windows keeps raylib's copy, since raudio.c must set up `windows.h` before miniaudio includes it. Updating raylib is: move the submodule to the new tag, regenerate, fix what broke, and if the new release bundles miniaudio 0.11.26 or newer, remove the miniaudio submodule and go back to the one-line `raudio.c`. There is deliberately no option to link a system raylib: the bindings are tied to one raylib release, and almost nobody has exactly that one installed.
- `Sources/CRaylibShims/`: C helpers for what Swift cannot call: the `va_list` log callback (atomic handler, any line length, and it exits after a fatal message as raylib's stdout logging does) and the variadic `TraceLog`. Also two upstream workarounds called by `Window`: on macOS, RGFW releasing `NSApp` on its last window close (`swaylibPlatformWindowOpened`/`Closed`; drop it when RGFW fixes `RGFW_deinitPlatform`), and under the ANGLE trait on Linux, GLFW closing the X display before terminating EGL, which crashes ANGLE's GLX backend (`swaylibPlatformWindowClosing` terminates EGL first).
- `Sources/Swaylib/`: the Swift API. `Math/` has the vectors, matrix, quaternion and rectangle; `Color.swift`, `Window.swift` (also `Time`, `Random` and the unattended-run support), `Drawing.swift` (the scoped `Begin`/`End` functions and the `Draw` namespace), `Camera.swift`, `Input.swift`, `Image.swift`, `Texture.swift` (also `RenderTexture`), `Font.swift`, `Shader.swift`, `Audio.swift`, `Log.swift`, `Errors.swift`. `Platform.swift` is the only file that imports the C runtime (for `getenv`). `Generated/` is written by the generator and never edited by hand. `Swaylib.docc/` is the DocC catalog.
- `Tools/Generate/`: the `swaylib-generate` executable and `wrapped.txt`, the list of raylib functions that have a Swift counterpart. It reads `raylib_api.json` from the submodule (`tools/rlparser/output/`), so the generated code always matches the pinned release.
- `Examples/`: ports of raylib's examples, one executable target each (`BasicWindow`, `BouncingBall`, `RenderTextures`, `Camera3D`). Each is also a smoke test on CI.
- `Tests/SwaylibTests/`: Swift Testing suites.
- `.github/workflows/ci.yml`: Linux (toolchain check against `.swift-version`, lint, generator check, build, ANGLE build, tests under Xvfb with the default backend and with the ANGLE trait on Mesa's EGL, examples, docs), macOS (build, tests, examples) and Windows (build, tests without a window). Every job reads or checks the toolchain from `.swift-version`, third-party actions are pinned to a commit, the token is read-only and checkouts do not keep credentials. It only runs when a push or pull request changes a path in its `paths` filters (sources, tests, examples, tools, the manifest, the toolchain and format configs, `.gitmodules`, both workflow files), written once as a YAML anchor shared by the push and pull request triggers; a new top-level file the build reads must be added there, and to `docs.yml`'s list if the docs build reads it. `.github/workflows/docs.yml` publishes the DocC catalog to GitHub Pages (https://swift-gamedev.github.io/Swaylib/) on every push to `main` that changes `Sources/`, the manifest, `.swift-version`, `.gitmodules` or the workflow, built with `--transform-for-static-hosting --hosting-base-path Swaylib`, with the site root replaced by a redirect to `documentation/swaylib/`.

The generator reads `raylib_api.json` and emits the mechanical parts: enums and option sets (`Generated/Enums.swift`), the named colors (`Generated/Colors.swift`), and the API Coverage article (`Swaylib.docc/APICoverage.md`), which lists every raylib function with the Swift symbol from `wrapped.txt`. Generated output is committed. `swift run swaylib-generate --check` fails when it is stale, and CI runs that.

## Graphics backends

raylib picks its graphics API when it is compiled (`GRAPHICS_API_OPENGL_33`, `GRAPHICS_API_OPENGL_ES3` and so on), not at runtime. So does Swaylib. Backends are SwiftPM package traits that set the C defines on `CRaylib`:

- Default (no trait): desktop OpenGL 3.3, which is rlgl's own default when nothing is defined.
- `ANGLE`: raylib built for OpenGL ES 3, and raylib tells GLFW to create an EGL context. GLFW loads `libEGL` at runtime, but rlgl's ES 3 path calls `gl*` directly, so `GLESv2` is linked (`libgles-dev` on Linux, ANGLE's own `libGLESv2` elsewhere) and the ANGLE build is what the program finds at runtime. On Linux the program must be linked against ANGLE itself (`-Xlinker -L<dir>`): linked against `libgles-dev` it records `libGLESv2.so.2`, which ANGLE (soname `libGLESv2.so`) never replaces. The dynamic loader must then find ANGLE: a runpath (`-Xlinker -rpath`) or `LD_LIBRARY_PATH`, since "next to the executable" only works with a runpath. Under the trait GLFW is told to load `libEGL.so` and `libGLESv2.so` (`_GLFW_EGL_LIBRARY`, `_GLFW_GLESV2_LIBRARY`), ANGLE's names, instead of Mesa's `.so.1`/`.so.2`; otherwise it mixes Mesa's EGL with ANGLE's GL. ANGLE's own backend (Vulkan, D3D11, Metal, OpenGL) is chosen at window creation through GLFW's `GLFW_ANGLE_PLATFORM_TYPE` hint or `ANGLE_DEFAULT_PLATFORM`; exposing that in Swift, and fetching ANGLE binaries, are roadmap items. Prebuilt binaries come from https://github.com/swift-gamedev/angle-prebuilt, Swaylib's fork of dsafdsaf132/angle-prebuilt. Its releases carry a `SHA256SUMS` file, and its SwiftShader is built with the X11 window surface (the upstream builds lack it), which its CI checks. The Development article shows how to download one and test against it. Not supported on macOS yet: raylib's RGFW platform only creates native OpenGL contexts, so `rcore.c` stops the build with an error. It is still the planned default there, where Apple's OpenGL is deprecated, once RGFW's raylib platform gains an EGL path.
- Zink (later): native OpenGL path pointed at a Mesa build with the Zink driver. Do not spend time on this until the other two are solid, and do not let Zink concerns shape the API.

Rules:

- The Swift API must be identical under every backend. If a feature only exists on one (for example a desktop OpenGL extension), it gets a runtime capability check, not a separate API.
- Shader code differs between GLSL 330 and GLSL ES 300. Examples and tests that use shaders ship both, picked with `#if ANGLE` (fine inside this package) or `Shader.language`. Docs aimed at users must show `Shader.language`: a trait's compilation condition is not visible in packages that depend on Swaylib.
- Getting ANGLE binaries is the hard part. Prefer prebuilt, versioned ANGLE releases fetched by a script with checksums. Never require users to install depot_tools to build Swaylib.

## Platform support

- Linux: X11 through GLFW (`_GLFW_X11`). Building needs the X11 and OpenGL headers (`libx11-dev libxrandr-dev libxi-dev libxcursor-dev libxinerama-dev libgl1-mesa-dev`, plus `libgles-dev` for the ANGLE trait); GLFW loads the X11 extensions and `libGL` at runtime. Wayland sessions work through XWayland. Native Wayland needs protocol headers generated by `wayland-scanner`, which raylib's Makefile runs and SwiftPM cannot, so it is a roadmap item.
- Windows: the Swift toolchain for Windows plus the MSVC build tools and Windows SDK, which Swift needs but does not install (swift.org's Windows instructions list them). Links `opengl32`, `gdi32`, `winmm`, `user32` and `shell32`. CI builds and runs the non-window tests; nobody has run it by hand yet.
- macOS: 15 or newer (the Swift `Mutex` in `Log` needs it). Cocoa through RGFW (`PLATFORM_DESKTOP_RGFW`), not GLFW; see the layout section for why. Links AppKit, IOKit, CoreVideo, QuartzCore, OpenGL and CoreAudio. Native OpenGL works but is deprecated, which is why ANGLE on Metal is the intended default there.
- Web (planned, does not build yet): the Swift SDK for Wasm, which targets WASI, with JavaScriptKit and its PackageToJS plugin, which also supplies the browser WASI shim. Emscripten is not part of the plan: only raylib's own web platform files need it, so Swaylib would provide its own raylib platform and `gl*` imports over WebGL 2. raylib's OpenGL ES 3 path stays, so there is no WebGPU backend. The Web section of the roadmap tracks the steps.

Platform-specific linker and define settings live in `Package.swift` with `.when(platforms:)`. Platform checks in Swift source are allowed only inside `Swaylib`, never in examples, and should be rare (today: `Platform.swift` only).

## API design rules

- raylib is single threaded and not reentrant. Every public API that touches the window, input, audio device, GPU or raylib's other global state is `@MainActor`. The package builds in the Swift 6 language mode with complete concurrency checking. Pure value types (vectors, colors, rectangles, math) are `Sendable` and not actor isolated.
- GPU and audio resources (`Texture`, `RenderTexture`, `Shader`, `Font`, `Image`, `Sound`, `Music`, `AudioDevice`, `Window`) are noncopyable structs (`~Copyable`) that own their raylib handle and unload it in `deinit`. Never leave unloading to the user. Use a class only when a resource really needs shared ownership.
- Loading functions `throw(SwaylibError)` instead of returning a struct the caller has to check with `IsTextureValid` and friends.
- Paired `Begin`/`End` calls are scoped closures: `drawing { }`, `mode2D(camera) { }`, `mode3D(camera) { }`, `textureMode(target) { }`, `shaderMode(shader) { }`, `blendMode(.additive) { }`, `scissorMode(area) { }`. A mismatched `End` must be impossible to write. raylib's `End` functions reset to the default rather than to the enclosing scope, so `DrawingState` in `Drawing.swift` keeps a stack per mode and every scope restores the enclosing value when it ends. `textureMode` starts its body without a camera and restores the outer target and camera.
- C enums and flag sets are generated Swift enums and `OptionSet`s. Integers that mean a key or a button never appear in the public API.
- Use Swift naming: `Window.shouldClose`, `texture.draw(at:tint:)`, `Color.rayWhite`. Keep raylib's terminology (texture, render texture, mode 2D) so its docs and cheatsheet still help. raylib's free functions live in namespaces: `Draw`, `Keyboard`, `Mouse`, `Time`, `Log`, `Random`. Overloads that differ only in a numeric type (`Float` versus `Int32`) make integer literals ambiguous, so give them distinct names (`setFloat`, `setInt`) instead.
- raylib resets some global input settings in `InitWindow` (the exit key, the mouse cursor) and keeps others across `CloseWindow` (the frame target). Anything Swaylib caches in a static must be reapplied in `Window.init`, and anything a property claims as its default must be set there. Setters that call into the platform (`Mouse.cursor`) only do so once `IsWindowReady()`; before that they store the value.
- raylib has one global window. `Window.init` throws `windowAlreadyOpen` while one is open. The same goes for the audio device: `AudioDevice.init` throws `audioDeviceAlreadyOpen`.
- raylib batches draws and submits them later by texture id, so resource `deinit`s that free GPU objects (`Texture`, `RenderTexture`, `Font`) flush the batch first (`flushPendingDraws`), and so do calls that change or read a texture's pixels (`update(pixels:)`, `image()`).
- Closing a window deletes its context's GPU objects. GPU resources record `GraphicsContext.generation` when they load and only unload GPU objects in `deinit` while that context is current; otherwise they free just their CPU memory, because the ids may belong to a later window. Audio resources are counted in `AudioLifetime`, which keeps the device open until the last `Sound` or `Music` unloads.
- raylib returns its default font or shader when loading fails. Check for that and throw, and never unload the default.
- A noncopyable struct without stored properties counts as initialized from the start, so its `deinit` runs even when `init` throws. Give such a type a stored property that `init` assigns last (`AudioDevice.isOpen`).
- Math types support the operators you would expect (`+`, `-`, `*`, scalar multiply, dot and cross as methods). `*` between two vectors is component-wise. `Quaternion` is its own type, not a `Vector4` alias, and `a * b` applies `a` first, like `Matrix`'s `*` (raylib's `QuaternionMultiply` is the other order). They are layout compatible with raylib's C structs so passing them across costs nothing. `ValueTypeTests` checks the layouts; keep it in step when adding a type.
- Strings go in as Swift `String`; no `UnsafePointer<CChar>` in the public API. Same for arrays and buffers: offer `[T]` (and later `Span`) based API, keep raw pointers internal.
- Do not hide raylib behind a game engine. No entity systems, scene graphs or app frameworks in `Swaylib`.
- Swift Testing's `#expect` cannot expand member accesses on noncopyable values. In tests, read `window.width` and friends into locals first.

## Building and testing

- `swift build` builds raylib and everything else with the default backend; `swift build --traits ANGLE` the OpenGL ES 3 variant. Requires the Swift version in `.swift-version` (swiftly installs it) and, on Linux, the X11 and OpenGL headers listed above.
- `swift test` runs the Swift Testing suites. `ValueTypeTests`, `GeneratedEnumTests` and `CRaylibTests` run anywhere. `WindowTests` opens a hidden window and draws into render textures, so it is enabled when `DISPLAY` is set on Linux (CI uses `xvfb-run -a swift test`), always on macOS, and only with `SWAYLIB_WINDOW_TESTS=1` on Windows; `SWAYLIB_WINDOW_TESTS=0` skips it anywhere. Render tests check specific pixels rather than comparing reference images.
- Every program using Swaylib honors `SWAYLIB_FRAMES=<n>` (`Window.shouldClose` turns true after `n` frames drawn with `drawing { }`, so it only stops programs that poll it) and `SWAYLIB_SCREENSHOT=<file.png>` (save the last of them, taken before the buffer swap). It still opens a real window, so Linux needs an X server or Xvfb. `SWAYLIB_FRAMES=20 SWAYLIB_SCREENSHOT=out.png swift run BasicWindow` is how to check an example without a person watching; CI does this for every example and uploads the screenshots.
- `swift run swaylib-generate` regenerates `Sources/Swaylib/Generated/` and the API Coverage page; `--check` only verifies. Run it after touching `Tools/Generate/` or `wrapped.txt`.
- CI builds and tests on Linux, Windows and macOS. A change that only builds on the platform you happen to be on is not done. When a CI job fails on a platform you cannot run, read the log and fix it; do not disable the job.
- When adding raylib API: write the wrapper with a doc comment, add a line per C function to `Tools/Generate/wrapped.txt`, regenerate, cover it with a test or an example, and list any new public type under a topic in `Swaylib.docc/Swaylib.md`.

## Git worktrees

Prefer doing work in a git worktree over switching branches in the main checkout, so the main checkout stays on `main` and parallel tasks don't step on each other. Claude Code's worktrees go under `.claude/worktrees/`, which is ignored. A new worktree does not check out submodules, so run `git submodule update --init` in it before building. Each worktree has its own `.build/`, so its first build compiles raylib from scratch. Remove the worktree (`git worktree remove`) once its branch is merged or abandoned.

## Searching the Codebase

Use fast, modern tools instead of the slow defaults:

- [`rg`](https://github.com/BurntSushi/ripgrep) (ripgrep) for text search, not `grep`. It respects `.gitignore` for you. **NOTE**: Prefer to use [`ast-grep`](https://ast-grep.github.io) when applicable as it uses the structure of the code instead.
- [`fd`](https://github.com/sharkdp/fd) for finding files by name, not `find`.
- [`ast-grep`](https://ast-grep.github.io) for structural searches and rewrites, like finding every call to a function or every type that conforms to a protocol. It supports both Swift and C. Call it as `ast-grep`. The `sg` alias is deprecated, so don't use it.
- `jq` for reading and querying JSON, including the submodule's `raylib_api.json`.

If your harness has dedicated search or file tools that already wrap these, those are fine too.

## Code Quality

Always lint and format:

- `swift format` (ships with the toolchain) formats and lints. Config lives in `.swift-format` at the root. `swift format --in-place --recursive Sources/Swaylib Sources/CRaylibShims Tools Tests Examples Package.swift` fixes, `swift format lint --strict --recursive` over the same paths reports. CI runs the lint. The generator's output must pass it too.
- `.editorconfig`: UTF-8, LF, 4 spaces, 120 columns for Swift; 2 spaces for Markdown, TOML, YAML and JSON.
- Do not format or lint the raylib or miniaudio submodules.

Use modern code practices:

- The latest stable Swift 6 release, Swift 6 language mode, complete strict concurrency. The toolchain is pinned in `.swift-version` (read by swiftly); `Package.swift` asks for tools version 6.2 so that users on 6.2 and newer can depend on the package.
- Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest.
- Typed throws, noncopyable types, `Span` and package traits are all fair game. Use them where they make the API better, not to show off.
- Use Foundation sparingly. It is fine for tests and the generator, but `Swaylib` itself does not import it, which keeps binaries small on Linux and Windows.
- No dependency gets added without a reason. Use the standard library and raylib first. The only package dependency is the Swift-DocC plugin.

## Docs (IMPORTANT!!!)

Always update the docs if necessary when changing or adding code. If the docs already contain outdated information, expand your scope to cover that info too.

The docs are DocC only. Every public symbol gets a `///` doc comment, and longer material is written as articles in `Sources/Swaylib/Swaylib.docc/`. Build and check them with the [Swift-DocC plugin](https://github.com/swiftlang/swift-docc-plugin) (`swift package generate-documentation --target Swaylib --warnings-as-errors`), which CI runs, so broken symbol links fail the build. Articles: `GettingStarted.md`, `Backends.md` (native OpenGL, ANGLE, Zink, and how to pick one), `Platforms.md`, `APICoverage.md` (generated, never edited by hand), `Architecture.md`, `Development.md`, `Roadmap.md`. Topic groups in `Swaylib.md` (the catalog's landing page) must list every public type, so nothing ends up in an unsorted "Other" section.

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
