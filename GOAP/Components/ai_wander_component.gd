extends Node

@export var body: CharacterBody2D
@export var agent: NavigationAgent2D
@export var move_component: Node

@export var radius := 400
@export var delay := 2.0

func _ready():
	wander_loop()

func wander_loop():
	while true:

		await get_tree().create_timer(delay).timeout

		var offset = Vector2(
			randf_range(-radius, radius),
			randf_range(-radius, radius)
		)

		var target = body.global_position + offset
		var safe = NavigationServer2D.map_get_closest_point(
			agent.get_navigation_map(),
			target
		)

		move_component.set_target(safe)
