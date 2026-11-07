// A ball that bounces off the window edges. Space pauses it, the mouse drags it.
import Swaylib

var window = try Window(width: 800, height: 450, title: "Swaylib: bouncing ball", flags: [.windowResizable])
window.targetFPS = 60

var position = window.size / 2
var speed = Vector2(5, 4)
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
        position += speed
        if position.x >= window.size.x - radius || position.x <= radius {
            speed.x = -speed.x
        }
        if position.y >= window.size.y - radius || position.y <= radius {
            speed.y = -speed.y
        }
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
