extends node

@onready var detection_zone = $DetectionZone

enum State { IDLE, PATROL, CHASE, ATTACK }

var current_state = State.IDLE

func _physics_process(delta):
    match current_state:
        State.IDLE:
            handle_idle()
        State.PATROL:
            handle_patrol()
        State.CHASE:
            handle_chase()
        State.ATTACK:
            handle_attack()

