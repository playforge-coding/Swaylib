// Draws into a small render texture, then shows it scaled up with nearest neighbor filtering,
// next to a texture generated on the CPU.
import Swaylib

var window = try Window(width: 800, height: 450, title: "Swaylib: render textures")
window.targetFPS = 60

let canvas = try RenderTexture(width: 64, height: 64)
canvas.setFilter(.point)

var checkers = Image(width: 128, height: 128, checksX: 16, checksY: 16, .darkBlue, .skyBlue)
checkers.drawText("128", x: 40, y: 50, fontSize: 30, color: .rayWhite)
let generated = try Texture(image: checkers)

var angle: Float = 0

while !window.shouldClose {
    // A quarter turn per second, kept within one full turn so it never loses float precision.
    angle = (angle + 90 * Time.frame).truncatingRemainder(dividingBy: 360)

    textureMode(canvas) {
        Draw.clearBackground(.darkGray)
        Draw.circle(center: Vector2(32, 32), radius: 24, color: .gold)
        Draw.rectangle(
            Rectangle(x: 24, y: 24, width: 16, height: 16), origin: Vector2(8, 8), rotation: angle, color: .red)
    }

    drawing {
        Draw.clearBackground(.rayWhite)
        canvas.draw(to: Rectangle(x: 40, y: 60, width: 320, height: 320))
        generated.draw(at: Vector2(440, 60), rotation: 0, scale: 2.5)
        Draw.text("render texture, 64x64 scaled 5x", x: 40, y: 400, color: .darkGray)
        Draw.text("image generated on the CPU", x: 440, y: 400, color: .darkGray)
    }
}
