extends Node3D

func _ready() -> void:
	push_warning("[Client] Entered world") # for time refrence in debuggers
	
	Network.spawn_scene.connect(_spawn_scene)
	Network.spawn_item.connect(_spawn_item)
	Network.despawn_item.connect(_despawn_item)
	Network.add_players.connect(_add_players)
	Network.remove_player.connect(_remove_player)

func _spawn_scene(node: NodePath, scene: String, position_: Vector3, name_: String):
	var new = load(scene).instantiate()
	new.name = name_
	
	get_node(node).add_child(new)
	new.global_position = position_

func _despawn_item(path: NodePath) -> void:
	if has_node(path):
		get_node(path).queue_free()

func _spawn_item(bytes, name_) -> void:
	var node = bytes_to_var_with_objects(bytes).instantiate()
	
	$Items.add_child(node)
	node.name = name_
	node.freeze = false

func _add_players(ids) -> void:
	for id in ids:
		var player = preload("res://scenes/player.tscn").instantiate()
		player.set_multiplayer_authority(id)
		player.name = str(id)
		add_child(player)
		player.global_position = $SpawnLoc.global_position
		
		if id == multiplayer.get_unique_id():
			player.get_node("Camera3D").current = true
			$CanvasLayer/Control/Loading.hide()

func _remove_player(id) -> void:
	if has_node(str(id)):
		get_node(str(id)).queue_free()

func _on_disconnect_pressed() -> void:
	get_node(str(multiplayer.get_unique_id()))._on_send_data_to_save_timeout()
	
	await get_tree().create_timer(0.5).timeout
	
	multiplayer.multiplayer_peer.close()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/menus/main.tscn")

func _on_exit_to_desktop_pressed() -> void:
	multiplayer.multiplayer_peer.close()
	get_tree().quit()


func _on_resume_pressed() -> void:
	$CanvasLayer/Control/PauseMenu.hide()
