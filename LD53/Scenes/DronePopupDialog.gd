extends PopupDialog

export(NodePath) var np_speed_upgrade_view
export(NodePath) var np_cargo_upgrade_view
export(NodePath) var np_memory_upgrade_view

onready var ui_speed_upgrade_view = get_node(np_speed_upgrade_view) as UpgradeView
onready var ui_cargo_upgrade_view = get_node(np_cargo_upgrade_view) as UpgradeView
onready var ui_memory_upgrade_view = get_node(np_memory_upgrade_view) as UpgradeView

var drone:Drone

func _on_DronePopupDialog_about_to_show():
	pass
	
func update_ui():
	if drone == null:
		return
	
	ui_speed_upgrade_view.upgrade_current_level = drone.upgrade_speed
	ui_cargo_upgrade_view.upgrade_current_level = drone.upgrade_cargo
	ui_memory_upgrade_view.upgrade_current_level = drone.upgrade_memory
	
	ui_speed_upgrade_view.update_ui()
	ui_cargo_upgrade_view.update_ui()
	ui_memory_upgrade_view.update_ui()

func _process(delta):
	if visible and Game.Data.deliver_phase:
		hide()

func _on_SpeedUpgradeView_Upgraded():
	drone.upgrade_speed += 1
	update_ui()

func _on_CargoUpgradeView2_Upgraded():
	drone.upgrade_cargo += 1
	update_ui()

func _on_MemoryUpgradeView3_Upgraded():
	drone.upgrade_memory += 1
	update_ui()
