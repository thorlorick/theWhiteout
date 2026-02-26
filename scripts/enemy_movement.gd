# enemy autonomous movement
# enemy_movement.gd

extends Node

var speed: float = 100.0
var entity: CharacterBody2D = null

func setup(entity_owner: CharacterBody2D) -> void:
    entity = entity_owner
