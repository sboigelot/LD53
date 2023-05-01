extends Node

class_name GameData

export var player_name:String = "Player"

export var money:int = 200
export var day:int = 1

export var deliver_phase:bool = false
export var deliver_phase_duration_seconds:float = 60.0
export var deliver_phase_infinite: bool = false
export var deliver_phase_timer: float = 0.0
export var deliver_phase_speed: float = 1.0
var pre_start_delivery_phase_money:int

var game_goal_factories: Array
var daily_deliveries: Array
var daily_money_benefits: Array

var build_tutorial_shown:bool = false
var tutorial_steps = [
	"click_me_drone",
	"add_step",
	"pick_target",
	"click_me_water_tower",
	"add_step",
	"change_deliver",
	"pick_target",
	"click_me_farm",
	"start_day",
	"victory_info"
]

func is_tutorial_step(step_name:String) -> bool:
	if tutorial_steps.size() == 0:
		return false
		
	return tutorial_steps[0] == step_name
	
func complete_tutorial_step(step_name:String):
	if is_tutorial_step(step_name):
		tutorial_steps.remove(0)

func start_delivery_phase(infinite:bool = false):
	complete_tutorial_step("start_day")
	deliver_phase_infinite = infinite
	deliver_phase_timer = 0.0
	deliver_phase_speed = 1.0
	deliver_phase = true
	pre_start_delivery_phase_money = money
	daily_deliveries.append({})
	daily_deliveries[day - 1]["water"] = 0
	daily_deliveries[day - 1]["vegetable"] = 0
	daily_deliveries[day - 1]["salad"] = 0
	daily_deliveries[day - 1]["meat"] = 0
	daily_deliveries[day - 1]["burger"] = 0
	daily_money_benefits.append(0)
	
	for factory in game_goal_factories:
		factory.reset_goals()
	
func reset_delivery_phase():
	deliver_phase_timer = 0.0
	deliver_phase_speed = 1.0
	deliver_phase = false
	money = pre_start_delivery_phase_money
	daily_deliveries.remove(day - 1)
	daily_money_benefits.remove(day - 1)
	
func get_total_goals_count(cargo_type:String) -> int:
	var total = 0
	for factory in game_goal_factories:
		var input:Stockpile = factory.sp_input_stockpile
		if input == null:
			continue
		if input.cargo_type != cargo_type:
			continue
		total += factory.get_total_goals_count()
	return total

func get_completed_goals_count(cargo_type:String) -> int:
	var total = 0
	for factory in game_goal_factories:
		var input:Stockpile = factory.sp_input_stockpile
		if input == null:
			continue
		if input.cargo_type != cargo_type:
			continue
		total += factory.get_completed_goals_count()
	return total
	
func _process(delta):
	if deliver_phase and not deliver_phase_infinite:
		deliver_phase_timer += (delta * deliver_phase_speed)
		if deliver_phase_timer >= deliver_phase_duration_seconds:
			complete_day()

func add_money(count:int):
	daily_money_benefits[day - 1] += count
	money += count
	
	if not build_tutorial_shown and money >= 300:
		tutorial_steps.append("build_on_land")

func register_day_delivery(cargo:String, count:int):
	var day_delivery = daily_deliveries[day - 1]
	if day_delivery.has(cargo):
		day_delivery[cargo] += count
	else:
		day_delivery[cargo] = count
		
	Game.Map.map_ui.update_goal_labels()
	
func get_delivery_count(cargo:String) -> int:
	if daily_deliveries.size() == 0:
		return 0
	var day_delivery = daily_deliveries[day - 1]
	if day_delivery.has(cargo):
		return day_delivery[cargo]
	return 0

func complete_day():
	deliver_phase_timer = 0.0
	deliver_phase_speed = 1.0
	deliver_phase = false
	day += 1
	Game.Map.map_ui.show_end_of_day_report(day - 1)

func register_game_goal(factory:Factory):
	if not game_goal_factories.has(factory):
		game_goal_factories.append(factory)
		Game.Map.map_ui.update_goal_labels()
