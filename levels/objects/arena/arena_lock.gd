class_name ArenaLock
extends Node

signal cleared

@export var enemies: Node3D
@export var unlock_flag := "arena_cleared"
@export var cleared_timeline := "arena_cleared"
@export var respawn_time := 60.0

const HINT_TEXT := "Mẹo: Nấm không đánh được! Đứng cạnh nấm, bấm X (hoặc K) để nhấc lên, quay mặt ra mép đảo rồi bấm X lần nữa để ném nấm xuống biển."

var _alive := 0
var _cleared := false
var _label: Label
var _hint: Label


func _ready() -> void:
	if enemies == null:
		push_error("ArenaLock: 'enemies' is not set")
		return
	_cleared = GameManager.is_door_unlocked(unlock_flag)
	for enemy: Node in enemies.get_children():
		if enemy is EnemyCharacter:
			_track(enemy, _spawn_info(enemy))
	_create_labels()
	_update_label()
	if _alive == 0 and not _cleared:
		_clear.call_deferred()


func remaining() -> int:
	return _alive


func _spawn_info(enemy: Node3D) -> Dictionary:
	var props := {}
	for p: Dictionary in enemy.get_property_list():
		var usage: int = p["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_STORAGE:
			props[p["name"]] = enemy.get(p["name"])
	return {"scene": enemy.scene_file_path, "transform": enemy.transform, "props": props}


func _track(enemy: Node, info: Dictionary) -> void:
	_alive += 1
	enemy.set_meta(&"arena", true)
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy, info))


func _on_enemy_tree_exited(enemy: Node, info: Dictionary) -> void:
	if not is_inside_tree() or GameManager.is_changing():
		return
	if not enemy.is_queued_for_deletion():
		return
	_alive -= 1
	_schedule_respawn(info)
	_update_label()
	if _alive == 0 and not _cleared:
		_clear()


func _schedule_respawn(info: Dictionary) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = respawn_time
	timer.timeout.connect(_respawn.bind(info, timer))
	add_child(timer)
	timer.start()


func _respawn(info: Dictionary, timer: Timer) -> void:
	timer.queue_free()
	if GameManager.is_changing():
		return
	var scene := load(info["scene"]) as PackedScene
	if scene == null:
		return
	var enemy := scene.instantiate() as Node3D
	var props: Dictionary = info["props"]
	for key: String in props:
		enemy.set(key, props[key])
	enemy.transform = info["transform"]
	enemies.add_child(enemy)
	_track(enemy, info)
	_update_label()


func _clear() -> void:
	_cleared = true
	GameManager.unlock_door(unlock_flag)
	cleared.emit()
	_update_label()
	_announce_cleared()


func _announce_cleared() -> void:
	var stage := owner as Stage
	if cleared_timeline == "" or stage == null:
		return
	var tick := Timer.new()
	tick.wait_time = 0.1
	add_child(tick)
	tick.start()
	var waited := 0.0
	while waited < 0.6 or (not _fox_ready(stage.player) and waited < 6.0):
		await tick.timeout
		waited += 0.1
	tick.queue_free()
	if _fox_ready(stage.player):
		Conversation.play(cleared_timeline, stage.player)


func _fox_ready(fox: Player) -> bool:
	if not is_instance_valid(fox) or fox.health <= 0 or fox.is_talking or fox.held != null:
		return false
	if Dialogic.current_timeline != null:
		return false
	var state: Node = fox.fsm.current_state
	return state == fox.fsm.states.get("idle") or state == fox.fsm.states.get("run")


func _create_labels() -> void:
	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(8, 6)
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	layer.add_child(_label)
	_hint = Label.new()
	_hint.position = Vector2(8, 22)
	_hint.size = Vector2(300, 0)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 9)
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.text = HINT_TEXT
	layer.add_child(_hint)
	add_child(layer)


func _update_label() -> void:
	if _label != null:
		if _cleared:
			_label.text = "Cửa đã mở! Quái: %d" % _alive
		else:
			_label.text = "Quái còn lại: %d" % _alive
	if _hint != null:
		_hint.visible = _has_unhittable_enemy()


func _has_unhittable_enemy() -> bool:
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		if enemy is EnemyCharacter and enemy.get_meta(&"arena", false) and not enemy.is_queued_for_deletion() \
				and not enemy.has_node("Direction/HurtArea3D"):
			return true
	return false
