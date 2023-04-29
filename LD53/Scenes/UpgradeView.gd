extends MarginContainer

class_name UpgradeView

signal Upgraded

export(Texture) var texture
export var upgrade_name: String
export var upgrade_cost: int
export var upgrade_current_level: int
export var upgrade_max_level: int

export(Color) var level_aquired_color
export(Color) var level_not_aquired_color

export(NodePath) var np_purchase_button
export(NodePath) var np_title_label
export(NodePath) var np_texture_rect
export(NodePath) var np_level_placeholder
export(NodePath) var np_cost_label

onready var ui_purchase_button = get_node(np_purchase_button) as Button
onready var ui_title_label = get_node(np_title_label) as Label
onready var ui_texture_rect = get_node(np_texture_rect) as TextureRect
onready var ui_level_placeholder = get_node(np_level_placeholder) as Container
onready var ui_cost_label = get_node(np_cost_label) as Label

func _ready():
	update_ui()

func update_ui():
	ui_title_label.text = upgrade_name
	ui_texture_rect.texture = texture
	for i in ui_level_placeholder.get_child_count():
		var level_color_rect = ui_level_placeholder.get_child(ui_level_placeholder.get_child_count() - i - 1) as ColorRect
		level_color_rect.color = level_aquired_color if i < upgrade_current_level else level_not_aquired_color
		level_color_rect.visible = i < upgrade_max_level
	
	ui_cost_label.text = str(upgrade_cost)

func _process(delta):
	var purchasable = Game.Data.money >= upgrade_cost
	ui_cost_label.modulate = level_aquired_color if purchasable else level_not_aquired_color
	ui_purchase_button.disabled = not purchasable

func _on_PurchaseButton_pressed():	
	var purchasable = Game.Data.money >= upgrade_cost
	if purchasable:
		Game.Data.money -= upgrade_cost
		emit_signal("Upgraded")
