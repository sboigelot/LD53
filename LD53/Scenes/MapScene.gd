extends Spatial

class_name MapScene

func _ready():
	Game.Map = self

func get_stockpile(node_path:NodePath):
	return $Buildings/StockpileNodePathSource.get_node(node_path)