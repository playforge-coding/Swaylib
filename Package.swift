// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Swaylib",
    platforms: [
        .macOS(.v14)
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
        // raylib's C source, vendored unmodified under raylib/. The wrapper files at the top level
        // of the target include it, so the vendored directory itself is never compiled directly.
        .target(
            name: "CRaylib",
            exclude: ["raylib", "LICENSE", "VERSION"],
            sources: [
                "rcore.c", "rshapes.c", "rtextures.c", "rtext.c", "rmodels.c", "raudio.c",
                "rglfw.c", "rglfw.m",
            ],
            cSettings: [
                .headerSearchPath("raylib"),
                .headerSearchPath("raylib/external/glfw/include"),
                .define("PLATFORM_DESKTOP_GLFW"),
                // Without any GRAPHICS_API_OPENGL_* define rlgl picks desktop OpenGL 3.3.
                .define("GRAPHICS_API_OPENGL_ES3", .when(traits: ["ANGLE"])),
                .define("_GLFW_X11", .when(platforms: [.linux])),
            ],
            linkerSettings: [
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
