extends WindowDialog

export(PackedScene) var WaypointViewScene

export(NodePath) var np_color_option
export(NodePath) var np_waypoint_view_placeholder
export(NodePath) var np_add_stop_index_label
export(NodePath) var np_add_stop_button
export(NodePath) var np_speed_upgrade_view
export(NodePath) var np_cargo_upgrade_view
export(NodePath) var np_memory_upgrade_view
export(NodePath) var np_tutorial_add_step_container

onready var ui_color_option = get_node(np_color_option) as OptionButton
onready var ui_waypoint_view_placeholder = get_node(np_waypoint_view_placeholder) as Container
onready var ui_add_stop_index_label = get_node(np_add_stop_index_label) as Label
onready var ui_add_stop_button = get_node(np_add_stop_button) as Button
onready var ui_speed_upgrade_view = get_node(np_speed_upgrade_view) as UpgradeView
onready var ui_cargo_upgrade_view = get_node(np_cargo_upgrade_view) as UpgradeView
onready var ui_memory_upgrade_view = get_node(np_memory_upgrade_view) as UpgradeView
onready var ui_tutorial_add_step_container = get_node(np_tutorial_add_step_container) as Container

var drone:Drone
	
func create_done_color_option_items():
	if ui_color_option.get_item_count() > 1:
		return
	
	ui_color_option.clear()
		
	for color in Game.available_drone_colors:
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(create_drone_color_icon(color))
		ui_color_option.add_icon_item(image_texture, "")

func _ready():
	create_done_color_option_items()

func create_drone_color_icon(color:Color) -> Image:
	var icon = Image.new()
	icon.create(16, 16, false, Image.FORMAT_RGB8)
	icon.fill(color)
	icon.unlock()
	return icon
	
func update_ui():
	if drone == null:
		return
	
	ui_speed_upgrade_view.upgrade_current_level = drone.upgrade_speed
	ui_cargo_upgrade_view.upgrade_current_level = drone.upgrade_cargo
	ui_memory_upgrade_view.upgrade_current_level = drone.upgrade_memory
	
	ui_speed_upgrade_view.update_ui()
	ui_cargo_upgrade_view.update_ui()
	ui_memory_upgrade_view.update_ui()
	
	ui_color_option.selected = Game.available_drone_colors.find(drone.color)
	
	for child in ui_waypoint_view_placeholder.get_children():
		child.queue_free()
	
	for index in drone.route.size():
		var waypoint_data:WaypointData = drone.route[index]
		var waypoint_view:WaypointView = WaypointViewScene.instance()
		waypoint_view.index = index
		waypoint_view.data = waypoint_data
		waypoint_view.last = index == drone.route.size() - 1
		waypoint_view.max_cargo = drone.get_upgraded_cargo_max()
		ui_waypoint_view_placeholder.add_child(waypoint_view)
		waypoint_view.connect("PickingTarget", self, "on_waypoint_view_picking_target")
		waypoint_view.connect("Delete", self, "on_delete_waypoint")
		
	if ui_waypoint_view_placeholder.get_child_count() > 0:
		var last_waypoint_view:WaypointView = ui_waypoint_view_placeholder.get_child(ui_waypoint_view_placeholder.get_child_count() - 1)
		if last_waypoint_view.data.factory == null:
			last_waypoint_view.ui_target_button.pressed = true
	
	ui_add_stop_index_label.text = "#%s" % (drone.route.size() + 1)
	
	var can_add_stop = drone.route.size() < drone.get_upgraded_memory()
	ui_add_stop_button.text = "add stop" if can_add_stop else "maximum memory"
	ui_add_stop_button.disabled = not can_add_stop
	
	drone.show_fly_path()

func on_waypoint_view_picking_target(waypoint_view):
	SfxManager.play("beep_click")
	for child in ui_waypoint_view_placeholder.get_children():
		if child != waypoint_view:
			child.toggle_target_button_off()

func on_delete_waypoint(data:WaypointData):
	SfxManager.play("robot_error_1")
	drone.route.erase(data)
	update_ui()

func _process(delta):
	if visible:
		ui_tutorial_add_step_container.visible = Game.Data.is_tutorial_step("add_step")
		if Game.Data.deliver_phase:
			Game.Map.hide_path()
			hide()

func _on_SpeedUpgradeView_Upgraded():
	SfxManager.play("confirm")
	drone.upgrade_speed += 1
	update_ui()

func _on_CargoUpgradeView2_Upgraded():
	SfxManager.play("confirm")
	drone.upgrade_cargo += 1
	update_ui()

func _on_MemoryUpgradeView3_Upgraded():
	SfxManager.play("confirm")
	drone.upgrade_memory += 1
	update_ui()

func _on_AddStopButton_pressed():
	SfxManager.play("beep_click")
	var waypoint = WaypointData.new()
	if  drone.route.size() > 0:
		var last_waypoint = drone.route[drone.route.size() - 1]
		waypoint.factory_input = not last_waypoint.factory_input
		waypoint.cargo_type = last_waypoint.cargo_type
		waypoint.cargo_count = last_waypoint.cargo_count
		
	drone.route.append(waypoint)
	
	Game.Data.complete_tutorial_step("add_step")
	update_ui()

func _on_ColorOptionButton_item_selected(index):
	SfxManager.play("beep_click")
	if drone != null:
		drone.color = Game.available_drone_colors[index]
		drone.show_fly_path()
