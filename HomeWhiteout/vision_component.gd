class_name VisionComponent
extends Node2D

# -----------------------------------------------------------------------------
# VisionComponent
# Eyes that scan the room. Sweep rotates around facing direction.
# When idle, plays a look-around sequence before settling.
# Facing is a Vector2 — no hardwired strings.
# Detection meter fills on evidence, drains on nothing — no flicker.
# Emits signals for alert, confirmed sighting, danger, gap closed, and lost.
# All zone logic is distance-based — no Area2D or collision shapes.
# -----------------------------------------------------------------------------

signal spotted_target(body)
signal lost_target()

signal alert_range(body)
signal danger_range(body)
signal range_lost(body)
signal gap_closed()
signal gap_opened()

# -----------------------------------------------------------------------------
# EXPORTS
# -----------------------------------------------------------------------------
@export_group("Setup")
@export var body:                CharacterBody2D
@export var wall_collision_mask: int   = 1
@export var debug_draw:          bool  = true

@export_group("Rays")
@export var ray_count:           int   = 5
@export var ray_length:          float = 200.0
@export var cone_half_spread:    float = 10.0
@export var head_offset:         float = 12.0

@export_group("Distances")
@export var alert_distance:      float = 150.0
@export var danger_distance:     float = 100.0
@export var strike_distance:     float = 40.0

@export_group("Detection")
@export var alert_threshold:     float = 0.3
@export var fill_rate_center:    float = 2.5
@export var fill_rate_edge:      float = 1.0
@export var drain_rate:          float = 1.5
@export var lost_timer_max:      float = 0.5

@export_group("Sweep")
@export var sweep_angle:         float = 25.0
@export var sweep_speed:         float = 60.0

@export_group("Look Around")
@export var look_angles:         Array = [-40.0, 0.0, 40.0, 0.0]
@export var look_step_time:      float = 0.8

# -----------------------------------------------------------------------------
# INTERNAL STATE
# -----------------------------------------------------------------------------
var facing:       Vector2 = Vector2.DOWN
var space_state:  PhysicsDirectSpaceState2D

var _was_seeing_target: bool   = false
var _lost_timer:        float  = 0.0
var _last_seen_body:    Node2D = null

var _sweep_angle: float = 0.0
var _sweep_dir:   float = 1.0

var _is_moving:      bool  = false
var _look_step:      int   = 0
var _look_timer:     float = 0.0
var _looking_around: bool  = false

var _detection_value:     float = 0.0
var _detection_confirmed: bool  = false

var _gap_closed:      bool = false
var _in_alert_range:  bool = false
var _in_danger_range: bool = false

# -----------------------------------------------------------------------------
# READY
# -----------------------------------------------------------------------------
func _ready() -> void:
	space_state = get_world_2d().direct_space_state

func _physics_process(delta: float) -> void:
	_update_sweep(delta)
	_cast_rays(delta)

# -----------------------------------------------------------------------------
# apply_awareness — called by GuardAgent when personality is assigned
# translates 0-10 awareness score into vision behaviour via lerp
# leave distances, threshold, sweep_angle, and look_around alone —
# those are level design decisions, not guard sharpness
# -----------------------------------------------------------------------------
func apply_awareness(a: int) -> void:
	var t = a / 10.0

	ray_count        = int(lerp(3.0,  11.0, t))
	ray_length       = lerp(120.0, 280.0, t)
	cone_half_spread = lerp(6.0,   18.0,  t)
	fill_rate_center = lerp(1.0,   4.0,   t)
	fill_rate_edge   = lerp(0.5,   2.0,   t)
	drain_rate       = lerp(2.5,   0.5,   t)
	lost_timer_max   = lerp(0.2,   1.2,   t)
	sweep_speed      = lerp(30.0,  80.0,  t)

