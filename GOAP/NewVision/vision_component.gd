class_name VisionComponent
extends Node2D
# -----------------------------------------------------------------------------
# VisionComponent
# Eyes that scan the room. Sweep rotates around facing direction.
# When idle, plays a look-around sequence before settling.
# Facing is a Vector2 — no hardwired strings.
# Detection is confirmed via a fill meter — no flicker false positives.
# -----------------------------------------------------------------------------
signal spotted_ue(body)
signal lost_ue()

const RAY_COUNT:       int   = 5
const RAY_LENGTH:      float = 200.0
const LOST_TIMER_MAX:  float = 0.5
const MIN_DISTANCE:    float = 30.0

# sweep
const SWEEP_ANGLE:     float = 25.0
const SWEEP_SPEED:     float = 60.0

# look-around sequence when idle
const LOOK_ANGLES:     Array = [-40.0, 0.0, 40.0, 0.0]
const LOOK_STEP_TIME:  float = 0.8

# detection fill rates — how fast the meter fills per ray hit per frame
const FILL_RATE_CENTER:  float = 2.5   # dead centre of cone
const FILL_RATE_EDGE:    float = 1.0   # edge of cone
const DRAIN_RATE:        float = 1.5   # drains when nothing seen

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

# gaze homing — pulls cone toward last flicker
var _gaze_target_angle: float = 0.0   # angle offset we are homing toward
var _homing:            bool  = false  # are we currently homing?

# detection meter
var _detection:      DetectionComponent = DetectionComponent.new()

@export var body: CharacterBody2D

func _ready() -> void:
	space_state = get_world_2d().direct_space_state
	add_child(_detection)
	_detection.confirmed.connect(_on_detection_confirmed)
	_detection.lost.connect(_on_detection_lost)

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

	if was_moving and not is_moving:
		_looking_around = true
		_look_step      = 0
		_look_timer     = 0.0

# -----------------------------------------------------------------------------
# _update_sweep — rocks gaze, homes toward flicker, or steps look-around
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
		return

	if _homing:
		# smoothly rotate sweep toward the flicker angle
		var diff = _gaze_target_angle - _sweep_angle
		_sweep_angle += diff * delta * 5.0
		# close enough — lock on
		if abs(diff) < 1.0:
			_sweep_angle = _gaze_target_angle
		return

	# normal lazy sweep
	_sweep_angle += SWEEP_SPEED * _sweep_dir * delta
	if _sweep_angle > SWEEP_ANGLE:
		_sweep_angle = SWEEP_ANGLE
		_sweep_dir   = -1.0
	elif _sweep_angle < -SWEEP_ANGLE:
		_sweep_angle = -SWEEP_ANGLE
		_sweep_dir   = 1.0

# -----------------------------------------------------------------------------
# _cast_rays — fans rays, feeds detection meter based on hits
# -----------------------------------------------------------------------------
func _cast_rays(delta: float) -> void:
	var hits:       int   = 0
	var hit_body:   Node2D = null
	var hit_angle:  float = 0.0
	var half_spread: float = 10.0

	# minimum distance — always seen if very close
	if _last_seen_body != null:
		var dist = body.global_position.distance_to(_last_seen_body.global_position)
		if dist < MIN_DISTANCE:
			hits     = RAY_COUNT
			hit_body = _last_seen_body

	if hits == 0:
		var gaze = facing.rotated(deg_to_rad(_sweep_angle))
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
				hits      += 1
				hit_body   = result.collider
				hit_angle  = lerp(-half_spread, half_spread, t)
				_last_seen_body = result.collider

	if hits > 0:
		# home the gaze toward the flicker
		_homing           = true
		_gaze_target_angle = _sweep_angle + hit_angle

		# fill rate based on how many rays hit — more hits = more certain
		var fill_rate = lerp(FILL_RATE_EDGE, FILL_RATE_CENTER, float(hits) / float(RAY_COUNT))
		_detection.fill(fill_rate * delta)
	else:
		# nothing seen — drain and stop homing if not confirmed
		if not _was_seeing_ue:
			_homing = false
		_detection.drain(DRAIN_RATE * delta)

	# lost timer — confirmed sighting that fades
	if _was_seeing_ue:
		if hits == 0:
			_lost_timer -= delta
			if _lost_timer <= -LOST_TIMER_MAX:
				_was_seeing_ue  = false
				_lost_timer     = 0.0
				_last_seen_body = null
				_homing         = false
				lost_ue.emit()
		else:
			_lost_timer = 0.0

# -----------------------------------------------------------------------------
# _on_detection_confirmed — meter hit 1.0 — fire spotted signal
# -----------------------------------------------------------------------------
func _on_detection_confirmed() -> void:
	if not _was_seeing_ue:
		_was_seeing_ue = true
		_lost_timer    = 0.0
		if _last_seen_body != null:
			spotted_ue.emit(_last_seen_body)

# -----------------------------------------------------------------------------
# _on_detection_lost — meter drained — nothing there
# -----------------------------------------------------------------------------
func _on_detection_lost() -> void:
	pass  # lost_ue fires via the lost timer above, not here

func clear_target() -> void:
	_was_seeing_ue  = false
	_lost_timer     = 0.0
	_last_seen_body = null
	_homing         = false
	_detection.reset()
