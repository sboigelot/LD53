extends RigidBody

class_name Drone

signal Pressed

export(NodePath) var np_click_me
export(NodePath) var np_warning_no_cargo_sprite_3D
export(NodePath) var np_warning_no_cargo_space_sprite_3D
export(NodePath) var np_warning_long_wait_time_sprite_3D
export(NodePath) var np_warning_confused

onready var sp_click_me =							get_node(np_click_me) as HoverLabel3D
onready var sp_warning_no_cargo_sprite_3D = 		get_node(np_warning_no_cargo_sprite_3D) 		as Sprite3D
onready var sp_warning_no_cargo_space_sprite_3D = 	get_node(np_warning_no_cargo_space_sprite_3D) 	as Sprite3D
onready var sp_warning_long_wait_time_sprite_3D = 	get_node(np_warning_long_wait_time_sprite_3D)	as Sprite3D
onready var sp_warning_confused = 					get_node(np_warning_confused)					as Sprite3D

export(NodePath) var np_cargo_icon_1
export(NodePath) var np_cargo_icon_2
export(NodePath) var np_cargo_icon_3

onready var sp_cargo_icons = [
	get_node(np_cargo_icon_1),
	get_node(np_cargo_icon_2),
	get_node(np_cargo_icon_3)
]

export(NodePath) var np_animation_player
export(NodePath) var np_selection_torus
export(NodePath) var np_drone_mesh

onready var sp_animation_player = get_node(np_animation_player)	as AnimationPlayer
onready var sp_selection_torus = get_node(np_selection_torus)	as CSGTorus
onready var sp_drone_mesh = get_node(np_drone_mesh)	as MeshInstance

export var color:Color = Color.white setget set_color

func set_color(value:Color):
	color = value
	if sp_drone_mesh == null:
		return
		
	var material = SpatialMaterial.new()
	material.albedo_color = color
	sp_drone_mesh.material_override = material
	
export var speed:float = 3.0
export var take_off_speed:float = 2.0
export var cargo_max:int = 1
export var memory_size:int = 3

const flight_y: float = 3.0
const dock_y: float = 0.5
const parking_speration: float = 2.0
const destination_snap_distance: float = 0.1 

export var cargo: PoolStringArray

export var route: Array
var route_index: int = 0 

var waypoint: WaypointData
var waypoint_parking_spot_id: int
var waypoint_parking_registered: bool
var waypoint_reached: bool
var waypoint_reserved: bool
var waypoint_parking_unregistered: bool
var waypoint_landed: bool
var waypoint_pickup_or_delivered: bool

var wait_for_waypoint: float
const max_wait_for_waypoint: float = 5.0
const need_take_off_before_move: bool = false

var upgrade_speed: int = 1
var upgrade_cargo: int = 1
var upgrade_memory: int = 1

func get_upgraded_speed() -> float:
	return speed + (upgrade_speed * 0.5)
	
func get_upgraded_cargo_max() -> int:
	return cargo_max + (upgrade_cargo - 1)
	
func get_upgraded_memory() -> int:
	return memory_size + (upgrade_memory - 1)
	
var drone_pad
var drone_pad_reached:bool = true
var drone_pad_landed:bool = true

func _ready():
	clear_all()
	on_cargo_change()
	sp_animation_player.play("Wobble")
	
	var random_color = color
	if (random_color == Color.white and
		Game.available_drone_colors != null and 
		Game.available_drone_colors.size() != 0):
		random_color = Game.available_drone_colors[randi() % Game.available_drone_colors.size()]
	set_color(random_color)

func show_hide_click_me():
	if not Game.Data.deliver_phase and Game.Data.is_tutorial_step("click_me_drone"):
		sp_click_me.popup()
	else:
		sp_click_me.hide()
		
func move_toward_drone_pad(delta) -> bool:
	clear_all()
	if cargo.size() > 0:
		cargo.resize(0)
		on_cargo_change()
		
	route_index = 0
	waypoint = null
	
	if drone_pad == null:
		return true
	
	var destination = Vector3(
		drone_pad.global_translation.x,
		drone_pad.global_translation.y + flight_y,
		drone_pad.global_translation.z)
	var reached_drone_pad = move_toward_destination(destination, delta)
		
	if reached_drone_pad:
		global_rotation = drone_pad.global_rotation
	
	return reached_drone_pad

func update_selection_torus_visibility():
	sp_selection_torus.visible = (Game.Map.map_ui.ui_drone_popup.visible and
									Game.Map.map_ui.ui_drone_popup.drone == self)

