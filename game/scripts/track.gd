extends Node3D
class_name RaceTrack

## Closed oval course. Geometry is generated as reusable 3D strips.
const RADIUS_X := 28.0
const RADIUS_Z := 18.0
const HALF_WIDTH := 4.0
const SEGMENTS := 160

func center(theta: float) -> Vector3:
    return Vector3(RADIUS_X * cos(theta), 0.0, RADIUS_Z * sin(theta))

func tangent(theta: float) -> Vector3:
    return Vector3(-RADIUS_X * sin(theta), 0.0, RADIUS_Z * cos(theta)).normalized()

func speed_factor(theta: float) -> float:
    return Vector2(RADIUS_X * sin(theta), RADIUS_Z * cos(theta)).length()

func outward(theta: float) -> Vector3:
    var direction := tangent(theta)
    return Vector3(direction.z, 0.0, -direction.x)

func road_height(theta: float, lane: float) -> float:
    return lane * 0.07 * (0.45 + 0.55 * abs(cos(theta)))

func point(theta: float, lane: float) -> Vector3:
    var p := center(theta) + outward(theta) * lane
    p.y = road_height(theta, lane)
    return p

func _ready() -> void:
    _add_strip("PinkRoad", -HALF_WIDTH, HALF_WIDTH, 0.0, Color("f27a80"))
    _add_strip("InnerCreamLine", -3.82, -3.60, 0.015, Color("fff0d4"))
    _add_strip("OuterCreamLine", 3.60, 3.82, 0.015, Color("fff0d4"))
    _add_strip("InnerBlueRail", -4.35, -4.01, 0.20, Color("245bc4"))
    _add_strip("OuterBlueRail", 4.01, 4.35, 0.20, Color("245bc4"))
    _add_side("OuterSide", 4.0, Color("245bc4"))
    _add_side("InnerSide", -4.0, Color("245bc4"))
    _add_track_marks()

func _add_strip(label: String, a: float, b: float, lift: float, color: Color) -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in SEGMENTS:
        var t0 := TAU * float(i) / SEGMENTS
        var t1 := TAU * float(i + 1) / SEGMENTS
        var p0 := point(t0, a) + Vector3.UP * lift
        var p1 := point(t0, b) + Vector3.UP * lift
        var p2 := point(t1, b) + Vector3.UP * lift
        var p3 := point(t1, a) + Vector3.UP * lift
        _quad(st, p0, p3, p2, p1)
    st.generate_normals()
    var instance := MeshInstance3D.new()
    instance.name = label
    instance.mesh = st.commit()
    instance.material_override = _mat(color)
    add_child(instance)

func _add_side(label: String, lane: float, color: Color) -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in SEGMENTS:
        var t0 := TAU * float(i) / SEGMENTS
        var t1 := TAU * float(i + 1) / SEGMENTS
        var p0 := point(t0, lane)
        var p1 := point(t1, lane)
        _quad(st, p0, p1, p1 - Vector3.UP * 0.85, p0 - Vector3.UP * 0.85)
    st.generate_normals()
    var instance := MeshInstance3D.new()
    instance.name = label
    instance.mesh = st.commit()
    var material := _mat(color)
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    instance.material_override = material
    add_child(instance)

func _add_track_marks() -> void:
    # A wide checkered finish line and two yellow boost areas are visual guides.
    for n in 8:
        var mark := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(0.65, 0.035, 0.68)
        mark.mesh = box
        mark.material_override = _mat(Color("fff0d4") if n % 2 == 0 else Color("245bc4"))
        mark.position = point(0.0, -3.5 + n) + Vector3.UP * 0.045
        mark.rotation.y = -PI / 2.0
        add_child(mark)
    for angle in [2.1, 4.2]:
        for n in 4:
            var pad := MeshInstance3D.new()
            var box := BoxMesh.new()
            box.size = Vector3(1.35, 0.035, 0.52)
            pad.mesh = box
            pad.material_override = _mat(Color("ffcf4d"))
            pad.position = point(angle, -1.8 + n * 1.2) + Vector3.UP * 0.05
            pad.rotation.y = -atan2(tangent(angle).z, tangent(angle).x)
            add_child(pad)

func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> void:
    for p in [p0, p1, p2, p0, p2, p3]:
        st.add_vertex(p)

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.95
    return material
