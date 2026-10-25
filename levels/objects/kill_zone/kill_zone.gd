extends Area3D

## A flat zone just under the sea: whatever falls in dies. The fox missing a platform ends up here.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.die()
		# Stop the fall right here: the camera follows the fox, and two seconds of falling (the
		# Dead state) would carry it down past the bottom of the sea into an empty void.
		body.movement_enabled = false
	elif body is BaseCharacter:
		body.queue_free()    # an enemy that falls into the sea


func _physics_process(_delta: float) -> void:
	var surface := _top_y()
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.is_queued_for_deletion() or not (enemy is BaseCharacter):
			continue
		if _is_carried(enemy):
			continue
		if enemy.global_position.y < surface:
			enemy.queue_free()


func _top_y() -> float:
	var shape := $CollisionShape3D as CollisionShape3D
	var box := shape.shape as BoxShape3D
	return shape.global_position.y + box.size.y * 0.5


func _is_carried(enemy: BaseCharacter) -> bool:
	return enemy.fsm != null and enemy.fsm.states.has("carried") \
		and enemy.fsm.current_state == enemy.fsm.states.carried
