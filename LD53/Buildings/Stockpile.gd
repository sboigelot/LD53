tool
extends Spatial

class_name Stockpile

signal Pressed
signal DroneLeft(stockpile)

export var cargo_max: int = 3
export var cargo_count: int = 0 setget set_crate_count
export var cargo_space_reserved: int = 0
export var cargo_reserved: int = 0

export var import: bool
export var cargo_type: String = "Vegetable"

export var drone_waiting: int = 0

func set_crate_count(value:int):
	cargo_count = min(cargo_max, value)
	get_node("Crates/Crate1").visible = cargo_count > 0
	get_node("Crates/Crate2").visible = cargo_count > 1
	get_node("Crates/Crate3").visible = cargo_count > 2
	
func _on_StaticBody_mouse_entered():
	scale = Vector3(1.25,1.25,1.25)

func _on_StaticBody_mouse_exited():
	scale = Vector3.ONE

func _on_StaticBody_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton:
		var mouse_event:InputEventMouseButton = event
		if (mouse_event.button_index == BUTTON_LEFT and
			mouse_event.pressed):
			on_mouse_left_button_click()
			
func on_mouse_left_button_click():
	print("on_mouse_left_button_click")
	emit_signal("Pressed", self)
	
func try_reserve_space() -> bool:
	if not has_free_space():
		return false
	
	cargo_space_reserved += 1
	return true
	
func has_free_cargo() -> bool:
	return (cargo_count - cargo_reserved) > 0
	
func try_reserve_cargo() -> bool:
	if not has_free_cargo():
		return false
		
	cargo_reserved += 1
	return true
	
func try_pickup() -> bool:
	if cargo_reserved <= 0:
		return false
		
	if cargo_count <= 0:
		return false
		
	self.cargo_count -= 1
	cargo_reserved -= 1
	return true
	
func has_free_space() -> bool:
	return (cargo_count + cargo_space_reserved) < cargo_max
	
func try_deliver() -> bool:
	if not has_free_space():
		return false
		
	self.cargo_count += 1
	cargo_space_reserved -= 1
	return true
	
func register_waiting() -> int:
	drone_waiting += 1
	return drone_waiting - 1
	
func unregister_waiting():
	drone_waiting -= 1
	emit_signal("DroneLeft", self)
