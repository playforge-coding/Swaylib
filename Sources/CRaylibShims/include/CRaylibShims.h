// Helpers for the parts of raylib's API that Swift cannot call directly.
#ifndef SWAYLIB_CRAYLIB_SHIMS_H
#define SWAYLIB_CRAYLIB_SHIMS_H

#ifdef __cplusplus
extern "C" {
#endif

// Receives one fully formatted log line. logLevel is a raylib TraceLogLevel value.
typedef void (*SwaylibLogHandler)(int logLevel, const char *message);

// Routes raylib's trace log through handler. raylib's own callback takes a va_list, which Swift
// cannot produce or consume, so the formatting happens here. Passing NULL restores raylib's
// default logging to stdout.
void swaylibSetLogHandler(SwaylibLogHandler handler);

#ifdef __cplusplus
}
#endif

#endif
