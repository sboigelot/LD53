extends Spatial

class_name MapScene

export(NodePath) var np_map_ui
onready var map_ui = get_node(np_map_ui) as MapUI

export var allow_keyboard_control: bool = true

func get_drone_placeholder():
	return get_node("Drones")
	
func get_building_placeholder():
	return get_node("Buildings")
				
func _ready():
	Game.new_game()
	Game.Map = self
	
	if not allow_keyboard_control:
		Game.Data.start_delivery_phase(not allow_keyboard_control)

func _input(event):
	if allow_keyboard_control and Input.is_action_just_released("ui_accept"):
		if Game.Data.deliver_phase:
			Game.Data.start_delivery_phase()
		else:
			Game.Data.reset_delivery_phase()

func get_stockpile(node_path:NodePath):
	return $Buildings/StockpileNodePathSource.get_node(node_path)
