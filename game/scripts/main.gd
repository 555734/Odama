extends Node3D

const TrackScene := preload("res://scripts/track.gd")
const BallScene := preload("res://scenes/ball_visual.tscn")
const LAPS := 3

var track: RaceTrack
var camera: Camera3D
var racers: Array[Dictionary] = []
var race_time := 0.0
var lap_time := 0.0
var best_lap := INF
var last_lap_number := 0
var countdown := 3.0
var finished := false
var boost_meter := 100.0
var steer_left := false
var steer_right := false
var brake_held := false
var boost_held := false

var ui_root: Control
var hud_label: Label
var center_label: Label
var hint_label: Label
var buttons: Array[Button] = []

func _ready() -> void:
    _build_world()
    _build_ui()
    _reset_race()
    get_viewport().size_changed.connect(_layout_ui)

func _build_world() -> void:
    var environment_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("9cd8ff")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("ffffff")
    environment.ambient_light_energy = 0.6
    environment_node.environment = environment
    add_child(environment_node)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -38, 0)
    sun.light_energy = 1.4
    sun.shadow_enabled = true
    add_child(sun)

    track = TrackScene.new()
    track.name = "RaceTrack"
    add_child(track)
    _build_scenery()

    camera = Camera3D.new()
    camera.current = true
    camera.fov = 72.0
    camera.near = 0.1
    camera.far = 240.0
    add_child(camera)

func _build_scenery() -> void:
    # Everything is an actual low-poly 3D mesh. Shapes follow the reference pack.
    _box("SkyIsland", Vector3(0, -2.9, 0), Vector3(112, 4, 92), Color("a8d976"))
    _box("IslandUnderlayer", Vector3(0, -5.8, 0), Vector3(108, 2.8, 88), Color("6f79b8"))
    _cylinder("CenterPond", Vector3(0, -0.76, 0), 8.5, 0.13, Color("72d9e8"))

    # The route's center is open so the winding road reads clearly from the camera.
    var random := RandomNumberGenerator.new()
    random.seed = 7342026
    for i in 34:
        var theta := TAU * float(i) / 34.0 + random.randf_range(-0.11, 0.11)
        var radius_x := 39.0 + random.randf_range(0.0, 10.0)
        var radius_z := 29.0 + random.randf_range(0.0, 8.0)
        _tree(Vector3(radius_x * cos(theta), -0.8, radius_z * sin(theta)), random.randf_range(0.85, 1.4))
    for i in 10:
        var theta := TAU * float(i) / 10.0 + 0.25
        _flag(track.point(theta, 6.0), i)
    _grandstand(Vector3(0, -0.3, -31), Color("f3a6c7"))
    _grandstand(Vector3(-40, -0.3, 0), Color("ffcb6b"))
    _finish_arch()
    for i in 9:
        var theta := TAU * float(i) / 9.0
        _cloud(Vector3(70 * cos(theta), 22 + float(i % 3) * 3, 60 * sin(theta)))

func _tree(p: Vector3, scale_factor: float) -> void:
    _cylinder("TreeTrunk", p + Vector3.UP * 1.2 * scale_factor, 0.42 * scale_factor, 2.4 * scale_factor, Color("d98655"))
    var palette := [Color("9fdb68"), Color("6ccc86"), Color("60c6ae"), Color("b9e87d")]
    var color: Color = palette[int(abs(p.x + p.z)) % palette.size()]
    _sphere("TreeCrown", p + Vector3(0, 3.2, 0) * scale_factor, Vector3(1.5, 1.35, 1.5) * scale_factor, color)
    _sphere("TreeCrown", p + Vector3(-0.8, 2.75, 0.25) * scale_factor, Vector3(0.95, 0.9, 0.95) * scale_factor, color.lightened(0.10))
    _sphere("TreeCrown", p + Vector3(0.85, 2.6, -0.3) * scale_factor, Vector3(0.9, 0.9, 0.9) * scale_factor, color.darkened(0.08))

func _flag(p: Vector3, index: int) -> void:
    var colors := [Color("f37eab"), Color("ffc646"), Color("58c8e7")]
    _cylinder("FlagPost", p + Vector3(0, 1.1, 0), 0.08, 2.3, Color("245bc4"))
    var flag := _box("Pennant", p + Vector3(0.45, 2.05, 0), Vector3(0.9, 0.48, 0.07), colors[index % 3])
    flag.rotation.y = float(index) * 0.6
    _sphere("FlagFinial", p + Vector3(0, 2.3, 0), Vector3.ONE * 0.15, Color("ffcb45"))

func _grandstand(p: Vector3, accent: Color) -> void:
    for row in 3:
        var step := _box("GrandstandStep", p + Vector3(0, 0.4 + row * 0.52, -row * 0.65), Vector3(7.0, 0.5, 1.1), accent.lightened(row * 0.08))
        step.rotation.y = 0.0
        for col in 6:
            var colors := [Color("ffcb45"), Color("59d0dc"), Color("ab77e5"), Color("f787af")]
            _sphere("SphereSpectator", p + Vector3(-2.9 + col * 1.15, 0.85 + row * 0.52, -row * 0.65), Vector3.ONE * 0.35, colors[(col + row) % 4])

