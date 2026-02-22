extends CharacterBody2D

var current_direction: String = ""
var stats

func _ready():
	stats = $Stats
	var movement = $Movement

	# Connect its signal to our function below
	movement.direction_input.connect(_on_direction_input)

func _on_direction_input(direction: String):
	# Store whichever direction was received
	current_direction = direction

func _physics_process(delta):
	# Reset velocity each frame
	velocity = Vector2.ZERO

	# Set velocity based on the current direction
	if current_direction == "left":
		velocity.x = -stats.speed
	elif current_direction == "right":
		velocity.x = stats.speed
	elif current_direction == "up":
		velocity.y = -stats.speed
	elif current_direction == "down":
		velocity.y = stats.speed

	# Actually move the character
	move_and_slide()
	
	# Reset direction so player stops when no key is held
	current_direction = ""
