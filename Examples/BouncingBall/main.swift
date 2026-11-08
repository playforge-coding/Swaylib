// A ball that bounces off the window edges. Space pauses it, the mouse drags it.
import Swaylib

var window = try Window(width: 800, height: 450, title: "Swaylib: bouncing ball", flags: [.windowResizable])
window.targetFPS = 60

var position = window.size / 2
// Pixels per second, the 5 and 4 pixels per frame of raylib's example at 60 FPS. Scaling by the
// frame time keeps the speed the same at any frame rate.
var speed = Vector2(300, 240)
let radius: Float = 20
var paused = false
var frames = 0

while !window.shouldClose {
    if Keyboard.isPressed(.space) {
        paused.toggle()
    }
    if Mouse.isDown(.left) {
        position = Mouse.position
    } else if !paused {
        position += speed * Time.frame
        // Bounce off each edge by pointing the speed back inward, and keep the ball inside, which
        // also brings it back after the window shrinks past it or it is dragged outside.
        let low = Vector2(radius, radius)
        let high = Vector2(max(radius, window.size.x - radius), max(radius, window.size.y - radius))
        if position.x <= low.x {
            speed.x = abs(speed.x)
        } else if position.x >= high.x {
            speed.x = -abs(speed.x)
        }
        if position.y <= low.y {
            speed.y = abs(speed.y)
        } else if position.y >= high.y {
            speed.y = -abs(speed.y)
        }
        position = Vector2(min(max(position.x, low.x), high.x), min(max(position.y, low.y), high.y))
    } else {
        frames += 1
    }

    drawing {
        Draw.clearBackground(.rayWhite)
        Draw.circle(center: position, radius: radius, color: .maroon)
        Draw.text("PRESS SPACE to PAUSE BALL MOVEMENT", x: 10, y: window.height - 25, color: .lightGray)
        if paused, (frames / 30) % 2 == 0 {
            Draw.text("PAUSED", x: 350, y: 200, fontSize: 30, color: .gray)
        }
        Draw.fps(x: 10, y: 10)
    }
}
