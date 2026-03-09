class_name AnxietyComponent

signal replan_please    # patrol urge strong enough — time to leave home
signal threat_detected  # UE moved into a new zone — recheck priorities
signal homesick         # home anxiety strong enough — time to go back

# home anxiety
var home_anxiety: float   = 0.0
var home_bonus: float     = 0.0
# patrol anxiety
var patrol_anxiety: float = 0.0
var patrol_bonus: float   = 0.0
# chase anxiety — distance does all the work, no bonus
var chase_anxiety: float  = 0.0

# rates — how fast anxieties build and bonuses fade
const HOME_ANXIETY_RATE:   float = 0.022
const PATROL_ANXIETY_RATE: float = 0.08
const BONUS_AMOUNT:        float = 0.3
const BONUS_DECAY:         float = 0.0005

# threat zones — all measured as UE distance TO HOME, not to Joe
const OUTER_ZONE:  float = 300.0
const MIDDLE_ZONE: float = 200.0
const INNER_ZONE:  float = 100.0
const STRIKE_ZONE: float = 50.0

# thresholds — when to shout
const PATROL_THRESHOLD:   float = 0.3
const HOMESICK_THRESHOLD: float = 0.35

# latches — prevent signal spam
var _patrol_latch:   bool = false
var _homesick_latch: bool = false
var _current_zone:   int  = -1

# called every frame when guard is at home
func tick_home(delta: float) -> void:
	# patrol_anxiety += PATROL_ANXIETY_RATE * delta
	home_bonus = max(0.0, home_bonus - BONUS_DECAY * delta)
	patrol_bonus    = max(0.0, patrol_bonus - BONUS_DECAY * delta)
	print(">>> URGES — home: %.2f | patrol: %.2f | chase: %.2f" % [
		get_home_priority(),
		get_patrol_priority(),
		get_chase_priority()
	])
	if not _patrol_latch and get_patrol_priority() >= PATROL_THRESHOLD:
		_patrol_latch = true
		print(">>> ANXIETY: patrol urge strong enough — requesting replan")
		replan_please.emit()

# called every frame when guard is patrolling
func tick_patrol(delta: float) -> void:
	home_anxiety  += HOME_ANXIETY_RATE * delta
	patrol_anxiety = max(0.0, patrol_anxiety - PATROL_ANXIETY_RATE * delta)
	patrol_bonus   = max(0.0, patrol_bonus - BONUS_DECAY * delta)
	print(">>> URGES — home: %.2f | patrol: %.2f | chase: %.2f" % [
		get_home_priority(),
		get_patrol_priority(),
		get_chase_priority()
	])
	if not _homesick_latch and get_home_priority() >= HOMESICK_THRESHOLD:
		_homesick_latch = true
		print(">>> ANXIETY: homesick — requesting replan")
		homesick.emit()

# called every frame when guard is chasing
# distance is UE-to-home, not Joe-to-UE
func tick_chase(delta: float, distance: float) -> void:
	home_anxiety += HOME_ANXIETY_RATE * delta
	print(">>> URGES — home: %.2f | patrol: %.2f | chase: %.2f" % [
		get_home_priority(),
		get_patrol_priority(),
		get_chase_priority()
	])
	var new_zone: int
	if distance >= OUTER_ZONE:
		new_zone = -1
		chase_anxiety = 0.0
	elif distance >= MIDDLE_ZONE:
		new_zone = 0
		chase_anxiety = 0.3
	elif distance >= INNER_ZONE:
		new_zone = 1
		chase_anxiety = 0.6
	else:
		new_zone = 2
		chase_anxiety = 0.9

	if new_zone != _current_zone:
		_current_zone = new_zone
		match new_zone:
			-1: print(">>> CHASE: UE outside outer zone — not a threat (%.1f)" % distance)
			0:  print(">>> CHASE: UE entered outer zone — watching (%.1f)" % distance)
			1:  print(">>> CHASE: UE entered middle zone — moving to intercept (%.1f)" % distance)
			2:  print(">>> CHASE: UE entered inner zone — HOME THREATENED (%.1f)" % distance)
		threat_detected.emit()

# guard arrives home — everything resets, satisfaction bonus
func arrive_home() -> void:
	home_anxiety    = 0.0
	home_bonus      = BONUS_AMOUNT
	patrol_anxiety  = 0.0
	chase_anxiety   = 0.0
	_patrol_latch   = false
	_homesick_latch = false
	_current_zone   = -1
	print(">>> ANXIETY: arrived home — fully reset, home bonus applied")

# guard commits to patrol from home — home anxiety resets, patrol bonus applied
func arrive_on_patrol() -> void:
	patrol_bonus    = BONUS_AMOUNT
	home_anxiety    = 0.0
	home_bonus     = 0.0  
	_homesick_latch = false
	print(">>> ANXIETY: committed to patrol — home anxiety cleared, patrol bonus applied")

# already patrolling — just reset the homesick latch so it can fire again
func resume_patrol() -> void:
	_homesick_latch = false
	print(">>> ANXIETY: resuming patrol — homesick latch reset")

# UE spotted — no artificial spike, let distance do the work naturally
func spotted_ue() -> void:
	chase_anxiety = 0.0
	_current_zone = -1
	print(">>> ANXIETY: UE spotted — letting distance drive chase priority")

# UE lost — clear chase state, fresh start on all latches
func lost_ue() -> void:
	chase_anxiety   = 0.0
	_current_zone   = -1
	_homesick_latch = false
	_patrol_latch   = false
	patrol_bonus    = BONUS_AMOUNT
	print(">>> ANXIETY: UE lost — chase cleared, patrol bonus applied")

# priority getters
func get_home_priority() -> float:
	return clamp(home_anxiety + home_bonus, 0.0, 1.0)
func get_patrol_priority() -> float:
	return clamp(patrol_anxiety + patrol_bonus, 0.0, 1.0)
func get_chase_priority() -> float:
	return clamp(chase_anxiety, 0.0, 1.0)
