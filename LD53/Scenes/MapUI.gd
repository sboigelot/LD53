extends CanvasLayer


export(NodePath) var np_money_label

onready var ui_money_label = get_node(np_money_label) as Label

func _process(delta):
	ui_money_label.text = str(Game.Data.money)