func _finish_arch() -> void:
    var mid: Vector3 = track.point(0.0, 0.0)
    var left: Vector3 = track.point(0.0, -5.0)
    var right: Vector3 = track.point(0.0, 5.0)
    _box("GoalLeftPost", left + Vector3.UP * 2.2, Vector3(0.72, 4.4, 0.8), Color("245bc4"))
    _box("GoalRightPost", right + Vector3.UP * 2.2, Vector3(0.72, 4.4, 0.8), Color("245bc4"))
    _box("GoalTop", mid + Vector3.UP * 4.6, Vector3(11.0, 0.55, 0.9), Color("ffcb45"))
    for i in 10:
        _box("GoalChecker", mid + Vector3(-4.5 + i, 4.62, 0.48), Vector3(0.98, 0.45, 0.06), Color("fff1d9") if i % 2 == 0 else Color("245bc4"))

func _cloud(p: Vector3) -> void:
    _sphere("Cloud", p, Vector3(2.4, 1.2, 1.2), Color("ffffff"))
    _sphere("Cloud", p + Vector3(-1.0, 0.6, 0), Vector3(1.3, 1.2, 1.1), Color("f0f8ff"))
    _sphere("Cloud", p + Vector3(1.2, 0.35, 0), Vector3(1.3, 1.0, 1.0), Color("ffffff"))

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    return material

func _box(label: String, p: Vector3, box_size: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := BoxMesh.new()
    mesh.size = box_size
    node.mesh = mesh
    node.material_override = _material(color)
    node.position = p
    add_child(node)
    return node

func _sphere(label: String, p: Vector3, sphere_scale: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := SphereMesh.new()
    mesh.radial_segments = 12
    mesh.rings = 6
    node.mesh = mesh
    node.material_override = _material(color)
    node.position = p
    node.scale = sphere_scale
    add_child(node)
    return node

func _cylinder(label: String, p: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 12
    node.mesh = mesh
    node.material_override = _material(color)
    node.position = p
    add_child(node)
    return node

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    ui_root = Control.new()
    ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui_root)
    hud_label = _label("HUD", 26, Color("19386d"))
    center_label = _label("Countdown", 76, Color("ffffff"))
    center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label = _label("Hint", 22, Color("19386d"))
    hint_label.text = "STEER ◀ ▶   •   HOLD BOOST   •   BRAKE"
    var names := ["◀", "▶", "BRAKE", "BOOST", "RESTART"]
    for name in names:
        var button := Button.new()
        button.text = name
        button.add_theme_font_size_override("font_size", 25)
        button.focus_mode = Control.FOCUS_NONE
        ui_root.add_child(button)
        buttons.append(button)
    buttons[0].button_down.connect(func(): steer_left = true)
    buttons[0].button_up.connect(func(): steer_left = false)
    buttons[1].button_down.connect(func(): steer_right = true)
    buttons[1].button_up.connect(func(): steer_right = false)
    buttons[2].button_down.connect(func(): brake_held = true)
    buttons[2].button_up.connect(func(): brake_held = false)
    buttons[3].button_down.connect(func(): boost_held = true)
    buttons[3].button_up.connect(func(): boost_held = false)
    buttons[4].pressed.connect(_reset_race)
    _layout_ui()

func _label(label_name: String, size: int, color: Color) -> Label:
    var label := Label.new()
    label.name = label_name
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.7))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    ui_root.add_child(label)
    return label

func _layout_ui() -> void:
    if ui_root == null:
        return
    var viewport_size := get_viewport().get_visible_rect().size
    var w := viewport_size.x
    var h := viewport_size.y
    hud_label.position = Vector2(22, 14)
    hud_label.size = Vector2(w - 44, 118)
    center_label.position = Vector2(0, h * 0.29)
    center_label.size = Vector2(w, 110)
    hint_label.position = Vector2(22, h - 150)
    hint_label.size = Vector2(w - 44, 34)
    buttons[0].position = Vector2(24, h - 112)
    buttons[1].position = Vector2(150, h - 112)
    buttons[2].position = Vector2(w - 408, h - 112)
    buttons[3].position = Vector2(w - 276, h - 112)
    buttons[4].position = Vector2(w - 144, 18)
    for i in buttons.size():
        buttons[i].size = Vector2(116 if i < 2 else 124, 86 if i < 4 else 56)
    buttons[4].size = Vector2(126, 56)

func _reset_race() -> void:
    for racer in racers:
        racer["node"].queue_free()
    racers.clear()
    race_time = 0.0
    lap_time = 0.0
    best_lap = INF
    last_lap_number = 0
    countdown = 3.0
    boost_meter = 100.0
    finished = false
    for i in 4:
        var ball: BallVisual = BallScene.instantiate() as BallVisual
        ball.design = i
        ball.name = "Racer_%d" % i
        add_child(ball)
        racers.append({"node": ball, "progress": -0.065 * i, "lane": -1.7 + i * 1.1, "speed": 0.0, "base_speed": 17.1 + 0.6 * i})
        ball.position = track.point(racers[i]["progress"], racers[i]["lane"]) + Vector3.UP
    _update_camera(1.0)
    _update_hud()

