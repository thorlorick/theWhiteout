class_name VisionComponent
extends Node2D

# -------------------------------------------------------
# VisionComponent
# Casts rays. Emits two signals. That's it.
# -------------------------------------------------------

signal target_spotted(body: Node2D, intensity: float)
signal target_lost(last_known_position: Vector2)

# -------------------------------------------------------
# EXPORTS
# -------------------------------------------------------
@export_group("Setup")
@export var body:                CharacterBody2D
@export var wall_collision_mask: int   = 1
@export var debug_draw:          bool  = true

@export_group("Rays")
@export var ray_count:           int   = 30
@export var ray_length:          float = 200.0
@export var cone_half_spread:    float = 60.0

# -------------------------------------------------------
# CONSTANTS
# -------------------------------------------------------
const LOST_GRACE_SECONDS: float = 0.1

# -------------------------------------------------------
# INTERNAL STATE
# -------------------------------------------------------
var facing:      Vector2 = Vector2.DOWN
var space_state: PhysicsDirectSpaceState2D

var _last_seen_body: Node2D  = null
var _last_known_pos: Vector2 = Vector2.ZERO
var _is_tracking:   bool    = false
var _grace_timer:   float   = 0.0

# -------------------------------------------------------
# READY
# -------------------------------------------------------
func _ready() -> void:
	space_state = get_world_2d().direct_space_state

func _physics_process(delta: float) -> void:
	_cast_rays(delta)

# -------------------------------------------------------
# update_direction — called by GuardAgent
# -------------------------------------------------------
func update_direction(direction: Vector2, _is_moving: bool = false, _is_running: bool = false) -> void:
	if direction != Vector2.ZERO:
		facing = direction

# -------------------------------------------------------
# _cast_rays
# -------------------------------------------------------
func _cast_rays(delta: float) -> void:
	var hits:      int    = 0
	var seen_body: Node2D = null

	for i in range(ray_count):
		var t       = float(i) / float(ray_count - 1) if ray_count > 1 else 0.0
		var angle   = lerp(-cone_half_spread, cone_half_spread, t)
		var ray_dir = facing.rotated(deg_to_rad(angle))
		var target  = body.global_position + ray_dir * ray_length

		var query            = PhysicsRayQueryParameters2D.create(body.global_position, target)
		query.exclude        = [body]
		query.collision_mask = wall_collision_mask

		var result = space_state.intersect_ray(query)
		if result and result.collider.is_in_group("player"):
			hits     += 1
			seen_body = result.collider

	if hits > 0:
		_grace_timer    = LOST_GRACE_SECONDS
		_last_seen_body = seen_body
		_last_known_pos = seen_body.global_position

		if not _is_tracking:
			_is_tracking = true

		# 1. Coverage: how much of the cone is hitting the player? (0.0 to 1.0)
		var coverage = float(hits) / float(ray_count)

		# 2. Proximity: 1.0 if touching, 0.0 at the tip of the ray
		var dist      = body.global_position.distance_to(seen_body.global_position)
		var proximity = clamp(1.0 - (dist / ray_length), 0.0, 1.0)

		# 3. Final intensity: combined score
		var intensity = coverage * proximity

		target_spotted.emit(seen_body, intensity)

	else:
		if _is_tracking:
			_grace_timer -= delta
			if _grace_timer <= 0.0:
				_is_tracking    = false
				_last_seen_body = null
				target_lost.emit(_last_known_pos)

# -------------------------------------------------------
# clear_target — called by GuardAgent if needed
# -------------------------------------------------------
func clear_target() -> void:
	_is_tracking    = false
	_last_seen_body = null
	_last_known_pos = Vector2.ZERO
	_grace_timer    = 0.0

# -------------------------------------------------------
# DEBUG DRAW
# -------------------------------------------------------
func _process(_delta: float) -> void:
	if debug_draw:
		queue_redraw()

func _draw() -> void:
	if not debug_draw or body == null:
		return

	var offset = body.global_position - global_position
	var color  = Color(0.2, 1.0, 0.4, 0.4) if _is_tracking else Color(1.0, 1.0, 0.0, 0.3)

	for i in range(ray_count):
		var t       = float(i) / float(ray_count - 1) if ray_count > 1 else 0.0
		var angle   = lerp(-cone_half_spread, cone_half_spread, t)
		var ray_dir = facing.rotated(deg_to_rad(angle))
		draw_line(offset, offset + ray_dir * ray_length, color, 1.5)

	if _last_known_pos != Vector2.ZERO and not _is_tracking:
		var lkp = _last_known_pos - global_position
		draw_circle(lkp, 5.0, Color(1, 0.5, 0, 0.8))
