class_name DetectionComponent
extends Node
# -----------------------------------------------------------------------------
# DetectionComponent
# A generic fill/drain meter with a confirmation threshold.
# Knows nothing about vision, sound, or anything else.
# Feed it evidence via fill(). Starve it via drain().
# It fires signals when full or empty — that's all it does.
# -----------------------------------------------------------------------------
signal confirmed	# meter hit 1.0
signal lost      	# meter drained to 0.0

const THRESHOLD: float = 1.0  # full
const EMPTY:     float = 0.0  # empty

var _value: float = 0.0
var _was_confirmed: bool = false

# -----------------------------------------------------------------------------
# fill — add evidence, clamp to 1.0
# -----------------------------------------------------------------------------
func fill(amount: float) -> void:
	_value = min(THRESHOLD, _value + amount)
	if _value >= THRESHOLD and not _was_confirmed:
		_was_confirmed = true
		confirmed.emit()

# -----------------------------------------------------------------------------
# drain — remove evidence, clamp to 0.0
# -----------------------------------------------------------------------------
func drain(amount: float) -> void:
	_value = max(EMPTY, _value - amount)
	if _value <= EMPTY and _was_confirmed:
		_was_confirmed = false
		lost.emit()

# -----------------------------------------------------------------------------
# reset — hard clear, no signals
# -----------------------------------------------------------------------------
func reset() -> void:
	_value         = 0.0
	_was_confirmed = false

# -----------------------------------------------------------------------------
# get_value — read the meter
# -----------------------------------------------------------------------------
func get_value() -> float:
	return _value
