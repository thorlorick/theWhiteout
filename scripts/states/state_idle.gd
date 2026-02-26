# state_idle.gd
extends FSMStateBase

var idle_timer: float = 0.0
const IDLE_DURATION: float = 2.0

func enter(entity_owner) -> void:
    super.enter(entity_owner)
    idle_timer = 0.0

func update(delta: float) -> void:
    idle_timer += delta
    if idle_timer >= IDLE_DURATION:
        transition_requested.emit("Patrol")
