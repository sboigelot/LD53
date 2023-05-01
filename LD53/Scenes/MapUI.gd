extends CanvasLayer

class_name MapUI

export(NodePath) var np_day_label
export(NodePath) var np_money_label
export(NodePath) var np_stat_count_label_goal_salad
export(NodePath) var np_stat_count_label_goal_meat
export(NodePath) var np_open_day_report_button
export(NodePath) var np_help_window
export(NodePath) var np_confirmation_dialog
export(NodePath) var np_select_construction_dialog
export(NodePath) var np_drone_popup
export(NodePath) var np_delivery_phase_info_label
export(NodePath) var np_delivery_phase_progress_bar
export(NodePath) var np_tutorial_start_day_container

onready var ui_day_label 					= get_node(np_day_label) as Label
onready var ui_money_label 					= get_node(np_money_label) as Label
onready var ui_stat_count_label_goal_salad	= get_node(np_stat_count_label_goal_salad) as Label
onready var ui_stat_count_label_goal_meat	= get_node(np_stat_count_label_goal_meat) as Label
onready var ui_open_day_report_button		= get_node(np_open_day_report_button) as Button
onready var ui_help_window					= get_node(np_help_window) as WindowDialog
onready var ui_confirmation_dialog 			= get_node(np_confirmation_dialog) as ConfirmationDialog
onready var ui_select_construction_dialog 	= get_node(np_select_construction_dialog) as SelectConstructionDialog
onready var ui_drone_popup 					= get_node(np_drone_popup) as WindowDialog
onready var ui_delivery_phase_info_label 	= get_node(np_delivery_phase_info_label) as Label
onready var ui_delivery_phase_progress_bar 	= get_node(np_delivery_phase_progress_bar) as ProgressBar
onready var ui_tutorial_start_day_container = get_node(np_tutorial_start_day_container) as Container

export(NodePath) var np_end_of_day_report_popup
export(NodePath) var np_edr_count_label_water
export(NodePath) var np_edr_count_label_vegetable
export(NodePath) var np_edr_count_label_salad
export(NodePath) var np_edr_count_label_meat
export(NodePath) var np_edr_count_label_burger
export(NodePath) var np_edr_count_label_coin
export(NodePath) var np_edr_count_label_goal_salad
export(NodePath) var np_edr_count_label_goal_meat
export(NodePath) var np_edr_victory_label

onready var ui_end_of_day_report_popup		= get_node(np_end_of_day_report_popup) as PopupDialog
onready var ui_edr_count_label_water		= get_node(np_edr_count_label_water) as Label
onready var ui_edr_count_label_vegetable	= get_node(np_edr_count_label_vegetable) as Label
onready var ui_edr_count_label_salad		= get_node(np_edr_count_label_salad) as Label
onready var ui_edr_count_label_meat			= get_node(np_edr_count_label_meat) as Label
onready var ui_edr_count_label_burger		= get_node(np_edr_count_label_burger) as Label
onready var ui_edr_count_label_coin			= get_node(np_edr_count_label_coin) as Label
onready var ui_edr_count_label_goal_salad	= get_node(np_edr_count_label_goal_salad) as Label
onready var ui_edr_count_label_goal_meat	= get_node(np_edr_count_label_goal_meat) as Label
onready var ui_edr_victory_label			= get_node(np_edr_victory_label) as Label

export(NodePath) var np_edr_prev_day_button
export(NodePath) var np_edr_day_label
export(NodePath) var np_edr_next_day_button

onready var ui_edr_prev_day_button		= get_node(np_edr_prev_day_button) as Button
onready var ui_edr_day_label			= get_node(np_edr_day_label) as Label
onready var ui_edr_next_day_button		= get_node(np_edr_next_day_button) as Button

var last_confirmation_request_func: FuncRef

var waiting_for_factory_target: WaypointView

var current_report_day:int = 0

func _process(delta):
	ui_day_label.text = str(Game.Data.day)
	ui_money_label.text = str(Game.Data.money)
	
	ui_delivery_phase_progress_bar.max_value = Game.Data.deliver_phase_duration_seconds
	ui_delivery_phase_progress_bar.value = Game.Data.deliver_phase_timer
#	ui_delivery_phase_progress_bar.visible = Game.Data.deliver_phase
	
	ui_delivery_phase_info_label.text = "Delivery in Progress!" if Game.Data.deliver_phase else "Planning Mode"

	ui_tutorial_start_day_container.visible = Game.Data.is_tutorial_step("start_day")
	
	ui_open_day_report_button.visible = Game.Data.day > 1

func show_drone_popup(drone):
	ui_drone_popup.drone = drone
	ui_drone_popup.update_ui()
	if not ui_drone_popup.visible:
		ui_drone_popup.popup()

