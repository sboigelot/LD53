tool
extends Spatial

class_name HoverLabel3D

export var text: String = "Click Me!"

export(NodePath) var np_animation_player
onready var sp_anomation_player = get_node(np_animation_player) as AnimationPlayer

func _process(delta):
	get_node("Label").text = text

func popup():
	if visible:
		return
		
	visible = true
	sp_anomation_player.play("Hover")
	
func hide():
	if not visible:
		return
		
	visible = false
	sp_anomation_player.stop(true)