# -----------------------------------------------------------------------------
# update_direction — called by GuardAgent when velocity_changed fires
# -----------------------------------------------------------------------------
func update_direction(direction: Vector2, is_moving: bool, is_running: bool) -> void:
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
# _update_sweep
# Priority order:
#   1. Actively seeing target  — lock gaze onto them, no sweep
#   2. Look-around sequence    — only when idle and not tracking
#   3. Default back-and-forth  — normal patrol sweep
# -----------------------------------------------------------------------------
func _update_sweep(delta: float) -> void:
	# 1. Seeing target — track them directly, ignore everything else
	if _was_seeing_target or _detection_confirmed:
		if _last_seen_body != null:
			var to_target    = (_last_seen_body.global_position - body.global_position).normalized()
			var facing_angle = rad_to_deg(facing.angle())
			var target_angle = rad_to_deg(to_target.angle())
			var desired      = target_angle - facing_angle
			_sweep_angle     = move_toward(_sweep_angle, desired, sweep_speed * delta * 3.0)
		return

	# 2. Look-around when freshly stopped
	if _looking_around:
		_look_timer += delta
		if _look_timer >= look_step_time:
			_look_timer = 0.0
			_look_step  += 1
			if _look_step >= look_angles.size():
				_look_step      = look_angles.size() - 1
				_looking_around = false
		_sweep_angle = move_toward(_sweep_angle, look_angles[_look_step], sweep_speed * delta)
		return

	# 3. Default patrol sweep
	_sweep_angle += sweep_speed * _sweep_dir * delta
	if _sweep_angle > sweep_angle:
		_sweep_angle = sweep_angle
		_sweep_dir   = -1.0
	elif _sweep_angle < -sweep_angle:
		_sweep_angle = -sweep_angle
		_sweep_dir   =  1.0

# -----------------------------------------------------------------------------
# _cast_rays
# -----------------------------------------------------------------------------
func _cast_rays(delta: float) -> void:
	var hits:      int   = 0

	# offset ray origin to head position
	var ray_origin = body.global_position + facing * head_offset

	var gaze = facing.rotated(deg_to_rad(_sweep_angle))
	for i in range(ray_count):
		var t       = float(i) / float(ray_count - 1) if ray_count > 1 else 0.0
		var angle   = lerp(-cone_half_spread, cone_half_spread, t)
		var ray_dir = gaze.rotated(deg_to_rad(angle))
		var target  = ray_origin + ray_dir * ray_length
		var query   = PhysicsRayQueryParameters2D.create(ray_origin, target)
		query.exclude        = [body]
		query.collision_mask = wall_collision_mask
		var result  = space_state.intersect_ray(query)
		if result and result.collider.is_in_group("player"):
			hits += 1
			_last_seen_body = result.collider

	if hits > 0:
		# cancel look-around immediately so sweep priority 1 can take over
		_looking_around = false

		var fill_rate = lerp(fill_rate_edge, fill_rate_center, float(hits) / float(ray_count))
		_detection_value = min(1.0, _detection_value + fill_rate * delta)

		# distance always measured from body center, not head
		var dist = body.global_position.distance_to(_last_seen_body.global_position)

		if _detection_value >= alert_threshold and not _in_alert_range:
			_in_alert_range = true
			print(">>> VISION: alert range entered")
			alert_range.emit(_last_seen_body)

		if _detection_value >= 1.0 and not _detection_confirmed:
			_detection_confirmed = true
			_was_seeing_target   = true
			_lost_timer          = lost_timer_max
			spotted_target.emit(_last_seen_body)

		if _was_seeing_target:
			_lost_timer = lost_timer_max

		if _detection_confirmed and dist <= danger_distance and not _in_danger_range:
			_in_danger_range = true
			print(">>> VISION: danger range entered")
			danger_range.emit(_last_seen_body)

		if _was_seeing_target and dist <= strike_distance and not _gap_closed:
			_gap_closed = true
			print(">>> VISION: gap closed — strike distance reached")
			gap_closed.emit()
			
		if _was_seeing_target and dist > strike_distance and _gap_closed:
			_gap_closed = false
			print(">>> VISION: gap opened — player moved away")
			gap_opened.emit()

	else:
		_detection_value = max(0.0, _detection_value - drain_rate * delta)
		
		

		if _was_seeing_target:
			_lost_timer -= delta
			if _lost_timer <= 0.0:
				_was_seeing_target   = false
				_detection_confirmed = false
				_detection_value     = 0.0
				_lost_timer          = 0.0
				_gap_closed          = false
				_in_alert_range      = false
				_in_danger_range     = false
				print(">>> VISION: range lost")
				range_lost.emit(_last_seen_body)
				_last_seen_body = null
				lost_target.emit()

		elif _detection_value <= 0.0 and _in_alert_range:
			_in_alert_range  = false
			_in_danger_range = false
			print(">>> VISION: partial sighting lost — resetting zones")
			range_lost.emit(_last_seen_body)
			_last_seen_body = null

