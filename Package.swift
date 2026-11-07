// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Swaylib",
    platforms: [
        // Synchronization.Mutex, which Log uses, needs macOS 15.
        .macOS(.v15)
    ],
    products: [
        .library(name: "Swaylib", targets: ["Swaylib"])
    ],
    traits: [
        .trait(
            name: "ANGLE",
            description: "Build raylib for OpenGL ES 3 on an EGL context, so it runs on ANGLE's libEGL and libGLESv2."
        ),
        .default(enabledTraits: []),
    ],
    targets: [
        // raylib's own source, a git submodule at a tagged release under raylib/. The wrapper
        // files at the top level of the target include it, so the submodule itself is never
        // compiled directly.
        .target(
            name: "CRaylib",
            exclude: ["raylib"],
            sources: [
                "rcore.c", "rshapes.c", "rtextures.c", "rtext.c", "rmodels.c", "raudio.c",
                "rglfw.c",
            ],
            cSettings: [
                .headerSearchPath("raylib/src"),
                .headerSearchPath("raylib/src/external/glfw/include"),
                // GLFW's Cocoa code is Objective-C without ARC, and SwiftPM compiles Objective-C
                // with ARC on and offers no way to turn it off, so macOS uses raylib's RGFW
                // platform instead, whose macOS backend is plain C over the Objective-C runtime.
                .define("PLATFORM_DESKTOP_GLFW", .when(platforms: [.linux, .windows])),
                .define("PLATFORM_DESKTOP_RGFW", .when(platforms: [.macOS])),
                // Without any GRAPHICS_API_OPENGL_* define rlgl picks desktop OpenGL 3.3.
                .define("GRAPHICS_API_OPENGL_ES3", .when(traits: ["ANGLE"])),
                .define("_GLFW_X11", .when(platforms: [.linux])),
            ],
            linkerSettings: [
                // rlgl's OpenGL ES 3 path calls gl* directly, so the GLES library must be on the
                // linker path: libgles-dev's on Linux, ANGLE's own libGLESv2 on Windows and macOS.
                .linkedLibrary("GLESv2", .when(traits: ["ANGLE"])),
                .linkedLibrary("X11", .when(platforms: [.linux])),
                .linkedLibrary("m", .when(platforms: [.linux])),
                .linkedLibrary("dl", .when(platforms: [.linux])),
                .linkedLibrary("pthread", .when(platforms: [.linux])),
                .linkedLibrary("rt", .when(platforms: [.linux])),
                .linkedLibrary("opengl32", .when(platforms: [.windows])),
                .linkedLibrary("gdi32", .when(platforms: [.windows])),
                .linkedLibrary("winmm", .when(platforms: [.windows])),
                .linkedLibrary("user32", .when(platforms: [.windows])),
                .linkedLibrary("shell32", .when(platforms: [.windows])),
                .linkedFramework("Foundation", .when(platforms: [.macOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedFramework("IOKit", .when(platforms: [.macOS])),
                .linkedFramework("OpenGL", .when(platforms: [.macOS])),
                .linkedFramework("CoreVideo", .when(platforms: [.macOS])),
                .linkedFramework("QuartzCore", .when(platforms: [.macOS])),
                .linkedFramework("CoreAudio", .when(platforms: [.macOS])),
            ]
        ),
        // C helpers for the few raylib entry points Swift cannot call directly (va_list callbacks).
        .target(
            name: "CRaylibShims",
            dependencies: ["CRaylib"]
        ),
        .target(
            name: "Swaylib",
            dependencies: ["CRaylib", "CRaylibShims"]
        ),
        .testTarget(
            name: "SwaylibTests",
            dependencies: ["Swaylib"]
        ),
    ],
    cLanguageStandard: .gnu11
)
