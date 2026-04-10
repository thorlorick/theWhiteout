class_name VisionComponent
extends Node2D

# -------------------------------------------------------
# VisionComponent
# Casts rays. Emits two signals. That's it.
# -------------------------------------------------------

signal target_spotted(body: Node2D, distance: float)
signal target_lost(last_known_position: Vector2)

# -------------------------------------------------------
# EXPORTS
# -------------------------------------------------------
@export_group("Setup")
@export var body:                CharacterBody2D
@export var wall_collision_mask: int   = 1
@export var debug_draw:          bool  = true

@export_group("Rays")
@export var ray_count:           int   = 5
@export var ray_length:          float = 200.0
@export var cone_half_spread:    float = 10.0

@export_group("Sweep")
@export var sweep_angle:         float = 25.0
@export var sweep_speed:         float = 60.0

# -------------------------------------------------------
# CONSTANTS
# -------------------------------------------------------
const LOST_GRACE_SECONDS: float = 0.1

# -------------------------------------------------------
# INTERNAL STATE
# -------------------------------------------------------
var facing:      Vector2 = Vector2.DOWN
var space_state: PhysicsDirectSpaceState2D

var _last_seen_body:     Node2D  = null
var _last_known_pos:     Vector2 = Vector2.ZERO
var _is_tracking:        bool    = false
var _grace_timer:        float   = 0.0

var _sweep_angle:        float   = 0.0
var _sweep_dir:          float   = 1.0
var _is_moving:          bool    = false
var _looking_around:     bool    = false
var _look_step:          int     = 0
var _look_timer:         float   = 0.0

const LOOK_ANGLES: Array = [-40.0, 0.0, 40.0, 0.0]
const LOOK_STEP_TIME: float = 0.8

# -------------------------------------------------------
# READY
# -------------------------------------------------------
func _ready() -> void:
	space_state = get_world_2d().direct_space_state

func _physics_process(delta: float) -> void:
	_update_sweep(delta)
	_cast_rays(delta)

# -------------------------------------------------------
# update_direction — called by GuardAgent
# -------------------------------------------------------
func update_direction(direction: Vector2, is_moving: bool) -> void:
	var was_moving = _is_moving
	_is_moving = is_moving

	if is_moving and direction != Vector2.ZERO:
		facing          = direction
		_looking_around = false
		_look_step      = 0
		_look_timer     = 0.0

	if was_moving and not is_moving:
		_looking_around = true
		_look_step      = 0
		_look_timer     = 0.0

# -------------------------------------------------------
# _update_sweep
# -------------------------------------------------------
func _update_sweep(delta: float) -> void:
	if _is_tracking and _last_seen_body != null:
		var to_target    = (_last_seen_body.global_position - body.global_position).normalized()
		var facing_angle = rad_to_deg(facing.angle())
		var target_angle = rad_to_deg(to_target.angle())
		var desired      = target_angle - facing_angle
		_sweep_angle     = move_toward(_sweep_angle, desired, sweep_speed * delta * 3.0)
		return

	if _looking_around:
		_look_timer += delta
		if _look_timer >= LOOK_STEP_TIME:
			_look_timer = 0.0
			_look_step += 1
			if _look_step >= LOOK_ANGLES.size():
				_look_step      = LOOK_ANGLES.size() - 1
				_looking_around = false
		_sweep_angle = move_toward(_sweep_angle, LOOK_ANGLES[_look_step], sweep_speed * delta)
		return

	_sweep_angle += sweep_speed * _sweep_dir * delta
	if _sweep_angle > sweep_angle:
		_sweep_angle = sweep_angle
		_sweep_dir   = -1.0
	elif _sweep_angle < -sweep_angle:
		_sweep_angle = -sweep_angle
		_sweep_dir   =  1.0

# -------------------------------------------------------
# _cast_rays
# -------------------------------------------------------
func _cast_rays(delta: float) -> void:
	var hits:       int    = 0
	var seen_body:  Node2D = null
	var gaze = facing.rotated(deg_to_rad(_sweep_angle))

	for i in range(ray_count):
		var t       = float(i) / float(ray_count - 1) if ray_count > 1 else 0.0
		var angle   = lerp(-cone_half_spread, cone_half_spread, t)
		var ray_dir = gaze.rotated(deg_to_rad(angle))
		var target  = body.global_position + ray_dir * ray_length
		
		var query   = PhysicsRayQueryParameters2D.create(body.global_position, target)
		query.exclude        = [body]
		query.collision_mask = wall_collision_mask
		
		var result  = space_state.intersect_ray(query)
		if result and result.collider.is_in_group("player"):
			hits += 1
			seen_body = result.collider

	if hits > 0:
		_grace_timer     = LOST_GRACE_SECONDS
		_last_seen_body  = seen_body
		_last_known_pos  = seen_body.global_position
		_looking_around  = false

		if not _is_tracking:
			_is_tracking = true

		# --- THE MATH SECTION ---
		
		# 1. Coverage: How much of the cone is hitting the player? (0.2 to 1.0)
		var coverage = float(hits) / float(ray_count)
		
		# 2. Proximity: 1.0 if touching, 0.0 if at the very tip of the ray.
		var dist = body.global_position.distance_to(seen_body.global_position)
		var proximity = clamp(1.0 - (dist / ray_length), 0.0, 1.0)
		
		# 3. Final Intensity: Combined score
		var intensity = coverage * proximity
		
		# Now we send the "Packaged Info"
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
	var gaze   = facing.rotated(deg_to_rad(_sweep_angle))
	var color  = Color(0.2, 1.0, 0.4, 0.4) if _is_tracking else Color(1.0, 1.0, 0.0, 0.3)

	for i in range(ray_count):
		var t       = float(i) / float(ray_count - 1) if ray_count > 1 else 0.0
		var angle   = lerp(-cone_half_spread, cone_half_spread, t)
		var ray_dir = gaze.rotated(deg_to_rad(angle))
		draw_line(offset, offset + ray_dir * ray_length, color, 1.5)

	if _last_known_pos != Vector2.ZERO and not _is_tracking:
		var lkp = _last_known_pos - global_position
		draw_circle(lkp, 5.0, Color(1, 0.5, 0, 0.8))
