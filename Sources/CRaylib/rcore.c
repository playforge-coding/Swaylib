// Compiles raylib's rcore module from the submodule. Relative includes inside it
// (platforms/..., external/...) resolve against the raylib/src/ directory.

// raylib's RGFW platform always creates a native OpenGL context and never an EGL one, so on macOS
// an OpenGL ES build cannot reach ANGLE. Fail here rather than build something that cannot render.
#if defined(__APPLE__) && defined(GRAPHICS_API_OPENGL_ES3)
#error "The ANGLE trait is not supported on macOS yet: raylib's RGFW platform does not create an EGL context. See the roadmap."
#endif

#if defined(SWAYLIB_METAL_IGNORED)
#warning "The Metal trait only works on macOS and has no effect on this platform."
#endif

// The Metal trait compiles a generated copy of rcore.c, because the rlgl include and the frame
// boundaries cannot be changed from outside it. See Tools/Generate/MetalOverlay.swift.
#if defined(RAYLIB_USE_RLMT)
#include "metal/rcore.c"
#else
#include "raylib/src/rcore.c"
#endif
