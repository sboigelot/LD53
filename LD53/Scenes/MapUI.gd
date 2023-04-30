extends CanvasLayer

class_name MapUI

export(NodePath) var np_day_label
export(NodePath) var np_money_label
export(NodePath) var np_confirmation_dialog
export(NodePath) var np_drone_popup
export(NodePath) var np_delivery_phase_info_label
export(NodePath) var np_delivery_phase_progress_bar

onready var ui_day_label = get_node(np_day_label) as Label
onready var ui_money_label = get_node(np_money_label) as Label
onready var ui_confirmation_dialog = get_node(np_confirmation_dialog) as ConfirmationDialog
onready var ui_drone_popup = get_node(np_drone_popup) as PopupDialog
onready var ui_delivery_phase_info_label = get_node(np_delivery_phase_info_label) as Label
onready var ui_delivery_phase_progress_bar = get_node(np_delivery_phase_progress_bar) as ProgressBar

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

var last_confirmation_request_func: FuncRef

var waiting_for_factory_target: WaypointView

func _process(delta):
	ui_day_label.text = str(Game.Data.day)
	ui_money_label.text = str(Game.Data.money)
	
	ui_delivery_phase_progress_bar.max_value = Game.Data.deliver_phase_duration_seconds
	ui_delivery_phase_progress_bar.value = Game.Data.deliver_phase_timer
#	ui_delivery_phase_progress_bar.visible = Game.Data.deliver_phase
	
	ui_delivery_phase_info_label.text = "Delivery in Progress!" if Game.Data.deliver_phase else "Configuration Mode"

func show_drone_popup(drone):
	ui_drone_popup.drone = drone
	ui_drone_popup.update_ui()
	if not ui_drone_popup.visible:
		ui_drone_popup.popup()

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
	if Game.Data.deliver_phase:
		if Game.Data.deliver_phase_speed == 1.0:
			Game.Data.deliver_phase_speed = 5.0
		else:
			Game.Data.deliver_phase_speed = 1.0
			
func show_end_of_day_report(day:int):
	
	ui_edr_count_label_water.text		=	str(Game.Data.daily_deliveries[day - 1]["water"])
	ui_edr_count_label_vegetable.text 	=	str(Game.Data.daily_deliveries[day - 1]["vegetable"])
	ui_edr_count_label_salad.text		=	str(Game.Data.daily_deliveries[day - 1]["salad"])
	ui_edr_count_label_meat.text 		=	str(Game.Data.daily_deliveries[day - 1]["meat"])
	ui_edr_count_label_burger.text		=	str(Game.Data.daily_deliveries[day - 1]["burger"])
	ui_edr_count_label_coin.text 		=	str(Game.Data.daily_money_benefits[day - 1])
	
	var delivered_salad = Game.Data.get_total_goals_count("salad")
	var goal_salad = Game.Data.get_completed_goals_count("salad")
	ui_edr_count_label_goal_salad.text 	=	"%d / %d" % [delivered_salad, goal_salad]
	
	var delivered_meat = Game.Data.get_total_goals_count("meat")
	var goal_meat = Game.Data.get_completed_goals_count("meat")
	ui_edr_count_label_goal_meat.text 	=	"%d / %d" % [delivered_meat, goal_meat]
	
	ui_edr_victory_label.visible = delivered_salad >= goal_salad and delivered_meat >= goal_meat
	ui_end_of_day_report_popup.popup_centered()

func _on_CloseButton_pressed():
	ui_end_of_day_report_popup.hide()
