extends Spatial

export(NodePath) var np_animation_player
onready var sp_animation_player = get_node_or_null(np_animation_player) as AnimationPlayer

func popup():
	visible = true
	if (sp_animation_player != null and
			sp_animation_player.has_animation("Popup")):
				sp_animation_player.play("Popup")
