extends Spatial

class_name DronePad

signal Pressed(DronePad)

export(PackedScene) var DroneScene

export(NodePath) var np_drone_parking_space

onready var sp_drone_parking_space = get_node(np_drone_parking_space) as Spatial

var drone: Drone
export var drone_bought: bool = false
export var basic_drone_price: int

func _process(delta):
	if drone == null and drone_bought:
		spawn_drone()
		
func spawn_drone():	
	drone = DroneScene.instance()
	Game.Map.get_drone_placeholder().add_child(drone)
	drone.drone_pad = self
	drone.drone_pad_reached = false
	drone.drone_pad_landed = false
	drone.global_translation = sp_drone_parking_space.global_translation
	drone.global_rotation = sp_drone_parking_space.global_rotation

func _on_StaticBody_input_event(camera, event, position, normal, shape_idx):
	if drone != null:
		return
		
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
	if Game.Data.money >= basic_drone_price:
		text = "Are you sure you want to buy\na drone for %d gold" % basic_drone_price
	else:
		text = "You need %d gold to buy a new Drone!" % basic_drone_price
	Game.Map.map_ui.show_confirmation_dialog("Buy Drone?", text, self, "on_confirm_drone_purchase")

func on_confirm_drone_purchase():
	if Game.Data.money >= basic_drone_price:
		Game.Data.money -= basic_drone_price
		drone_bought = true

func _on_StaticBody_mouse_entered():
	if drone != null:
		return
		
	if Game.Data.deliver_phase:
		return
		
	scale = Vector3(1.25,1.25,1.25)

func _on_StaticBody_mouse_exited():
	if drone != null:
		return
		
	if Game.Data.deliver_phase:
		return
		
	scale = Vector3.ONE
