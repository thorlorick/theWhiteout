class_name VisionComponent
extends Node2D

signal spotted_ue(body)

const RAY_COUNT:  int   = 3
const RAY_LENGTH: float = 200.0
const RAY_SPREAD: float = 15.0

var current_direction: String = "down"
var space_state: PhysicsDirectSpaceState2D

@export var body: CharacterBody2D

func _ready() -> void:
	space_state = get_world_2d().direct_space_state

func _physics_process(delta: float) -> void:
	_cast_rays()

func update_direction(direction: String, is_moving: bool) -> void:
	if direction != "":
		current_direction = direction

func _cast_rays() -> void:
	var angles = _get_ray_angles()
	for angle in angles:
		var direction_vector = _direction_to_vector(current_direction).rotated(deg_to_rad(angle))
		var target           = body.global_position + direction_vector * RAY_LENGTH
		var query            = PhysicsRayQueryParameters2D.create(body.global_position, target)
		query.exclude        = [body]
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result:
			if result.collider.is_in_group("ue"):
				spotted_ue.emit(result.collider)
				return

func _get_ray_angles() -> Array:
	if RAY_COUNT == 1:
		return [0.0]
	var angles = []
	for i in range(RAY_COUNT):
		var t = float(i) / float(RAY_COUNT - 1)
		angles.append(lerp(-RAY_SPREAD, RAY_SPREAD, t))
	return angles

func _direction_to_vector(dir: String) -> Vector2:
	match dir:
		"up":    return Vector2.UP
		"down":  return Vector2.DOWN
		"left":  return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.DOWN
