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
export var cargo_type: String = "vegetable"

export var drone_waiting: int = 0
var drone_in_lane

func set_crate_count(value:int):
	cargo_count = min(cargo_max, value)
	get_node("Crates/crate1").visible = cargo_type != "water" and cargo_count > 0
	get_node("Crates/crate2").visible = cargo_type != "water" and cargo_count > 1
	get_node("Crates/crate3").visible = cargo_type != "water" and cargo_count > 2
	get_node("Buckets/bucket1").visible = cargo_type == "water" and cargo_count > 0
	get_node("Buckets/bucket2").visible = cargo_type == "water" and cargo_count > 1
	get_node("Buckets/bucket3").visible = cargo_type == "water" and cargo_count > 2
	
func _on_StaticBody_mouse_entered():
	if Game.Data.deliver_phase:
		return
	scale = Vector3(1.25,1.25,1.25)

func _on_StaticBody_mouse_exited():
	if Game.Data.deliver_phase:
		return
	scale = Vector3.ONE

func _on_StaticBody_input_event(camera, event, position, normal, shape_idx):
	if Game.Data.deliver_phase:
		return
	if event is InputEventMouseButton:
		var mouse_event:InputEventMouseButton = event
		if (mouse_event.button_index == BUTTON_LEFT and
			mouse_event.pressed):
			on_mouse_left_button_click()
			
func on_mouse_left_button_click():
	print("on_mouse_left_button_click")
	emit_signal("Pressed", self)
	
func try_reserve_space(quantity:int) -> bool:
	if not has_free_space(quantity):
		return false
	
	cargo_space_reserved += quantity
	return true
	
func has_free_cargo(quantity) -> bool:
	return (cargo_count - cargo_reserved) >= quantity
	
func try_reserve_cargo(quantity:int) -> bool:
	if not has_free_cargo(quantity):
		return false
		
	cargo_reserved += quantity
	return true
	
func try_pickup(reserved:bool, quantity:int) -> bool:
	if reserved and cargo_reserved <= 0:
		return false
		
	if cargo_count < quantity:
		return false
		
	self.cargo_count -= quantity
	if reserved:
		cargo_reserved -= quantity
	return true
	
func has_free_space(quantity:int) -> bool:
	return (cargo_count + cargo_space_reserved + quantity) <= cargo_max
	
func try_deliver(reserved:bool, quantity:int) -> bool:
	if not reserved and not has_free_space(quantity):
		return false
		
	self.cargo_count += quantity
	if reserved:
		cargo_space_reserved -= quantity
	return true
	
func register_waiting() -> int:
	drone_waiting += 1
	return drone_waiting - 1
	
func unregister_waiting():
	drone_waiting -= 1
	emit_signal("DroneLeft", self)
