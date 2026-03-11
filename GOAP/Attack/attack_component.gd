class_name AttackComponent
# -----------------------------------------------------------------------------
# AttackComponent
# Handles attack timing and cooldowns.
# Deals damage to a HealthComponent.
# Knows nothing about movement or range — that's the caller's job.
# -----------------------------------------------------------------------------
signal attack_landed(target: Node)

@export var damage:   float = 10.0
@export var cooldown: float = 1.0  # seconds between attacks

var _timer: float = 0.0
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
# try_attack — attempt to hit a target, respects cooldown
# -----------------------------------------------------------------------------
func try_attack(target: Node) -> void:
	if not _ready_to_attack:
		return
	if not target.has_method("take_damage"):
		return
	target.take_damage(damage)
	emit_signal("attack_landed", target)
	print(">>> ATTACK: hit for %.1f damage" % damage)
	_ready_to_attack = false
	_timer = cooldown

# -----------------------------------------------------------------------------
# getters
# -----------------------------------------------------------------------------
func is_ready() -> bool: return _ready_to_attack
