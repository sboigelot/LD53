extends Resource

class_name WaypointData

export var np_stockpile: NodePath

var stockpile: Stockpile setget , get_stockpile
func get_stockpile() -> Stockpile:
	return Game.Map.get_stockpile(np_stockpile) as Stockpile

# not taken into acount for now!
export var cargo_count: int
