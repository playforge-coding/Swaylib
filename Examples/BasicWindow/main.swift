// The smallest Swaylib program: a window with some text in it.
import Swaylib

var window = try Window(width: 800, height: 450, title: "Swaylib: basic window")
window.targetFPS = 60

while !window.shouldClose {
    drawing {
        Draw.clearBackground(.rayWhite)
        Draw.text("Congrats! You created your first window!", x: 190, y: 200, color: .lightGray)
    }
}
