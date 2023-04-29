extends CanvasLayer

class_name MapUI

export(NodePath) var np_money_label
export(NodePath) var np_confirmation_dialog
export(NodePath) var np_drone_popup

onready var ui_money_label = get_node(np_money_label) as Label
onready var ui_confirmation_dialog = get_node(np_confirmation_dialog) as ConfirmationDialog
onready var ui_drone_popup = get_node(np_drone_popup) as PopupDialog

var last_confirmation_request_func: FuncRef

func _process(delta):
	ui_money_label.text = str(Game.Data.money)

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
