tool
extends Spatial

export var completed:bool = false setget set_completed

func set_completed(value:bool):
	completed = value
	get_node("RedCube").visible = not value
	get_node("GreenCube").visible = value
