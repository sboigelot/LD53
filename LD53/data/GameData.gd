extends Node

class_name GameData

export var player_name:String = "Player"

export var money:int = 200
export var day:int = 1

export var deliver_phase:bool = false
export var deliver_phase_duration_seconds:float = 60.0
export var deliver_phase_timer: float = 0.0
export var deliver_phase_speed: float = 1.0
var pre_start_delivery_phase_money:int

func start_delivery_phase():
	deliver_phase_timer = 0.0
	deliver_phase_speed = 1.0
	deliver_phase = true
	pre_start_delivery_phase_money = money
	
func reset_delivery_phase():
	deliver_phase_timer = 0.0
	deliver_phase_speed = 1.0
	deliver_phase = false
	money = pre_start_delivery_phase_money
	
func _process(delta):
	if deliver_phase:
		deliver_phase_timer += (delta * deliver_phase_speed)
		if deliver_phase_timer >= deliver_phase_duration_seconds:
			day += 1
			deliver_phase = false

