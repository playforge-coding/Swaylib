// Compiles raylib's rcore module from the submodule. Relative includes inside it
// (platforms/..., external/...) resolve against the raylib/src/ directory.

// raylib's RGFW platform always creates a native OpenGL context and never an EGL one, so on macOS
// an OpenGL ES build cannot reach ANGLE. Fail here rather than build something that cannot render.
#if defined(__APPLE__) && defined(GRAPHICS_API_OPENGL_ES3)
#error "The ANGLE trait is not supported on macOS yet: raylib's RGFW platform does not create an EGL context. See the roadmap."
#endif

#include "raylib/src/rcore.c"
