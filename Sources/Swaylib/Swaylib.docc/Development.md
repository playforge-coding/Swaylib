# Development

Building, testing and contributing to Swaylib itself.

## Building

raylib is a git submodule, so clone with `git clone --recurse-submodules`, or run
`git submodule update --init` in an existing clone. SwiftPM does this itself when Swaylib is used
as a dependency.

On Linux, install the X11 and OpenGL development headers first; <doc:Platforms> has the package
names for each system.

`swift build` builds raylib and the package with the default backend, `swift build --traits ANGLE`
the OpenGL ES 3 variant. The toolchain version is pinned in `.swift-version`, which
[swiftly](https://www.swift.org/swiftly/) reads, and CI uses the same version on every platform.

## Testing

`swift test` runs the Swift Testing suites. The value type and generated code tests run anywhere.
The window tests open a hidden window and draw into render textures, so they need a display: they
run when `DISPLAY` is set on Linux (use `xvfb-run -a swift test` on a server), always on macOS, and
only with `SWAYLIB_WINDOW_TESTS=1` on Windows. `SWAYLIB_WINDOW_TESTS=0` skips them anywhere.

The examples double as smoke tests: `SWAYLIB_FRAMES=20 SWAYLIB_SCREENSHOT=out.png swift run
BasicWindow` draws 20 frames, writes the last one and exits. CI runs every example this way and
keeps the screenshots as artifacts. In PowerShell on Windows, set the variables first:

```
$env:SWAYLIB_FRAMES = "20"; $env:SWAYLIB_SCREENSHOT = "out.png"; swift run BasicWindow
```

### Testing on ANGLE

CI tests the `ANGLE` trait on Mesa's EGL and GLES. To test on ANGLE itself on Linux, download a
release from [swift-gamedev/angle-prebuilt](https://github.com/swift-gamedev/angle-prebuilt) and
check it against the release's `SHA256SUMS`:

```
gh release download <tag> -R swift-gamedev/angle-prebuilt -p 'angle-*-linux-x64.tar.gz' -p SHA256SUMS
sha256sum --check --ignore-missing SHA256SUMS
tar xzf angle-*-linux-x64.tar.gz
```

The libraries are in `angle/out/Release`. Copy them to a directory of your choice (the commands
below use `/opt/angle/lib`) and link the build against it with a runpath, so the test binary finds
them:

```
swift test --traits ANGLE -Xlinker -L/opt/angle/lib -Xlinker -rpath -Xlinker /opt/angle/lib
ANGLE_DEFAULT_PLATFORM=vulkan swift test --traits ANGLE -Xlinker -L/opt/angle/lib -Xlinker -rpath -Xlinker /opt/angle/lib
ANGLE_DEFAULT_PLATFORM=swiftshader swift test --traits ANGLE -Xlinker -L/opt/angle/lib -Xlinker -rpath -Xlinker /opt/angle/lib
```

The first runs on ANGLE's default backend for the platform (OpenGL on Linux), the second on
Vulkan, and the third on SwiftShader, ANGLE's software renderer, which needs no GPU. raylib logs
the renderer when the window opens; it starts with `ANGLE (` when ANGLE is in use.

## Formatting and linting

`swift format` ships with the toolchain and reads `.swift-format` at the root:

```
swift format --in-place --recursive Sources/Swaylib Sources/CRaylibShims Tools Tests Examples Package.swift
swift format lint --strict --recursive Sources/Swaylib Sources/CRaylibShims Tools Tests Examples Package.swift
```

The raylib submodule is never formatted.

## Generated code

After editing `Tools/Generate/` or `wrapped.txt`, run `swift run swaylib-generate` and commit the
output. `swift run swaylib-generate --check` fails if the committed output is stale; CI runs it.

## Documentation

Every public symbol has a `///` comment and the articles live in `Sources/Swaylib/Swaylib.docc/`.
Build the docs with the Swift-DocC plugin:

```
swift package generate-documentation --target Swaylib --warnings-as-errors
```

CI runs that command, so a broken symbol link fails the build. To browse them locally:

```
swift package --disable-sandbox preview-documentation --target Swaylib
```

Every push to `main` publishes the docs to
[swift-gamedev.github.io/Swaylib](https://swift-gamedev.github.io/Swaylib/) through the Docs
workflow (`.github/workflows/docs.yml`). It builds them for static hosting under the `/Swaylib/`
base path and replaces the site's root page with a redirect to the landing page. It can also be
run by hand from the Actions tab.

## Adding raylib API

1. Write the Swift wrapper next to the related code in `Sources/Swaylib/`, with a doc comment.
2. Add a line to `Tools/Generate/wrapped.txt` for each raylib function it replaces and regenerate.
3. Cover it with a test, or use it in an example.
4. If it introduces a public type, list it under a topic in `Swaylib.docc/Swaylib.md`.
