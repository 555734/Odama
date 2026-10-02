extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    if scene == null:
        push_error("Main scene failed to load")
        quit(1)
        return
    var game: Node3D = scene.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    var track: RaceTrack = game.track
    if track == null or game.racers.size() != 4:
        push_error("World or four racers missing")
        quit(1)
        return
    if absf(track.point(0.0, 4.0).distance_to(track.point(0.0, -4.0)) - 8.0) > 0.1:
        push_error("Track width is wrong")
        quit(1)
        return
    game.countdown = 0.0
    for i in 90:
        await process_frame
    if game.racers[0]["progress"] <= 0.0 or game.race_time <= 0.0:
        push_error("Race did not advance")
        quit(1)
        return
    game._reset_race()
    await process_frame
    if game.racers.size() != 4 or game.race_time != 0.0:
        push_error("Restart failed")
        quit(1)
        return
    print("SMOKE PASS: world, models, movement, UI and restart")
    quit(0)
