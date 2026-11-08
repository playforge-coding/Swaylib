// A cube on a grid, seen through an orbiting 3D camera.
import Swaylib

var window = try Window(width: 800, height: 450, title: "Swaylib: 3D camera")
window.targetFPS = 60

var camera = Camera3D(position: Vector3(10, 10, 10), target: .zero, fovy: 45)
let cubePosition = Vector3.zero

while !window.shouldClose {
    camera.update(mode: .orbital)

    drawing {
        Draw.clearBackground(.rayWhite)
        mode3D(camera) {
            Draw.cube(at: cubePosition, size: Vector3(2, 2, 2), color: .red)
            Draw.cubeWires(at: cubePosition, size: Vector3(2, 2, 2), color: .maroon)
            Draw.grid(slices: 10, spacing: 1)
        }
        Draw.text("The camera orbits the cube", x: 10, y: 40, color: .darkGray)
        Draw.fps(x: 10, y: 10)
    }
}