func _physics_process(delta):
	if not visible:
		return
		
	var game_delta = Game.Data.deliver_phase_speed * delta
	
	show_hide_click_me()
	update_selection_torus_visibility()
	
	if not Game.Data.deliver_phase:
		
		if not drone_pad_reached:
			drone_pad_reached = move_toward_drone_pad(game_delta)
			return
			
		if not drone_pad_landed:
			drone_pad_landed = land_on_drone_pad(delta)
			return
			
		return
		
	if waypoint == null:
		waypoint = get_current_route_waypoint()
		if waypoint == null:
			return

	# 0: register waypoint parking spot
	if not waypoint_parking_registered:
		waypoint_parking_registered = register_waypoint_parking(game_delta)
		return

	# 1 goto waypoint next parking spot
	if not waypoint_reached:
		drone_pad_reached = false
		drone_pad_landed = false
		waypoint_reached = move_toward_waypoint(game_delta)
		return
	
	if not waypoint_order_match_stockpile():
		return
		
	if not drone_turn_in_lane(game_delta):
		return
		
	# 2 try reserve waypoint space
	if not waypoint_reserved:
		waypoint_reserved = reserve_waypoint(game_delta)
		return
	
	# 3 free waypoint parking spot
	if not waypoint_parking_unregistered:
		waypoint_parking_unregistered = unregister_waypoint_parking(delta)
		return
		
	# 4 land on waypoint
	if not waypoint_landed:
		waypoint_landed = land_on_waypoint(game_delta)
		return
	
	if not waypoint_pickup_or_delivered:
		# 5 pickup/deliver cargo
		waypoint_pickup_or_delivered = pickup_or_deliver(game_delta)
		return
		
	free_turn_in_lane()
	next_waypoint()

func get_current_route_waypoint() -> WaypointData:
	if route_index >= route.size():
		return null
		
	var route_waypoint = route[route_index]
	
	if route_waypoint.stockpile == null:
		next_waypoint()
		return null
		
	return route_waypoint
	
func next_waypoint():
	clear_all()
	route_index = (route_index + 1) % route.size()
	
func clear_all():
	waypoint = null
	
	waypoint_parking_spot_id = 0
	waypoint_parking_registered = false
	waypoint_reached = false
	waypoint_reserved = false
	waypoint_parking_unregistered = false
	waypoint_landed = false
	waypoint_pickup_or_delivered = false
	wait_for_waypoint = 0.0
	
	sp_warning_no_cargo_sprite_3D.visible = false
	sp_warning_no_cargo_space_sprite_3D.visible = false
	sp_warning_long_wait_time_sprite_3D.visible = false
	sp_warning_confused.visible = false

func register_waypoint_parking(delta) -> bool:
	waypoint_parking_spot_id = waypoint.stockpile.register_waiting()
	if not waypoint.stockpile.is_connected("DroneLeft", self, "on_stockpile_drone_left"):
		waypoint.stockpile.connect("DroneLeft", self, "on_stockpile_drone_left")
	return true
	
func on_stockpile_drone_left(stockpile):
	if waypoint == null:
		return
		
	if waypoint.stockpile != stockpile:
		return
	
	waypoint_parking_spot_id = max(waypoint_parking_spot_id - 1, 0)
	waypoint_reached = false
	wait_for_waypoint = 0.0
	
func move_toward_waypoint(delta) -> bool:
	var destination = Vector3(
		waypoint.stockpile.global_translation.x,
		waypoint.stockpile.global_translation.y + flight_y + (parking_speration * waypoint_parking_spot_id),
		waypoint.stockpile.global_translation.z)
		
	if translation.y < destination.y:
		translation.y += (take_off_speed * delta)
		if need_take_off_before_move:
			return false
		
	return move_toward_destination(destination, delta)

func move_toward_destination(destination:Vector3, delta:float) -> bool:
	var distance = translation.distance_to(destination)
	if distance < destination_snap_distance:
		return true
	
	rotation_degrees.y =  lerp(rotation_degrees.y,
				rad2deg(translation.angle_to(destination)), 1.0)

	var direction = translation.direction_to(destination)
	var actual_speed =  get_upgraded_speed() * delta
	actual_speed = min(actual_speed, translation.distance_to(destination))
	translation += direction * actual_speed
	return false

func waypoint_order_match_stockpile() -> bool:
	var matching_order = waypoint.cargo_type == waypoint.stockpile.cargo_type
	sp_warning_confused.visible = not matching_order
	return matching_order

func reserve_waypoint(delta) -> bool:
	if waypoint.factory_input:
		return try_reserve_delivery(delta)
	else:
		return try_reserve_pickup(delta)

