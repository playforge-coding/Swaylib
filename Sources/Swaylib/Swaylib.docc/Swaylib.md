# ``Swaylib``

Idiomatic Swift bindings for raylib, on Linux, Windows and macOS.

## Overview

![The Swaylib logo: a pixel art orange square with a Swift bird above the word swaylib.](swaylib-logo)

Swaylib wraps [raylib](https://www.raylib.com), the C library for simple games and graphics
programs, in Swift that reads like Swift. raylib itself is compiled into your program by Swift
Package Manager, so raylib does not need to be installed. Linux needs the X11 and OpenGL
development headers to build; <doc:Platforms> lists what each system needs.

```swift
import Swaylib

var window = try Window(width: 800, height: 450, title: "Hello")
window.targetFPS = 60

while !window.shouldClose {
    drawing {
        Draw.clearBackground(.rayWhite)
        Draw.text("Hello from Swift", x: 190, y: 200, color: .lightGray)
    }
}
```

The names follow raylib's, so its [cheatsheet](https://www.raylib.com/cheatsheet/cheatsheet.html)
still helps: `DrawCircleV` is ``Draw/circle(center:radius:color:)``, `LoadTexture` is
``Texture/init(path:)``, `BeginMode2D` and `EndMode2D` are the ``mode2D(_:_:)`` block. The
<doc:APICoverage> page lists every raylib function and what wraps it.

Resources such as ``Texture``, ``Font`` and ``Sound`` unload themselves when they go out of scope,
loading throws ``SwaylibError`` instead of returning something to check, and every function that
touches the window, input or the GPU runs on the main actor.

## Topics

### Getting started

- <doc:GettingStarted>
- <doc:Backends>
- <doc:Platforms>

### Window and frames

- ``Window``
- ``drawing(_:)``
- ``mode2D(_:_:)``
- ``mode3D(_:_:)``
- ``textureMode(_:_:)``
- ``shaderMode(_:_:)``
- ``blendMode(_:_:)``
- ``scissorMode(_:_:)``
- ``Time``
- ``ConfigFlags``

### Drawing

- ``Draw``
- ``Color``
- ``Camera2D``
- ``Camera3D``
- ``BlendMode``
- ``CameraMode``
- ``CameraProjection``

### Input

- ``Keyboard``
- ``Mouse``
- ``Gamepad``
- ``Touch``
- ``Gestures``
- ``KeyboardKey``
- ``MouseButton``
- ``MouseCursor``
- ``GamepadButton``
- ``GamepadAxis``
- ``Gesture``

### Images and textures

- ``Image``
- ``Texture``
- ``RenderTexture``
- ``PixelFormat``
- ``TextureFilter``
- ``TextureWrap``
- ``CubemapLayout``
- ``NPatchLayout``

### Text

- ``Font``
- ``FontType``

### Shaders

- ``Shader``
- ``ShaderLanguage``
- ``ShaderLocationIndex``
- ``ShaderUniformDataType``
- ``ShaderAttributeDataType``
- ``MaterialMapIndex``

### Audio

- ``AudioDevice``
- ``Sound``
- ``Music``

### Math

- ``Vector2``
- ``Vector3``
- ``Vector4``
- ``Quaternion``
- ``Matrix``
- ``Rectangle``

### Errors, logging and randomness

- ``SwaylibError``
- ``SwaylibError/Resource``
- ``Log``
- ``TraceLogLevel``
- ``Random``
- ``raylibVersion``

### Project

- <doc:APICoverage>
- <doc:Architecture>
- <doc:Development>
- <doc:Roadmap>
