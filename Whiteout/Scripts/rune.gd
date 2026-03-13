extends Area2D
class_name Rune

@export var data: RuneData

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	call_deferred("_play_drop_animation")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	print(">>> RUNE: collected ", data.rune_name if data else "unknown")
	queue_free()

func _play_drop_animation() -> void:
	modulate.a = 0.0
	scale = Vector2(0.3, 0.3)

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "position:y", position.y - 20, 0.15)
	tween.chain().tween_property(self, "position:y", position.y, 0.2)\
		.set_ease(Tween.EASE_IN)

	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)\
		.set_trans(Tween.TRANS_ELASTIC)

	tween.chain().tween_callback(_start_bob)

func _start_bob() -> void:
	var bob = create_tween()
	bob.set_loops()
	bob.tween_property(self, "position:y", position.y - 5, 0.6)\
		.set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(self, "position:y", position.y, 0.6)\
		.set_ease(Tween.EASE_IN_OUT)
