class_name VisionComponent
extends Node2D
# -----------------------------------------------------------------------------
# VisionComponent
# Eyes that scan the room. Sweep rotates around facing direction.
# When idle, plays a look-around sequence before settling.
# Facing is a Vector2 — no hardwired strings.
# -----------------------------------------------------------------------------
signal spotted_ue(body)
signal lost_ue()

const RAY_COUNT:       int   = 5
const RAY_LENGTH:      float = 200.0
const LOST_TIMER_MAX:  float = 0.5
const MIN_DISTANCE:    float = 30.0

# sweep — eyes rock left and right while moving
const SWEEP_ANGLE:     float = 25.0   # degrees either side of facing
const SWEEP_SPEED:     float = 60.0   # degrees per second

# look-around — plays when guard stops
const LOOK_ANGLES:     Array = [-40.0, 0.0, 40.0, 0.0]  # sequence of offsets
const LOOK_STEP_TIME:  float = 0.8    # seconds per step

var facing:          Vector2 = Vector2.DOWN
var space_state:     PhysicsDirectSpaceState2D

var _was_seeing_ue:  bool   = false
var _lost_timer:     float  = 0.0
var _last_seen_body: Node2D = null

var _sweep_angle:    float  = 0.0
var _sweep_dir:      float  = 1.0

var _is_moving:      bool   = false
var _look_step:      int    = 0
var _look_timer:     float  = 0.0
var _looking_around: bool   = false

@export var body: CharacterBody2D

func _ready() -> void:
	space_state = get_world_2d().direct_space_state

func _physics_process(delta: float) -> void:
	_update_sweep(delta)
	_cast_rays(delta)

# -----------------------------------------------------------------------------
# update_direction — called by GuardAgent when velocity_changed fires
# -----------------------------------------------------------------------------
func update_direction(direction: Vector2, is_moving: bool) -> void:
	var was_moving = _is_moving
	_is_moving = is_moving

	if is_moving and direction != Vector2.ZERO:
		facing          = direction
		_looking_around = false
		_look_step      = 0
		_look_timer     = 0.0

	# just stopped — start look-around
	if was_moving and not is_moving:
		_looking_around = true
		_look_step      = 0
		_look_timer     = 0.0

# -----------------------------------------------------------------------------
# _update_sweep — rocks the gaze left and right, or steps through look-around
# -----------------------------------------------------------------------------
func _update_sweep(delta: float) -> void:
	if _looking_around:
		_look_timer += delta
		if _look_timer >= LOOK_STEP_TIME:
			_look_timer = 0.0
			_look_step += 1
			if _look_step >= LOOK_ANGLES.size():
				_look_step      = LOOK_ANGLES.size() - 1
				_looking_around = false
		_sweep_angle = LOOK_ANGLES[_look_step]
	else:
		_sweep_angle += SWEEP_SPEED * _sweep_dir * delta
		if _sweep_angle > SWEEP_ANGLE:
			_sweep_angle = SWEEP_ANGLE
			_sweep_dir   = -1.0
		elif _sweep_angle < -SWEEP_ANGLE:
			_sweep_angle = -SWEEP_ANGLE
			_sweep_dir   = 1.0

# -----------------------------------------------------------------------------
# _cast_rays — fans rays around current gaze angle
# -----------------------------------------------------------------------------
func _cast_rays(delta: float) -> void:
	var sees_ue = false

	if _last_seen_body != null:
		var dist = body.global_position.distance_to(_last_seen_body.global_position)
		if dist < MIN_DISTANCE:
			sees_ue = true

	if not sees_ue:
		var gaze        = facing.rotated(deg_to_rad(_sweep_angle))
		var half_spread = 10.0
		for i in range(RAY_COUNT):
			var t       = float(i) / float(RAY_COUNT - 1) if RAY_COUNT > 1 else 0.0
			var angle   = lerp(-half_spread, half_spread, t)
			var ray_dir = gaze.rotated(deg_to_rad(angle))
			var target  = body.global_position + ray_dir * RAY_LENGTH
			var query   = PhysicsRayQueryParameters2D.create(body.global_position, target)
			query.exclude        = [body]
			query.collision_mask = 1
			var result  = space_state.intersect_ray(query)
			if result and result.collider.is_in_group("ue"):
				sees_ue         = true
				_last_seen_body = result.collider
				break

	if sees_ue:
		_lost_timer = 0.0
		if not _was_seeing_ue:
			_was_seeing_ue = true
			spotted_ue.emit(_last_seen_body)
	else:
		if _was_seeing_ue:
			_lost_timer -= delta
			if _lost_timer <= -LOST_TIMER_MAX:
				_was_seeing_ue  = false
				_lost_timer     = 0.0
				_last_seen_body = null
				lost_ue.emit()

func clear_target() -> void:
	_was_seeing_ue  = false
	_lost_timer     = 0.0
	_last_seen_body = null