func try_reserve_delivery(delta) -> bool:
	if not cargo.has(waypoint.stockpile.cargo_type):
		sp_warning_no_cargo_sprite_3D.visible = true
		return false
		
	if not waypoint.stockpile.try_reserve_space(waypoint.cargo_count):
		wait_for_waypoint += delta
		sp_warning_long_wait_time_sprite_3D.visible = wait_for_waypoint > max_wait_for_waypoint
		return false
	
	wait_for_waypoint = 0.0
	return true

func try_reserve_pickup(delta) -> bool:
	if cargo.size() + waypoint.cargo_count > get_upgraded_cargo_max():
		sp_warning_no_cargo_space_sprite_3D.visible = true
		return false
		
	if not waypoint.stockpile.try_reserve_cargo(waypoint.cargo_count):
		wait_for_waypoint += delta
		sp_warning_long_wait_time_sprite_3D.visible = wait_for_waypoint > max_wait_for_waypoint
		return false
	
	wait_for_waypoint = 0.0
	return true

func unregister_waypoint_parking(delta) -> bool:
	if waypoint.stockpile.is_connected("DroneLeft", self, "on_stockpile_drone_left"):
		waypoint.stockpile.disconnect("DroneLeft", self, "on_stockpile_drone_left")
	waypoint.stockpile.unregister_waiting()
	return true

func drone_turn_in_lane(delta) -> bool:
	
	if waypoint_parking_spot_id != 0:
		return false
	
	if waypoint.stockpile.drone_in_lane == self:
		return true
		
	if waypoint.stockpile.drone_in_lane == null:
		waypoint.stockpile.drone_in_lane = self	
		return true
		
	wait_for_waypoint += delta
	sp_warning_long_wait_time_sprite_3D.visible = wait_for_waypoint > max_wait_for_waypoint
	return false

func land_on_waypoint(delta) -> bool:
	if translation.y > (waypoint.stockpile.translation.y + dock_y):
		translation.y -= (take_off_speed * delta)
		return false
	
	return true

func land_on_drone_pad(delta) -> bool:
	if drone_pad == null:
		return true
		
	if translation.y > (drone_pad.global_translation.y):
		translation.y -= (take_off_speed * delta)
		return false
	
	return true
	
func pickup_or_deliver(delta)->bool:
	if waypoint.factory_input:
		return try_deliver(delta)
		
	return try_pickup(delta)
	
func free_turn_in_lane():
	if waypoint.stockpile.drone_in_lane == self:
		waypoint.stockpile.drone_in_lane = null
	
func try_deliver(delta) -> bool:
#	this should never be true with initial FSM
	if not cargo.has(waypoint.stockpile.cargo_type):
		sp_warning_no_cargo_sprite_3D.visible = true
		return false
		
	if not waypoint.stockpile.try_deliver(true, waypoint.cargo_count):
		wait_for_waypoint += delta
		sp_warning_long_wait_time_sprite_3D.visible = wait_for_waypoint > max_wait_for_waypoint
		return false
	
	for i in waypoint.cargo_count:
		cargo.remove(cargo.rfind(waypoint.stockpile.cargo_type))
	on_cargo_change()
	return true

func try_pickup(delta) -> bool:
#	this should never be true with initial FSM
	if cargo.size() >= get_upgraded_cargo_max():
		sp_warning_no_cargo_space_sprite_3D.visible = true
		return false
	
	if not waypoint.stockpile.try_pickup(true, waypoint.cargo_count):
		sp_warning_confused.visible = true
		return false
	
	for i in waypoint.cargo_count:
		cargo.push_back(waypoint.stockpile.cargo_type)
	on_cargo_change()
	return true
	
func on_cargo_change():
	for i in sp_cargo_icons.size():
		var cargo_icon:Sprite3D = sp_cargo_icons[i]
		cargo_icon.visible = cargo.size() > i
		if cargo_icon.visible:
			cargo_icon.texture = load("res://Assets/Icons/%s.png" % cargo[i])
	

func _on_Drone_input_event(camera, event, position, normal, shape_idx):
	if Game.Data.deliver_phase:
		return
	
	if event is InputEventMouseButton:
		var mouse_event:InputEventMouseButton = event
		if (mouse_event.button_index == BUTTON_LEFT and
			mouse_event.pressed):
			on_mouse_left_button_click()

func on_mouse_left_button_click():
	emit_signal("Pressed", self)
	
	Game.Data.complete_tutorial_step("click_me_drone")
	Game.Map.map_ui.show_drone_popup(self)

func _on_Drone_mouse_entered():
	if Game.Data.deliver_phase:
		return
	scale = Vector3(1.25,1.25,1.25)

func _on_Drone_mouse_exited():
	if Game.Data.deliver_phase:
		return
	scale = Vector3.ONE
