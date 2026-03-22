class_name AttackComponent
extends Node

# -----------------------------------------------------------------------------
# AttackComponent
# Handles attack timing and cooldowns.
# Knows nothing about health, damage, or what it's hitting.
# Emits attack_landed and lets the orchestrator decide what happens next.
# -----------------------------------------------------------------------------
signal attack_landed(target: Node)

@export var cooldown: float = 1.0  # seconds between attacks

var _timer:          float = 0.0
var _ready_to_attack: bool = true

# -----------------------------------------------------------------------------
# tick — called every frame, counts down cooldown
# -----------------------------------------------------------------------------
func tick(delta: float) -> void:
	if not _ready_to_attack:
		_timer -= delta
		if _timer <= 0.0:
			_ready_to_attack = true
			print(">>> ATTACK: ready")

# -----------------------------------------------------------------------------
# try_attack — attempt a hit, respects cooldown
# does not touch the target — just says "I hit it" and walks away
# -----------------------------------------------------------------------------
func try_attack(target: Node) -> void:
	if not _ready_to_attack:
		return
	if target == null:
		return
	emit_signal("attack_landed", target)
	print(">>> ATTACK: landed")
	_ready_to_attack = false
	_timer = cooldown

# -----------------------------------------------------------------------------
# getters
# -----------------------------------------------------------------------------
func is_ready() -> bool: return _ready_to_attack
