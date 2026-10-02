extends SceneTree

## Export editable GLB source models without Blender or third-party dependencies.
## Run: godot --headless --path game --script res://tools/export_models.gd

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var output := ProjectSettings.globalize_path("res://models")
    DirAccess.make_dir_recursive_absolute(output)
    var ball_scene: PackedScene = load("res://scenes/ball_visual.tscn")
    for i in 4:
        var ball: BallVisual = ball_scene.instantiate() as BallVisual
        ball.design = i
        root.add_child(ball)
        await process_frame
        if not _export(ball, output.path_join("ball_%s.glb" % "abcd"[i])):
            quit(1)
            return
        ball.queue_free()
        await process_frame
    var track := RaceTrack.new()
    root.add_child(track)
    await process_frame
    if not _export(track, output.path_join("track_oval.glb")):
        quit(1)
        return
    track.queue_free()
    await process_frame
    var main_scene: PackedScene = load("res://scenes/main.tscn")
    var game: Node3D = main_scene.instantiate()
    root.add_child(game)
    await process_frame
    var scenery := Node3D.new()
    scenery.name = "EnvironmentKit"
    for child in game.get_children():
        if child is MeshInstance3D:
            scenery.add_child(child.duplicate())
    if not _export(scenery, output.path_join("environment_kit.glb")):
        scenery.free()
        game.queue_free()
        quit(1)
        return
    scenery.free()
    game.queue_free()
    await process_frame
    print("GLB EXPORT PASS: four painted balls, oval track and scenery kit")
    quit(0)

func _export(node: Node, path: String) -> bool:
    var document := GLTFDocument.new()
    var state := GLTFState.new()
    var error := document.append_from_scene(node, state)
    if error != OK:
        push_error("GLB scene conversion failed: %s (%d)" % [path, error])
        return false
    error = document.write_to_filesystem(state, path)
    if error != OK:
        push_error("GLB write failed: %s (%d)" % [path, error])
        return false
    print("Wrote ", path)
    return true
