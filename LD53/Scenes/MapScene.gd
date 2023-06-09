extends Spatial

class_name MapScene

export(NodePath) var np_map_ui
onready var map_ui = get_node(np_map_ui) as MapUI

export(NodePath) var np_water_animation_player
onready var sp_water_animation_player = get_node(np_water_animation_player) as AnimationPlayer

export var allow_keyboard_control: bool = true

func get_drone_placeholder():
	return get_node("Drones")
	
func get_building_placeholder():
	return get_node("Buildings")
				
func _ready():
	Game.new_game()
	Game.Map = self
	
	if sp_water_animation_player != null:
		sp_water_animation_player.play("Wave")
	
	if not allow_keyboard_control:
		Game.Data.start_delivery_phase(not allow_keyboard_control)

func _input(event):
	if allow_keyboard_control:
		if Input.is_action_just_released("ui_accept"):
			if not Game.Data.deliver_phase:
				Game.Data.start_delivery_phase()
			else:
				Game.Data.reset_delivery_phase()

func get_stockpile(node_path:NodePath):
	return $Buildings/StockpileNodePathSource.get_node(node_path)

func show_path(points:Array, color:Color):
	var multi_line = $Paths/DronePathMultiLine3D as MultiLine3D
	multi_line.points = points
	multi_line.rebuild()
	multi_line.visible = true
	color.a = 0.36
	multi_line.material.albedo_color = color
	
func hide_path():
	if $Paths/DronePathMultiLine3D != null:
		$Paths/DronePathMultiLine3D.visible = false
