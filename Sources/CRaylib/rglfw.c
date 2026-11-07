// GLFW, bundled with raylib, for every platform except Apple ones. On macOS the same file has to
// be compiled as Objective-C, which rglfw.m does, because it pulls in GLFW's Cocoa sources.
#if !defined(__APPLE__)
#include "raylib/rglfw.c"
#endif
