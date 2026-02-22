extends CharacterBody2D
var current_direction: Vector2 = Vector2.ZERO
var stats

func _ready():
    stats = $Stats
    var movement = $Movement
    movement.direction_input.connect(_on_direction_input)

func _on_direction_input(direction: Vector2):
    current_direction = direction

func _physics_process(delta):
    velocity = current_direction * stats.speed
    move_and_slide()
    current_direction = Vector2.ZERO
