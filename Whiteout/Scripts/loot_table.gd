extends Node
class_name LootTable

const RUNE_SCENE = preload("res://scenes/rune.tscn")

@export var runes: Array[RuneData] = []
@export var weights: Array[int] = []

func drop(spawn_position: Vector2) -> void:
    if runes.is_empty():
        return

    var chosen_data = _pick_random()
    var rune = RUNE_SCENE.instantiate()
    rune.data = chosen_data
    get_tree().current_scene.add_child(rune)
    rune.global_position = spawn_position

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
