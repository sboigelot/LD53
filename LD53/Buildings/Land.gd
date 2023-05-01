extends Spatial

var tutorial_shown:bool = false

func _on_StaticBody_input_event(camera, event, position, normal, shape_idx):
	if Game.Data.deliver_phase:
		return
		
	if event is InputEventMouseButton:
		var mouse_event:InputEventMouseButton = event
		if (mouse_event.button_index == BUTTON_LEFT and
			mouse_event.pressed):
			on_mouse_left_button_click()

func on_mouse_left_button_click():
	emit_signal("Pressed", self)
	Game.Data.complete_tutorial_step("build_on_land")
	
#	var text = ""
#	if Game.Data.money >= garage_price:
#		text = "Are you sure you want to buy\na garage for %d gold" % garage_price
#	else:
#		text = "You need %d gold to buy a new garage!" % garage_price
#	Game.Map.map_ui.show_confirmation_dialog("Buy Garge?", text, self, "on_confirm_garage_purchase")
	
	Game.Map.map_ui.show_select_construction_dialog(self, "on_confirm_construction")

func on_confirm_construction(packed_scene):
	spawn_replacement(packed_scene)
	queue_free()

func spawn_replacement(packed_scene):
	var replacement = packed_scene.instance()
	Game.Map.get_building_placeholder().add_child(replacement)
	replacement.global_translation = global_translation
	replacement.global_rotation = global_rotation
	replacement.popup()

func _process(delta):
	if tutorial_shown:
		if $HoverLabel3D.visible:
			$HoverLabel3D.visible = Game.Data.is_tutorial_step("build_on_land")
	elif not Game.Data.deliver_phase and Game.Data.is_tutorial_step("build_on_land"):
			$HoverLabel3D.visible = true
			tutorial_shown = true

func _on_StaticBody_mouse_entered():
	if Game.Data.deliver_phase:
		return
		
	scale = Vector3(1.25,1.25,1.25)

func _on_StaticBody_mouse_exited():		
	if Game.Data.deliver_phase:
		return
		
	scale = Vector3.ONE
