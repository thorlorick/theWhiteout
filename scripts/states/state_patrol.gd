# state_patrol.gd
extends FSMStateBase

var patrol_timer: float = 0.0
const PATROL_DURATION: float = 3.0

func enter(owner) -> void:
    super.enter(owner)
    patrol_timer = 0.0
    print("Entering Patrol")

func exit() -> void:
    print("Exiting Patrol")

func update(delta: float) -> void:
    patrol_timer += delta
    print("Patrolling... ", snapped(patrol_timer, 0.1))
    if patrol_timer >= PATROL_DURATION:
        transition_requested.emit("Idle")
