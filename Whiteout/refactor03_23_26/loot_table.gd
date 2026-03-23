class_name LootTable
extends Node

const RUNE_SCENE = preload("res://scenes/rune.tscn")

@export var runes: Array[RuneData] = []
@export var weights: Array[int] = []
@export var health_component: HealthComponent

func _ready() -> void:
	print(">>> LOOT: LootTable ready, connecting to HealthComponent")
	if health_component:
		health_component.died.connect(_on_died)
	else:
		print(">>> LOOT: ERROR — no HealthComponent assigned!")

func _on_died() -> void:
	print(">>> LOOT: died signal received, dropping at ", get_parent().global_position)
	drop(get_parent().global_position)

func drop(spawn_position: Vector2) -> void:
	if runes.is_empty():
		print(">>> LOOT: runes array is empty!")
		return

	print(">>> LOOT: spawning rune at ", spawn_position)
	var chosen_data = _pick_random()
	print(">>> LOOT: chosen rune — ", chosen_data.rune_name if chosen_data else "NULL DATA")
	var rune = RUNE_SCENE.instantiate()
	rune.data = chosen_data
	get_tree().current_scene.add_child(rune)
	rune.global_position = spawn_position
	print(">>> LOOT: rune added to scene at ", rune.global_position)

func _pick_random() -> RuneData:
	if weights.is_empty() or weights.size() != runes.size():
		return runes[randi() % runes.size()]

	var total = 0
	for w in weights:
		total += w

	var roll = randi() % total
	for i in range(runes.size()):
		roll -= weights[i]
		if roll < 0:
			return runes[i]

	return runes[0]
