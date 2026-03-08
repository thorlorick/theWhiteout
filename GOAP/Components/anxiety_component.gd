class_name AnxietyComponent

# home anxiety
var home_anxiety: float  = 0.0
var home_bonus: float    = 0.0
# patrol anxiety
var patrol_anxiety: float = 0.0
var patrol_bonus: float   = 0.0
# chase anxiety
var chase_anxiety: float  = 0.0
var chase_bonus: float    = 0.0

# rates
const HOME_ANXIETY_RATE:   float = 0.008
const PATROL_ANXIETY_RATE: float = 0.005
const CHASE_BONUS_AMOUNT:  float = 0.8
const CHASE_BONUS_DECAY:   float = 0.006
const BONUS_AMOUNT:        float = 0.2
const BONUS_DECAY:         float = 0.003
const MAX_CHASE_DISTANCE:  float = 200.0

# called every frame when guard is at home
func tick_home(delta: float) -> void:
	patrol_anxiety += PATROL_ANXIETY_RATE * delta
	home_bonus = max(0.0, home_bonus - BONUS_DECAY * delta)

# called every frame when guard is patrolling
func tick_patrol(delta: float) -> void:
	home_anxiety += HOME_ANXIETY_RATE * delta
	patrol_bonus = max(0.0, patrol_bonus - BONUS_DECAY * delta)

# called every frame when guard is chasing — distance drives urgency
func tick_chase(delta: float, distance: float) -> void:
	home_anxiety += HOME_ANXIETY_RATE * delta
	chase_bonus = max(0.0, chase_bonus - CHASE_BONUS_DECAY * delta)
	# closer = higher anxiety to close the gap
	chase_anxiety = 1.0 - clamp(distance / MAX_CHASE_DISTANCE, 0.0, 1.0)

# guard arrives home — reset patrol anxiety, give home satisfaction bonus
func arrive_home() -> void:
	home_bonus     = BONUS_AMOUNT
	patrol_anxiety = 0.0
	chase_anxiety  = 0.0
	chase_bonus    = 0.0

# guard commits to patrol — reset home anxiety, give patrol satisfaction bonus
func arrive_on_patrol() -> void:
	patrol_bonus  = BONUS_AMOUNT
	home_anxiety  = 0.0

# UE spotted — adrenaline spike on chase priority
# NOTE: we no longer set chase_anxiety = 1.0 here
# chase_anxiety is now driven purely by distance in tick_chase()
# the chase_bonus alone is enough to spike priority immediately
func spotted_ue() -> void:
	chase_bonus   = CHASE_BONUS_AMOUNT   # big immediate spike
	chase_anxiety = 0.0                  # let distance drive this naturally

# UE lost — clear chase state, reward patrol for continuing
func lost_ue() -> void:
	chase_anxiety = 0.0
	chase_bonus   = 0.0
	patrol_bonus  = BONUS_AMOUNT         # back on the job

# priority getters — used by EnemyAgent to set goal priorities
func get_home_priority() -> float:
	return clamp(home_anxiety + home_bonus, 0.0, 1.0)

func get_patrol_priority() -> float:
	return clamp(patrol_anxiety + patrol_bonus, 0.0, 1.0)

func get_chase_priority() -> float:
	return clamp(chase_anxiety + chase_bonus, 0.0, 1.0)
