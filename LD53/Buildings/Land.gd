extends Spatial

export(PackedScene) var GarageScene
export var garage_price: int = 200

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
	
	var text = ""
	if Game.Data.money >= garage_price:
		text = "Are you sure you want to buy\na garage for %d gold" % garage_price
	else:
		text = "You need %d gold to buy a new garage!" % garage_price
	Game.Map.map_ui.show_confirmation_dialog("Buy Garge?", text, self, "on_confirm_garage_purchase")

func on_confirm_garage_purchase():
	if Game.Data.money >= garage_price:
		Game.Data.money -= garage_price
		spawn_garage()
		queue_free()

func spawn_garage():
	var garage = GarageScene.instance()
	Game.Map.get_building_placeholder().add_child(garage)
	garage.global_translation = global_translation
	garage.global_rotation = global_rotation

func _on_StaticBody_mouse_entered():
	if Game.Data.deliver_phase:
		return
		
	scale = Vector3(1.25,1.25,1.25)

func _on_StaticBody_mouse_exited():		
	if Game.Data.deliver_phase:
		return
		
	scale = Vector3.ONE
