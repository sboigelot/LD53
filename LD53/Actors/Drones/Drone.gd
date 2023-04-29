extends RigidBody

class_name Drone

export(NodePath) var np_warning_no_cargo_sprite_3D
export(NodePath) var np_warning_no_cargo_space_sprite_3D
export(NodePath) var np_warning_long_wait_time_sprite_3D
export(NodePath) var np_warning_confused

onready var sp_warning_no_cargo_sprite_3D = 		get_node(np_warning_no_cargo_sprite_3D) 		as Sprite3D
onready var sp_warning_no_cargo_space_sprite_3D = 	get_node(np_warning_no_cargo_space_sprite_3D) 	as Sprite3D
onready var sp_warning_long_wait_time_sprite_3D = 	get_node(np_warning_long_wait_time_sprite_3D)	as Sprite3D
onready var sp_warning_confused = 					get_node(np_warning_confused)					as Sprite3D

export var speed:float = 4.0
export var take_off_speed:float = 2.0
export var cargo_max:int = 1
export var memory_size:int = 3

export var flight_y: int = 10
const destination_snap_distance: float = 0.1 

export var cargo: PoolStringArray = []

export var route: Array = []
var route_index: int = 0 

var waypoint: WaypointData
var waypoint_parking_spot_id: int
var waypoint_parking_registered: bool
const parking_speration: float = 0.5
var waypoint_reached: bool
var waypoint_reserved: bool
var waypoint_parking_unregistered: bool
var waypoint_landed: bool
var waypoint_pickup_or_delivered: bool

var wait_for_waypoint: float
const max_wait_for_waypoint: float = 10.0

func _ready():
	sp_warning_no_cargo_sprite_3D.visible = false
	sp_warning_no_cargo_space_sprite_3D.visible = false
	sp_warning_long_wait_time_sprite_3D.visible = false
	sp_warning_confused.visible = false

func _physics_process(delta):
	if not Game.Data.deliver_phase:
		return
		
	if waypoint == null:
		waypoint = get_current_route_waypoint()
		if waypoint == null:
			return

	# 0: register waypoint parking spot
	if not waypoint_parking_registered:
		waypoint_parking_registered = register_waypoint_parking(delta)
		return

	# 1 goto waypoint next parking spot
	if not waypoint_reached:
		waypoint_reached = move_toward_waypoint(delta)
		return
		
	# 2 try reserve waypoint space
	if not waypoint_reserved:
		waypoint_reserved = reserve_waypoint(delta)
		return
	
	# 3 free waypoint parking spot
	if not waypoint_parking_unregistered:
		waypoint_parking_unregistered = unregister_waypoint_parking(delta)
		return
	
	# 4 land on waypoint
	if not waypoint_landed:
		waypoint_landed = land_on_waypoint(delta)
		return
	
	if not waypoint_pickup_or_delivered:
		# 5 pickup/deliver cargo
		waypoint_pickup_or_delivered = pickup_or_deliver(delta)
		return
			
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
	route_index = (route_index + 1) % route.size()
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
	
func move_toward_waypoint(delta) -> bool:
	
	var destination = Vector3(
		waypoint.stockpile.translation.x,
		flight_y + (parking_speration * waypoint_parking_spot_id),
		waypoint.stockpile.translation.z)
		
	var distance = translation.distance_to(destination)
	if distance < destination_snap_distance:
		return true
		
	if translation.y < destination.y:
		translation.y += (take_off_speed * delta)
#		return false
	
	var direction = translation.direction_to(destination)
	translate(direction * speed * delta)
	return false

func reserve_waypoint(delta) -> bool:
	if waypoint.stockpile.import:
		return try_reserve_delivery(delta)
	else:
		return try_reserve_pickup(delta)

func try_reserve_delivery(delta) -> bool:
	if not cargo.has(waypoint.stockpile.cargo_type):
		sp_warning_no_cargo_sprite_3D.visible = true
		return false
		
	if not waypoint.stockpile.try_reserve_space():
		wait_for_waypoint += delta
		sp_warning_long_wait_time_sprite_3D.visible = wait_for_waypoint > max_wait_for_waypoint
		return false
		
	return true

func try_reserve_pickup(delta) -> bool:
	if cargo.size() >= cargo_max:
		sp_warning_no_cargo_space_sprite_3D.visible = true
		return false
		
	if not waypoint.stockpile.try_reserve_cargo():
		wait_for_waypoint += delta
		sp_warning_long_wait_time_sprite_3D.visible = wait_for_waypoint > max_wait_for_waypoint
		return false
		
	return true

func unregister_waypoint_parking(delta) -> bool:
	if waypoint.stockpile.is_connected("DroneLeft", self, "on_stockpile_drone_left"):
		waypoint.stockpile.disconnect("DroneLeft", self, "on_stockpile_drone_left")
	waypoint.stockpile.unregister_waiting()
	return true
	
func land_on_waypoint(delta) -> bool:
	if translation.y > waypoint.stockpile.translation.y:
		translation.y -= (take_off_speed * delta)
		return false
	
	return true
	
func pickup_or_deliver(delta)->bool:
	if waypoint.stockpile.import:
		return try_deliver(delta)
		
	return try_pickup(delta)
	
func try_deliver(delta) -> bool:
#	this should never be true with initial FSM
	if not cargo.has(waypoint.stockpile.cargo_type):
		sp_warning_no_cargo_sprite_3D.visible = true
		return false
		
	if not waypoint.stockpile.try_deliver():
		wait_for_waypoint += delta
		sp_warning_long_wait_time_sprite_3D.visible = wait_for_waypoint > max_wait_for_waypoint
		return false
	
	cargo.remove(cargo.rfind(waypoint.stockpile.cargo_type))
	return true

func try_pickup(delta) -> bool:
#	this should never be true with initial FSM
	if cargo.size() >= cargo_max:
		sp_warning_no_cargo_space_sprite_3D.visible = true
		return false
	
	if not waypoint.stockpile.try_pickup():
		sp_warning_confused.visible = true
		return false
		
	cargo.push_back(waypoint.stockpile.cargo_type)
	return true
	