func _process(delta: float) -> void:
    if racers.is_empty():
        return
    if countdown > 0.0:
        countdown = maxf(0.0, countdown - delta)
        center_label.text = str(ceili(countdown)) if countdown > 0.0 else "GO!"
        _update_camera(delta)
        return
    if finished:
        _update_camera(delta)
        return
    center_label.text = ""
    race_time += delta
    lap_time += delta
    for i in racers.size():
        var racer := racers[i]
        var old_progress: float = racer["progress"]
        if i == 0:
            _update_player(racer, delta)
        else:
            _update_ai(racer, i, delta)
        var theta: float = racer["progress"]
        var direction: Vector3 = track.tangent(theta)
        var ball: BallVisual = racer["node"]
        ball.position = track.point(theta, racer["lane"]) + Vector3.UP
        ball.roll(direction, maxf(0.0, racer["speed"] * delta))
        racers[i] = racer
        if i == 0:
            _check_lap(old_progress, theta)
    _check_bumps()
    _update_camera(delta)
    _update_hud()

func _update_player(racer: Dictionary, delta: float) -> void:
    var left := steer_left or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
    var right := steer_right or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
    var brake := brake_held or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
    var boost := boost_held or Input.is_key_pressed(KEY_SPACE)
    var steer := int(right) - int(left)
    racer["lane"] = clampf(racer["lane"] + steer * 6.1 * delta, -3.0, 3.0)
    var target_speed := 18.5
    if brake:
        target_speed = 8.0
    elif boost and boost_meter > 0.0:
        target_speed = 27.0
        boost_meter = maxf(0.0, boost_meter - 27.0 * delta)
    else:
        boost_meter = minf(100.0, boost_meter + 8.0 * delta)
    if absf(racer["lane"]) > 2.8:
        target_speed *= 0.85
    racer["speed"] = move_toward(racer["speed"], target_speed, 17.0 * delta)
    racer["progress"] += racer["speed"] * delta / track.speed_factor(racer["progress"])

func _update_ai(racer: Dictionary, index: int, delta: float) -> void:
    racer["lane"] = clampf(sin(race_time * 0.45 + index * 1.9) * (1.0 + index * 0.25), -2.5, 2.5)
    var target_speed: float = racer["base_speed"] + sin(race_time * 0.8 + index * 2.0) * 1.0
    racer["speed"] = move_toward(racer["speed"], target_speed, 14.0 * delta)
    racer["progress"] += racer["speed"] * delta / track.speed_factor(racer["progress"])

func _check_bumps() -> void:
    var player := racers[0]
    for i in range(1, racers.size()):
        var rival := racers[i]
        var angle_gap: float = absf(player["progress"] - rival["progress"])
        if angle_gap < 0.08 and absf(player["lane"] - rival["lane"]) < 1.75:
            player["speed"] = minf(player["speed"], rival["speed"] + 0.3)
            player["lane"] = clampf(player["lane"] + signf(player["lane"] - rival["lane"]) * 0.07, -3.0, 3.0)
    racers[0] = player

func _check_lap(previous: float, current: float) -> void:
    var new_number := floori(current / TAU)
    if new_number > last_lap_number:
        best_lap = minf(best_lap, lap_time)
        lap_time = 0.0
        last_lap_number = new_number
    if current >= TAU * LAPS:
        finished = true
        center_label.text = "FINISH!  %s" % _format_time(race_time)

func _update_camera(delta: float) -> void:
    var player := racers[0]
    var theta: float = player["progress"]
    var p: Vector3 = track.point(theta, player["lane"]) + Vector3.UP
    var direction: Vector3 = track.tangent(theta)
    var desired := p - direction * 9.5 + Vector3.UP * 5.7
    camera.global_position = camera.global_position.lerp(desired, clampf(delta * 6.0, 0.0, 1.0))
    camera.look_at(p + direction * 6.5 + Vector3.UP * 0.6, Vector3.UP)

func _update_hud() -> void:
    var progress: float = racers[0]["progress"]
    var lap := mini(LAPS, floori(progress / TAU) + 1)
    var rank := 1
    for i in range(1, racers.size()):
        if racers[i]["progress"] > progress:
            rank += 1
    var best_text := "--:--" if is_inf(best_lap) else _format_time(best_lap)
    hud_label.text = "LAP %d/%d    POS %d/4    TIME %s\nBEST %s    SPEED %d    BOOST %d%%" % [lap, LAPS, rank, _format_time(race_time), best_text, roundi(racers[0]["speed"] * 3.6), roundi(boost_meter)]

func _format_time(seconds: float) -> String:
    var total := int(seconds)
    return "%02d:%02d.%02d" % [total / 60, total % 60, int(seconds * 100.0) % 100]