# -----------------------------------------------------------------------------
# dealing with lost targets
# -----------------------------------------------------------------------------
func on_target_lost() -> void:
	_gap_closed = false
	_in_alert_range = false
	_in_danger_range = false

func on_danger_entered() -> void:
	_in_danger_range = true

func on_alert_entered() -> void:
	_in_alert_range = true

func on_range_lost() -> void:
	_in_alert_range = false
	_in_danger_range = false

# -----------------------------------------------------------------------------
# clear_target
# -----------------------------------------------------------------------------
func clear_target() -> void:
	_was_seeing_target   = false
	_detection_confirmed = false
	_detection_value     = 0.0
	_lost_timer          = 0.0
	_last_seen_body      = null
	_gap_closed          = false
	_in_alert_range      = false
	_in_danger_range     = false

# -----------------------------------------------------------------------------
# DEBUG DRAW
# -----------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if debug_draw:
		queue_redraw()

func _draw() -> void:
	if not debug_draw:
		return
	if body == null:
		return

	var offset = body.global_position - global_position

	_draw_distance_rings(offset)
	_draw_cone(offset)
	_draw_detection_meter(offset)
	_draw_target_marker(offset)

func _draw_distance_rings(offset: Vector2) -> void:
	draw_arc(offset, alert_distance,  0, TAU, 32, Color(1.0, 1.0, 0.0, 0.25), 1.0)
	draw_arc(offset, danger_distance, 0, TAU, 32, Color(1.0, 0.5, 0.0, 0.35), 1.0)
	draw_arc(offset, strike_distance, 0, TAU, 32, Color(1.0, 0.0, 0.0, 0.45), 1.0)

func _draw_cone(offset: Vector2) -> void:
	var t     = _detection_value
	var color = Color(t, 1.0 - t, 0.0, 0.45)

	# draw cone from head position, same as rays
	var head = offset + facing * head_offset
	var gaze = facing.rotated(deg_to_rad(_sweep_angle))

	for i in range(ray_count):
		var pct     = float(i) / float(ray_count - 1) if ray_count > 1 else 0.0
		var angle   = lerp(-cone_half_spread, cone_half_spread, pct)
		var ray_dir = gaze.rotated(deg_to_rad(angle))
		var end     = head + ray_dir * ray_length
		draw_line(head, end, color, 1.5)

	var left_dir   = gaze.rotated(deg_to_rad(-cone_half_spread))
	var right_dir  = gaze.rotated(deg_to_rad( cone_half_spread))
	var edge_color = Color(color.r, color.g, color.b, 0.8)
	draw_line(head, head + left_dir  * ray_length, edge_color, 1.0)
	draw_line(head, head + right_dir * ray_length, edge_color, 1.0)

func _draw_detection_meter(offset: Vector2) -> void:
	var bar_width  = 30.0
	var bar_height = 4.0
	var bar_origin = offset + Vector2(-bar_width * 0.5, -28.0)

	draw_rect(Rect2(bar_origin, Vector2(bar_width, bar_height)), Color(0, 0, 0, 0.5))
	if _detection_value > 0.0:
		var t     = _detection_value
		var color = Color(t, 1.0 - t, 0.0, 0.85)
		draw_rect(Rect2(bar_origin, Vector2(bar_width * _detection_value, bar_height)), color)
	draw_line(
		bar_origin + Vector2(bar_width * alert_threshold, 0),
		bar_origin + Vector2(bar_width * alert_threshold, bar_height),
		Color(1, 1, 1, 0.6), 1.0
	)

func _draw_target_marker(offset: Vector2) -> void:
	if _last_seen_body == null:
		return
	var target_offset = _last_seen_body.global_position - global_position
	var color = Color(1, 0, 0, 0.9) if _detection_confirmed else Color(1, 1, 0, 0.7)
	draw_circle(target_offset, 5.0, color)
	draw_line(offset, target_offset, Color(color.r, color.g, color.b, 0.4), 1.0)
