extends MarginContainer

class_name WaypointView

signal PickingTarget(waypoint_view)
signal Delete(data)

export(NodePath) var np_index_label
export(NodePath) var np_direction_toggle_button
export(NodePath) var np_cargo_count_item_list
export(NodePath) var np_cargo_item_list
export(NodePath) var np_to_from_label
export(NodePath) var np_target_button
export(NodePath) var np_delete_button

onready var ui_index_label				= get_node(np_index_label) as Label
onready var ui_direction_toggle_button	= get_node(np_direction_toggle_button) as Button
onready var ui_cargo_count_item_list	= get_node(np_cargo_count_item_list) as OptionButton
onready var ui_cargo_item_list			= get_node(np_cargo_item_list) as OptionButton
onready var ui_to_from_label			= get_node(np_to_from_label) as Label
onready var ui_target_button			= get_node(np_target_button) as Button
onready var ui_np_delete_button			= get_node(np_delete_button) as Button

var data:WaypointData
var index: int
var last: bool = false
var max_cargo: int = 1

const cargo_ids: Dictionary = {
	"water":	0,
	"vegetable":1,
	"meat":		2,
	"salad":	3,
	"burger":	4
}

func _ready():
	if data == null:
		data = WaypointData.new()
	update_ui()

func update_ui():
	ui_index_label.text = "%d." % (index + 1)
	ui_direction_toggle_button.pressed = data.factory_input
	ui_direction_toggle_button.text = "Deliver" if data.factory_input else "Pickup"
	
	ui_direction_toggle_button.disabled = (
		data.factory == null or 
		(
			(
				data.factory.sp_input_stockpile == null or
				data.factory.sp_input_stockpile == null 
			) and
			data.factory.sp_storage_stockpile_container == null
		))
		
	ui_cargo_count_item_list.selected =  (data.cargo_count - 1)
	for i in ui_cargo_count_item_list.get_item_count():
		var disabled = i >= max_cargo
		ui_cargo_count_item_list.set_item_disabled(i, disabled)
		
	ui_cargo_item_list.selected = cargo_ids[data.cargo_type]
#	ui_to_from_label.text = "to" if data.factory_input else "from"
	ui_target_button.text = "Pick Target" if data.factory == null else data.factory.display_name

func toggle_target_button_off():
	SfxManager.play("beep_click")
	ui_target_button.pressed = false
	
func on_factory_selected(factory):
	data.factory = factory
	auto_select_cargo_type(factory)
	ui_target_button.pressed = false
	update_ui()

func auto_select_cargo_type(factory:Factory):
	
	if factory == null:
		return
	
	if factory.sp_storage_stockpile_container != null:
		return
	
	if factory.sp_input_stockpile == null:
		data.factory_input = false
		
	if factory.sp_output_stockpile == null:
		data.factory_input = true
	
	if data.factory_input:
		if factory.sp_input_stockpile != null:
			data.cargo_type = factory.sp_input_stockpile.cargo_type
	else:
		if factory.sp_output_stockpile != null:
			data.cargo_type = factory.sp_output_stockpile.cargo_type

func _on_DirectionToggleButton_toggled(button_pressed):
	SfxManager.play("beep_click")
	data.factory_input = button_pressed
	Game.Data.complete_tutorial_step("change_deliver")
	
#	ui_target_button.pressed = true
	auto_select_cargo_type(data.factory)
	
	update_ui()
		
func _on_CargoCountItemList_item_selected(index):
	SfxManager.play("beep_click")
	data.cargo_count = ui_cargo_count_item_list.selected + 1
	update_ui()

func _on_CargoItemList_item_selected(index):
	SfxManager.play("beep_click")
	for cargo_name in cargo_ids.keys():
		var cargo_id = cargo_ids[cargo_name]
		if ui_cargo_item_list.selected == cargo_id:
			data.cargo_type = cargo_name
			update_ui()
			return

func _on_DeleteButton_pressed():
	emit_signal("Delete", data)

func _on_TargetButton_toggled(button_pressed):
	if button_pressed == true:	
		Game.Map.map_ui.wait_for_factory_target(self)
		emit_signal("PickingTarget", self)
		Game.Data.complete_tutorial_step("pick_target")
	elif Game.Map.map_ui.waiting_for_factory_target == self:
		 Game.Map.map_ui.waiting_for_factory_target = null
		
