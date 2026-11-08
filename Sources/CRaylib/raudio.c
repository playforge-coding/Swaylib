// Compiles raylib's raudio module from the submodule, with a newer miniaudio on Linux and macOS.
//
// raylib 6.2 bundles miniaudio 0.11.25, whose PulseAudio backend cannot open a playback device
// when the server's native format is one miniaudio does not handle (s24_32, common on PipeWire):
// it asks for float samples but also passes PA_STREAM_FIX_FORMAT, which makes the server use the
// native format anyway, and then rejects the stream. miniaudio 0.11.26 fixes that. Including it
// here first, with the settings raudio.c uses, means the include guards skip raudio.c's own copy.
// Drop this once raylib ships miniaudio 0.11.26 or newer.
//
// Windows keeps raylib's copy: raudio.c has to set up windows.h (NOGDI, NOUSER and so on) before
// miniaudio includes it, or windows.h clashes with raylib's names (CloseWindow, ShowCursor). The
// PulseAudio bug does not affect it.
#if !defined(_WIN32)
#include "raylib/src/raylib.h"  // RL_MALLOC and RL_FREE, used by MA_MALLOC and MA_FREE

// Exactly as raudio.c defines them, so its own definitions repeat these without a conflict.
#define MA_MALLOC RL_MALLOC
#define MA_FREE RL_FREE

#define MA_NO_JACK
#define MA_NO_WAV
#define MA_NO_FLAC
#define MA_NO_MP3
#define MA_NO_RESOURCE_MANAGER
#define MA_NO_NODE_GRAPH
#define MA_NO_ENGINE
#define MA_NO_GENERATION

#define MA_COINIT_VALUE 2

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio/miniaudio.h"
#endif

#include "raylib/src/raudio.c"
