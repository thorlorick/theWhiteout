extends Node2D

enum State { IDLE, PATROL, CHASE, ATTACK }

var current_state = State.IDLE
var target = null

