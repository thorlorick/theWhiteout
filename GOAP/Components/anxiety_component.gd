class_name AnxietyComponent

var patrol_anxiety: float = 0.0
var home_anxiety: float = 0.0
var home_bonus: float = 0.0
var patrol_bonus: float = 0.0

const PATROL_ANXIETY_RATE: float = 0.005
const HOME_ANXIETY_RATE: float = 0.008
const BONUS_AMOUNT: float = 0.2
const BONUS_DECAY: float = 0.003

func tick(delta: float, at_home: bool) -> void:
	if at_home:
		patrol_anxiety += PATROL_ANXIETY_RATE * delta
		home_bonus = max(0.0, home_bonus - BONUS_DECAY * delta)
	else:
		home_anxiety += HOME_ANXIETY_RATE * delta
		patrol_bonus = max(0.0, patrol_bonus - BONUS_DECAY * delta)

func arrive_home() -> void:
	home_bonus = BONUS_AMOUNT
	patrol_anxiety = 0.0

func arrive_on_patrol() -> void:
	patrol_bonus = BONUS_AMOUNT
	home_anxiety = 0.0

func get_home_priority() -> float:
	return clamp(home_anxiety + home_bonus, 0.0, 1.0)

func get_patrol_priority() -> float:
	return clamp(patrol_anxiety + patrol_bonus, 0.0, 1.0)