func show_select_construction_dialog(instance, function):
	ui_select_construction_dialog.popup_centered()
	
	last_confirmation_request_func = FuncRef.new()
	last_confirmation_request_func.set_instance(instance)
	last_confirmation_request_func.function = function

func _on_SelectConstructionDialog_ConstructionSelected(packed_scene):
	if last_confirmation_request_func != null:
		last_confirmation_request_func.call_func(packed_scene)
		last_confirmation_request_func = null
	
func show_confirmation_dialog(title:String, text:String, instance, function):
	ui_confirmation_dialog.window_title = title
	ui_confirmation_dialog.dialog_text = text
	ui_confirmation_dialog.popup_centered()
	
	last_confirmation_request_func = FuncRef.new()
	last_confirmation_request_func.set_instance(instance)
	last_confirmation_request_func.function = function

func _on_ConfirmationDialog_confirmed():
	if last_confirmation_request_func != null:
		last_confirmation_request_func.call_func()
		last_confirmation_request_func = null

func wait_for_factory_target(waypoint_view):
	waiting_for_factory_target = waypoint_view

func on_factory_pressed(factory: Factory):
	if waiting_for_factory_target == null:
		return
		
	waiting_for_factory_target.on_factory_selected(factory)
	waiting_for_factory_target = null
	
	if ui_drone_popup.drone != null:
		show_drone_popup(ui_drone_popup.drone)

func _on_ResetButton_pressed():
	if Game.Data.deliver_phase:
		Game.Data.reset_delivery_phase()

func _on_PlayButton_pressed():
	if not Game.Data.deliver_phase:
		Game.Data.start_delivery_phase()
	else:
		Game.Data.deliver_phase_speed = 1.0

func _on_ForwardButton_pressed():
	if not Game.Data.deliver_phase:
		Game.Data.start_delivery_phase()
	if Game.Data.deliver_phase:
		if Game.Data.deliver_phase_speed == 1.0:
			Game.Data.deliver_phase_speed = 5.0
		else:
			Game.Data.deliver_phase_speed = 1.0
			

func show_end_of_day_report(day:int):
	
	if Game.Data.daily_deliveries.size() <= day - 1:
		return
		
	if day > Game.Data.day:
		return
	
	current_report_day = day
	
	ui_edr_prev_day_button.disabled = day == 1
	ui_edr_day_label.text = "day %d" % day
	ui_edr_next_day_button.disabled = day == Game.Data.day
	
	ui_edr_count_label_water.text		=	str(Game.Data.daily_deliveries[day - 1]["water"])
	ui_edr_count_label_vegetable.text 	=	str(Game.Data.daily_deliveries[day - 1]["vegetable"])
	ui_edr_count_label_salad.text		=	str(Game.Data.daily_deliveries[day - 1]["salad"])
	ui_edr_count_label_meat.text 		=	str(Game.Data.daily_deliveries[day - 1]["meat"])
	ui_edr_count_label_burger.text		=	str(Game.Data.daily_deliveries[day - 1]["burger"])
	ui_edr_count_label_coin.text 		=	str(Game.Data.daily_money_benefits[day - 1])
	
	update_goal_labels()
	ui_end_of_day_report_popup.popup_centered()
	
func update_goal_labels():
	if Game.Data == null:
		return
		
	var delivered_salad = Game.Data.get_completed_goals_count("salad")
	var goal_salad = Game.Data.get_total_goals_count("salad")
	ui_edr_count_label_goal_salad.text 	=	"%d / %d" % [delivered_salad, goal_salad]
	ui_stat_count_label_goal_salad.text 	=	"%d / %d" % [delivered_salad, goal_salad]
	
	var delivered_meat = Game.Data.get_completed_goals_count("burger")
	var goal_meat = Game.Data.get_total_goals_count("burger")
	ui_edr_count_label_goal_meat.text 	=	"%d / %d" % [delivered_meat, goal_meat]
	ui_stat_count_label_goal_meat.text 	=	"%d / %d" % [delivered_meat, goal_meat]
	
	ui_edr_victory_label.visible = delivered_salad >= goal_salad and delivered_meat >= goal_meat
	
func _on_CloseButton_pressed():
	ui_end_of_day_report_popup.hide()

func _on_OpenDayReportButton_button_down():
	show_end_of_day_report(Game.Data.day - 1)

func _on_PrevDayButton_pressed():
	current_report_day -= 1
	show_end_of_day_report(current_report_day)

func _on_NextDayButton_pressed():	
	current_report_day += 1
	show_end_of_day_report(current_report_day)

func _on_ShowRecipeButton_pressed():
	ui_help_window.popup()
