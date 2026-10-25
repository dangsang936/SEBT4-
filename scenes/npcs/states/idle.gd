extends FSMState

## Stands for a while, then wanders off.

func _enter() -> void:
	obj.stop_horizontal()
	obj.change_animation("idle")
	timer = randf_range(obj.rest_time.x, obj.rest_time.y)


func _update(delta: float) -> void:
	obj.stop_horizontal()
	timer -= delta
	if timer <= 0.0:
		change_state(fsm.states.wander)
