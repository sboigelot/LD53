extends Spatial

class_name MapScene

export(NodePath) var np_map_ui
onready var map_ui = get_node(np_map_ui) as MapUI

func get_drone_placeholder():
	return get_node("Drones")
	
func get_building_placeholder():
	return get_node("Buildings")

func _ready():
	Game.Map = self

func get_stockpile(node_path:NodePath):
	return $Buildings/StockpileNodePathSource.get_node(node_path)
