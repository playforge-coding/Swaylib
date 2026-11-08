// The Metal implementation of rlgl, from the raylib-backends submodule. SwiftPM links this target
// only on macOS under the Metal trait, but it still compiles every target of the root package on
// every platform, so the guard keeps this file empty elsewhere.
#if defined(__APPLE__)
#include "../CRaylib/raylib-backends/backends/rlmt/rlmt.mm"
#endif
