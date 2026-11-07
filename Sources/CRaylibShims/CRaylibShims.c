#include "CRaylibShims.h"

#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>

#include <CRaylib.h>

static SwaylibLogHandler currentHandler = NULL;

static void forwardLog(int logLevel, const char *text, va_list args)
{
    char buffer[1024];
    vsnprintf(buffer, sizeof buffer, text, args);
    SwaylibLogHandler handler = currentHandler;
    if (handler != NULL) handler(logLevel, buffer);
}

void swaylibSetLogHandler(SwaylibLogHandler handler)
{
    currentHandler = handler;
    SetTraceLogCallback(handler != NULL ? forwardLog : NULL);
}
