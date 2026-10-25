class_name EnemyZone
extends Area3D

## A box of the stage that keeps itself stocked with enemies. Every spawn_interval seconds, if
## fewer than max_enemies of its enemies are alive, it drops one more on a random walkable spot
## inside the box. An enemy that dies (or falls into the sea) leaves the tree, the zone counts it
## out, and a later tick replaces it.
##
## The box is the CollisionShape3D's BoxShape3D: drag its handles in the editor to resize the zone.
## The Area3D itself detects nothing (no layer, no mask) — it is only there to give the box a shape
## you can see and edit.

## What the zone spawns. Whatever has a `zone` property gets this zone written into it.
@export var enemy_scene: PackedScene
@export var max_enemies := 3
## Seconds between two spawns.
@export var spawn_interval := 4.0
## How far (flat, in meters) from the zone's center its enemies may chase the fox before giving up
## and walking back. Keep it larger than half the box's diagonal: otherwise an enemy wandering to a
## corner of the box would already count as too far.
@export var leash_radius := 7.0

var _alive := 0

@onready var _box: CollisionShape3D = $CollisionShape3D
@onready var _timer: Timer = $Timer


func _ready() -> void:
	_timer.wait_time = spawn_interval
	_timer.timeout.connect(_on_timer_timeout)
	_timer.start()


## How many of this zone's enemies are in the tree right now (a dying one counts until it's gone).
func alive_count() -> int:
	return _alive


## A random point of the box, pulled to the center of the nearest walkable cell. Vector3.INF when
## the stage has no Pathfinder.
func random_point() -> Vector3:
	var finder := GridPathfinder.find(self)
	if finder == null:
		return Vector3.INF
	var half: Vector3 = (_box.shape as BoxShape3D).size / 2.0
	var local := Vector3(randf_range(-half.x, half.x), 0.0, randf_range(-half.z, half.z))
	return finder.closest_point(_box.global_transform * local)


## The flat distance from the center of the box to `point`.
func distance_from_center(point: Vector3) -> float:
	var center := _box.global_position
	return Vector2(point.x - center.x, point.z - center.z).length()


func _on_timer_timeout() -> void:
	if _alive >= max_enemies or enemy_scene == null:
		return
	var point := random_point()
	if point == Vector3.INF:
		return    # no Pathfinder in this stage
	var enemy: Node3D = enemy_scene.instantiate()
	if "zone" in enemy:
		enemy.zone = self
	# A sibling of the zone, not a child: rotating or scaling the zone mustn't drag its enemies.
	get_parent().add_child(enemy)
	enemy.global_position = point
	_alive += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))


## An enemy that is picked up or thrown is reparented, which fires tree_exited too but leaves it
## alive and coming back: only one that is queued for deletion (Dead and KillZone both queue_free)
## is counted out.
func _on_enemy_tree_exited(enemy: Node) -> void:
	if enemy.is_queued_for_deletion():
		_alive -= 1
