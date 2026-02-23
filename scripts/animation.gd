extends Sprite2D

var _last_direction: String = "down"
var _is_moving: bool = false
var _is_attacking: bool = false

func _update_animation():
    if _is_attacking and _is_moving:
        $AnimationPlayer.play("walk_attack_" + _last_direction)
    elif _is_attacking:
        $AnimationPlayer.play("attack_" + _last_direction)
    elif _is_moving:
        $AnimationPlayer.play("walk_" + _last_direction)
    else:
        $AnimationPlayer.play("idle_" + _last_direction)

func _on_direction_input(direction: Vector2):
    _is_moving = direction != Vector2.ZERO
    
    if direction != Vector2.ZERO:
        if abs(direction.x) > abs(direction.y):
            _last_direction = "left" if direction.x < 0 else "right"
        else:
            _last_direction = "up" if direction.y < 0 else "down"
    
    _update_animation()

func _on_attack_input():
    if not _is_attacking:
        _is_attacking = true
        _update_animation()

func _on_animation_finished(_anim_name: String):
    if _is_attacking:
        _is_attacking = false
        _update_animation()


func _ready():
    $AnimationPlayer.animation_finished.connect(_on_animation_finished)
