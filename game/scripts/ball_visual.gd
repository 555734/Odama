extends Node3D
class_name BallVisual

## Reusable 3D racing ball. Its paint is a generated equirectangular texture,
## so the same model can also be exported as a GLB for further editing.
@export_range(0, 3) var design: int = 0

const PAINT := [
    preload("res://textures/ball_a.png"),
    preload("res://textures/ball_b.png"),
    preload("res://textures/ball_c.png"),
    preload("res://textures/ball_d.png")
]

var sphere: MeshInstance3D

func _ready() -> void:
    sphere = MeshInstance3D.new()
    sphere.name = "PaintedSphere"
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh.radial_segments = 48
    mesh.rings = 24
    sphere.mesh = mesh
    var paint := StandardMaterial3D.new()
    paint.albedo_texture = PAINT[clampi(design, 0, 3)]
    paint.roughness = 0.92
    paint.metallic = 0.0
    sphere.material_override = paint
    add_child(sphere)

func roll(direction: Vector3, distance: float) -> void:
    if sphere == null or direction.length_squared() < 0.001:
        return
    sphere.rotate(Vector3.UP.cross(direction).normalized(), distance)
