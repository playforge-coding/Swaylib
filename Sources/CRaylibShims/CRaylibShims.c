#include "CRaylibShims.h"

#include <stdarg.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include <CRaylib.h>

#if defined(__APPLE__)
// Declarations only; the implementation is compiled into rcore by raylib's RGFW platform.
#include "../CRaylib/raylib/external/RGFW/RGFW.h"
#endif

// Atomic because raylib can log from its audio thread while the main thread swaps handlers.
static _Atomic(SwaylibLogHandler) currentHandler = NULL;

static void forwardLog(int logLevel, const char *text, va_list args)
{
    SwaylibLogHandler handler = atomic_load(&currentHandler);
    if (handler != NULL)
    {
        // Most lines fit on the stack. Longer ones are measured and formatted again into a heap
        // buffer, from a copy of args so the second pass still has its arguments.
        char stackBuffer[1024];
        va_list copy;
        va_copy(copy, args);
        int length = vsnprintf(stackBuffer, sizeof stackBuffer, text, copy);
        va_end(copy);

        if (length >= (int)sizeof stackBuffer)
        {
            char *heapBuffer = malloc((size_t)length + 1);
            if (heapBuffer != NULL)
            {
                vsnprintf(heapBuffer, (size_t)length + 1, text, args);
                handler(logLevel, heapBuffer);
                free(heapBuffer);
            }
            else handler(logLevel, stackBuffer);
        }
        else if (length >= 0) handler(logLevel, stackBuffer);
    }

    // raylib exits after a fatal message when it prints to stdout itself, but returns when a
    // callback is installed. Exit here too, so installing a handler never changes control flow
    // (and raylib's fatal paths, such as a failed context activation, never continue half done).
    if (logLevel == LOG_FATAL) exit(EXIT_FAILURE);
}

void swaylibSetLogHandler(SwaylibLogHandler handler)
{
    atomic_store(&currentHandler, handler);
    SetTraceLogCallback(handler != NULL ? forwardLog : NULL);
}

void swaylibLog(int logLevel, const char *message)
{
    TraceLog(logLevel, "%s", message);
}

// RGFW_window_close calls RGFW_deinit once its window count reaches zero, and RGFW's macOS
// deinit releases NSApp. Holding one extra count for the life of the process keeps that from
// happening; RGFW_init is a no-op while the platform is still initialized, so later windows
// open normally. RGFW never clears its root window pointer on close, so that is done here.
void swaylibPlatformWindowOpened(void)
{
#if defined(__APPLE__)
    static bool held = false;
    RGFW_info *info = RGFW_getInfo();
    if (!held && info != NULL)
    {
        info->windowCount += 1;
        held = true;
    }
#endif
}

void swaylibPlatformWindowClosed(void)
{
#if defined(__APPLE__)
    RGFW_info *info = RGFW_getInfo();
    if (info != NULL && info->windowCount <= 1) info->root = NULL;
#endif
}
