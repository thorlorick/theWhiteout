class_name ZoneComponent
extends Node2D

# -----------------------------------------------------------------------------
# ZoneComponent
# Sits on anything worth protecting — home, treasure, VIP.
# Two concentric zones. If you're not in either, you're clear.
# Fires signals when bodies enter or exit. Knows nothing about who's listening.
# -----------------------------------------------------------------------------

signal body_entered_danger(body: Node2D)
signal body_exited_danger(body: Node2D)
signal body_entered_alert(body: Node2D)
signal body_exited_alert(body: Node2D)

@export var danger_radius: float = 150.0
@export var alert_radius:  float = 400.0

# zone nodes — created at runtime from exported radii
var _danger_zone: Area2D
var _alert_zone:  Area2D

# -----------------------------------------------------------------------------
# _ready — build the two zones programmatically from exported radii
# -----------------------------------------------------------------------------
func _ready() -> void:
	_danger_zone = _build_zone("DangerZone", danger_radius)
	_alert_zone  = _build_zone("AlertZone",  alert_radius)

	_danger_zone.body_entered.connect(_on_danger_entered)
	_danger_zone.body_exited.connect(_on_danger_exited)
	_alert_zone.body_entered.connect(_on_alert_entered)
	_alert_zone.body_exited.connect(_on_alert_exited)

# -----------------------------------------------------------------------------
# _build_zone — creates an Area2D with a circle collision shape
# -----------------------------------------------------------------------------
func _build_zone(zone_name: String, radius: float) -> Area2D:
	var area   = Area2D.new()
	var shape  = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius  = radius
	shape.shape    = circle
	area.name      = zone_name
	area.add_child(shape)
	add_child(area)
	return area

# -----------------------------------------------------------------------------
# signal handlers — forward to our own signals with clean names
# -----------------------------------------------------------------------------
func _on_danger_entered(body: Node2D) -> void:
	body_entered_danger.emit(body)

func _on_danger_exited(body: Node2D) -> void:
	body_exited_danger.emit(body)

func _on_alert_entered(body: Node2D) -> void:
	body_entered_alert.emit(body)

func _on_alert_exited(body: Node2D) -> void:
	body_exited_alert.emit(body)
