extends Resource

class_name WaypointData

var factory: Factory 
export var factory_input: bool = false
export var cargo_type: String = "water"

export var np_stockpile: NodePath

var stockpile: Stockpile setget , get_stockpile
func get_stockpile() -> Stockpile:
	if factory != null:
		
		if factory.sp_storage_stockpile_container != null:
			for storage_stockpile in factory.sp_storage_stockpile_container.get_children():
				if storage_stockpile.cargo_type == cargo_type and storage_stockpile.import == factory_input:
					return storage_stockpile
		
		if factory_input:
			return factory.sp_input_stockpile
		else:
			return factory.sp_output_stockpile
	
	if np_stockpile != null:
		return Game.Map.get_stockpile(np_stockpile) as Stockpile
		
	return null

export var cargo_count: int = 1
