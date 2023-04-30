extends Resource

class_name WaypointData

var factory: Factory 
var factory_input: bool = false
var cargo_type: String = "water"

export var np_stockpile: NodePath

var stockpile: Stockpile setget , get_stockpile
func get_stockpile() -> Stockpile:
	if factory != null:
		if factory_input:
			return factory.sp_input_stockpile
		else:
			return factory.sp_output_stockpile
	
	if np_stockpile != null:
		return Game.Map.get_stockpile(np_stockpile) as Stockpile
		
	return null

# not taken into acount for now!
export var cargo_count: int = 1
