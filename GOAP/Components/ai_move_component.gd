extends Node

@export var body: CharacterBody2D
@export var agent: NavigationAgent2D
@export var speed := 100

func _physics_process(delta):

	if agent.is_navigation_finished():
		return

	var next_point = agent.get_next_path_position()
	var direction = (next_point - body.global_position).normalized()

	body.velocity = direction * speed
	body.move_and_slide()

func set_target(pos: Vector2):
	agent.target_position = pos
