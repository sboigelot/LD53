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
export(NodePath) var np_tutorial_deliver_toggle
export(NodePath) var np_tutorial_pick_target

onready var ui_index_label				= get_node(np_index_label) as Label
onready var ui_direction_toggle_button	= get_node(np_direction_toggle_button) as Button
onready var ui_cargo_count_item_list	= get_node(np_cargo_count_item_list) as OptionButton
onready var ui_cargo_item_list			= get_node(np_cargo_item_list) as OptionButton
onready var ui_to_from_label			= get_node(np_to_from_label) as Label
onready var ui_target_button			= get_node(np_target_button) as Button
onready var ui_np_delete_button			= get_node(np_delete_button) as Button
onready var ui_tutorial_deliver_toggle	= get_node(np_tutorial_deliver_toggle) as Container
onready var ui_tutorial_pick_target		= get_node(np_tutorial_pick_target) as Container

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
	ui_index_label.text = "#%d" % (index + 1)
	ui_direction_toggle_button.pressed = data.factory_input
	ui_direction_toggle_button.text = "Deliver" if data.factory_input else "Pickup"
	ui_cargo_count_item_list.selected =  (data.cargo_count - 1)
	for i in ui_cargo_count_item_list.get_item_count():
		var disabled = i >= max_cargo
		ui_cargo_count_item_list.set_item_disabled(i, disabled)
		
	ui_cargo_item_list.selected = cargo_ids[data.cargo_type]
	ui_to_from_label.text = "to" if data.factory_input else "from"
	ui_target_button.text = "Pick Target" if data.factory == null else data.factory.display_name

func _process(delta):
	if not visible:
		return
		
	ui_tutorial_deliver_toggle.visible = last and Game.Data.is_tutorial_step("change_deliver")
	ui_tutorial_pick_target.visible = last and Game.Data.is_tutorial_step("pick_target")
	
func toggle_target_button_off():
	ui_target_button.pressed = false
	
func on_factory_selected(factory):
	data.factory = factory
	update_ui()

func _on_DirectionToggleButton_toggled(button_pressed):
	data.factory_input = button_pressed
	Game.Data.complete_tutorial_step("change_deliver")
	update_ui()
		
func _on_CargoCountItemList_item_selected(index):
	data.cargo_count = ui_cargo_count_item_list.selected + 1
	update_ui()

func _on_CargoItemList_item_selected(index):
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
		
