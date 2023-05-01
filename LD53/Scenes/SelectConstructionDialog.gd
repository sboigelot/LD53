extends PopupDialog

class_name SelectConstructionDialog

signal ConstructionSelected(packed_scene)

export(Color) var affordable_color
export(Color) var not_affordable_color

export var drone_hub_price:int = 300
export var warehouse_price:int = 500

export(PackedScene) var drone_hub_scene
export(PackedScene) var warehouse_scene

export(NodePath) var np_drone_hub_button
export(NodePath) var np_drone_hub_price_label

onready var ui_drone_hub_button = get_node(np_drone_hub_button) as Button
onready var ui_drone_hub_price_label = get_node(np_drone_hub_price_label) as Label

export(NodePath) var np_warehouse_button
export(NodePath) var np_warehouse_price_label

onready var ui_warehouse_button = get_node(np_warehouse_button) as Button
onready var ui_warehouse_price_label = get_node(np_warehouse_price_label) as Label

var map_has_warehouse:bool = false

func _on_SelectConstructionDialog_about_to_show():
	update_ui()
	
func update_ui():
	var can_afford_drone_hub = Game.Data.money >= drone_hub_price
	ui_drone_hub_button.disabled = not can_afford_drone_hub
	ui_drone_hub_price_label.text = str(drone_hub_price)
	ui_drone_hub_price_label.modulate = affordable_color if can_afford_drone_hub else not_affordable_color

	if not map_has_warehouse:	
		var can_afford_warehouse = Game.Data.money >= warehouse_price
		ui_warehouse_button.disabled = not can_afford_warehouse
		ui_warehouse_price_label.text = str(warehouse_price)
		ui_warehouse_price_label.modulate = affordable_color if can_afford_warehouse else not_affordable_color
	else:
		ui_warehouse_button.disabled = true
		ui_warehouse_price_label.text = "1 per map"
		ui_warehouse_price_label.modulate = not_affordable_color

func _on_CancelButton_pressed():
	hide()

func _on_SelectDroneHubButton_pressed():
	Game.Data.money -= drone_hub_price
	emit_signal("ConstructionSelected", drone_hub_scene)
	hide()

func _on_SelectWarehoudeHubButton_pressed():
	map_has_warehouse = true
	Game.Data.money -= warehouse_price
	emit_signal("ConstructionSelected", warehouse_scene)
	hide()
