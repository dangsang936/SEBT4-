extends Node3D

@export var id := ""
@export_file("*.tscn") var target_stage := ""
@export var target_door := ""
@export var locked := false
@export var unlock_flag := ""
@export var locked_timeline := "door_locked"

@onready var _sprite: AnimatedSprite3D = $AnimatedSprite3D


func _ready() -> void:
	add_to_group("spawn_points")
	$InteractiveArea3D.interacted.connect(_on_interacted)
	var arriving := id != "" and GameManager.pending_spawn == id
	_sprite.play("closing" if arriving else "idle")


func is_locked() -> bool:
	return locked and not GameManager.is_door_unlocked(unlock_flag)


func _on_interacted() -> void:
	if is_locked():
		_tell_locked()
		return
	if _sprite.animation == "opening":
		return
	_sprite.play("opening")
	await _sprite.animation_finished
	GameManager.change_stage(target_stage, target_door)


func _tell_locked() -> void:
	for body: Node3D in $InteractiveArea3D.get_overlapping_bodies():
		if body is Player:
			Conversation.play(locked_timeline, body)
			return
