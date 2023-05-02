extends Spatial

class_name Factory

signal Pressed(factory)

export var display_name: String

export(NodePath) var np_click_me
export(NodePath) var np_click_me_victory
export(NodePath) var np_animation_player
export(NodePath) var np_money_animation_player
export(NodePath) var np_input_stockpile
export(NodePath) var np_output_stockpile
export(NodePath) var np_storage_stockpile_container
export(NodePath) var np_warning_no_input_sprite_3D
export(NodePath) var np_warning_no_output_space_sprite_3D
export(NodePath) var np_delivery_target_placeholder

onready var sp_click_me 							= get_node(np_click_me) as HoverLabel3D
onready var sp_click_me_victory						= get_node(np_click_me_victory) as HoverLabel3D
onready var sp_animation_player 					= get_node_or_null(np_animation_player) as AnimationPlayer
onready var sp_money_animation_player 				= get_node_or_null(np_money_animation_player) as AnimationPlayer
onready var sp_input_stockpile 						= get_node_or_null(np_input_stockpile) as Stockpile
onready var sp_output_stockpile 					= get_node_or_null(np_output_stockpile) as Stockpile
onready var sp_storage_stockpile_container 			= get_node_or_null(np_storage_stockpile_container) as Spatial
onready var sp_warning_no_input_sprite_3D 			= get_node(np_warning_no_input_sprite_3D) 		as Spatial
onready var sp_warning_no_output_space_sprite_3D 	= get_node(np_warning_no_output_space_sprite_3D) 	as Spatial
onready var sp_delivery_target_placeholder 			= get_node(np_delivery_target_placeholder) 	as Spatial

export var cycle_pickup_delay: float = 1.0
var cycle_unpaid_delay_warning: float = 120.0 #disabled
export var cycle_duration: float = 5.0
export var delay_between_cycle: float = 3.0
export var output_retry_delay: float = 0.5
export var cycle_warning_duration: float = -3.0
export var cycle_money_generation: int = 0

export var unlock_condition_cargo_count: int = 0
export var unlock_condition_cargo_type: String

var victory_info_timer: float = 10.0 

var current_cycle_pickup_delay: float
var current_cycle_unpaid_timer: float
var current_cycle_remaining_duration: float
var current_cycle_cargo_reserved: bool
var current_cycle_paid: bool
var current_output_retry_delay: float
var current_delay_between_cycle: float

var delivery_phase_started: bool = false

func _ready():
	
	lock()
	
	if sp_warning_no_input_sprite_3D != null:
		sp_warning_no_input_sprite_3D.visible = false
		
	if sp_warning_no_output_space_sprite_3D != null:
		sp_warning_no_output_space_sprite_3D.visible = false
	
	yield(get_tree(),"idle_frame")
	register_game_goals()

func lock():
	if unlock_condition_cargo_count > 0:
		visible = false
		
func try_unlock():
	if unlock_condition_cargo_count == 0:
		visible = true
		return
	
	var game_count = Game.Data.get_delivery_count(unlock_condition_cargo_type)
	if game_count >= unlock_condition_cargo_count:
		visible = true
		popup()
		Game.Map.map_ui.play_achiement_animation()

func popup():	
	if (sp_animation_player != null and
		sp_animation_player.has_animation("Popup")):
			sp_animation_player.play("Popup")
				
func register_game_goals():
	if (sp_delivery_target_placeholder != null and
		sp_delivery_target_placeholder.get_child_count() > 0):
		if Game.Data != null:
			Game.Data.register_game_goal(self)
		
func reset_goals():
	if (sp_delivery_target_placeholder != null and
		sp_delivery_target_placeholder.get_child_count() > 0):
		for cube in sp_delivery_target_placeholder.get_children():
			cube.completed = false
	
func progress_goals(quantity:int):
	if (sp_delivery_target_placeholder != null and
		sp_delivery_target_placeholder.get_child_count() > 0):
		for cube in sp_delivery_target_placeholder.get_children():
			if not cube.completed:
				cube.completed = true
				quantity -= 1
				if quantity == 0:
					return

func get_total_goals_count() -> int:
	if sp_delivery_target_placeholder == null:
		return 0
	return sp_delivery_target_placeholder.get_child_count()

func get_completed_goals_count() -> int:
	var completed = 0
	if (sp_delivery_target_placeholder != null and
		sp_delivery_target_placeholder.get_child_count() > 0):
		for cube in sp_delivery_target_placeholder.get_children():
			if cube.completed:
				completed += 1
	return completed

func are_goals_completed() -> bool:
	return get_total_goals_count() == get_completed_goals_count()

func reset():
	if sp_warning_no_input_sprite_3D != null:
		sp_warning_no_input_sprite_3D.visible = false
		
	if sp_warning_no_output_space_sprite_3D != null:
		sp_warning_no_output_space_sprite_3D.visible = false
	
	current_cycle_unpaid_timer = 0
	current_cycle_remaining_duration = 0
	current_cycle_cargo_reserved = false
	current_cycle_paid = false
	current_output_retry_delay = 0
	current_delay_between_cycle = 0
	
#	reset_goals()
	
	if sp_input_stockpile != null:
		sp_input_stockpile.reset()
		
	if sp_output_stockpile != null:
		sp_output_stockpile.reset()
		
	if sp_storage_stockpile_container != null:
		for stockpile in sp_storage_stockpile_container.get_children():
			stockpile.reset(true)
		
	if (sp_animation_player.is_playing() and 
		sp_animation_player.current_animation != "Popup"):
		sp_animation_player.stop(true)
		
	if sp_money_animation_player != null and sp_money_animation_player.is_playing():
		sp_money_animation_player.stop(true)
	
func show_hide_click_me(delta):
	if sp_click_me != null:
		if Game.Data.is_tutorial_step("click_me_%s" % display_name.to_lower().replace(" ", "_")):
			sp_click_me.popup()
		else:
			sp_click_me.hide()
			
	if sp_click_me_victory != null:
		if Game.Data.is_tutorial_step("victory_info"):
			sp_click_me_victory.popup()
			victory_info_timer -= delta
			if victory_info_timer <= 0:
				Game.Data.complete_tutorial_step("victory_info")
		else:
			sp_click_me_victory.hide()
		
func _process(delta):
	
	show_hide_click_me(delta)
	
	if not Game.Data.deliver_phase:
		if sp_warning_no_input_sprite_3D != null:
			sp_warning_no_input_sprite_3D.visible = Game.Map.map_ui.waiting_for_factory_target != null
		if delivery_phase_started:
			reset()
		return
	delivery_phase_started = true
		
	if not visible:
		try_unlock()
		return
	
	if sp_storage_stockpile_container != null:
		transfert_stockpiles_to_output()
		return
		
	var game_delta = Game.Data.deliver_phase_speed * delta
	
	if current_delay_between_cycle > 0:
		current_delay_between_cycle -= game_delta
		return
		
	if not current_cycle_paid:
		current_cycle_unpaid_timer += game_delta
		sp_warning_no_input_sprite_3D.visible = current_cycle_unpaid_timer > cycle_unpaid_delay_warning
		current_cycle_paid = try_pay_cycle_if_needed(game_delta)
		if current_cycle_paid:
			start_new_cycle()
			return
	
	if current_output_retry_delay > 0:
		current_output_retry_delay -= game_delta
		return
	
	if current_cycle_paid:
		progress_cycle(game_delta)
		
func try_pay_cycle_if_needed(delta) -> bool:
	if current_cycle_paid:
		return true
	
	if sp_input_stockpile == null:
		return true
	
	if not current_cycle_cargo_reserved:
		current_cycle_cargo_reserved = sp_input_stockpile.try_reserve_cargo(1)
		if current_cycle_cargo_reserved:
			current_cycle_pickup_delay = cycle_pickup_delay
		return false
		
	current_cycle_pickup_delay -= delta
	if current_cycle_pickup_delay > 0:
		return false
	
	if sp_input_stockpile.try_pickup(true, 1):
		return true
	
	return false
	
func start_new_cycle():
	current_cycle_remaining_duration = cycle_duration
	if Game.building_jump and not sp_animation_player.is_playing():
		sp_animation_player.play("Cycle")
		
	sp_warning_no_input_sprite_3D.visible = false
	sp_warning_no_output_space_sprite_3D.visible = false

func progress_cycle(delta):
	current_cycle_remaining_duration -= delta
	if current_cycle_remaining_duration > 0:
		return
		
	var output_space_warning = current_cycle_remaining_duration < cycle_warning_duration
	sp_warning_no_output_space_sprite_3D.visible = output_space_warning
	if output_space_warning:
		current_output_retry_delay = output_retry_delay
		if sp_animation_player.is_playing():
			sp_animation_player.stop(true)
		
	current_cycle_paid = not produce_output()
	if not current_cycle_paid:
		complete_cycle()
		
func complete_cycle():
	
	if sp_animation_player.is_playing():
		sp_animation_player.stop(true)
		
	sp_warning_no_input_sprite_3D.visible = false
	sp_warning_no_output_space_sprite_3D.visible = false
	current_cycle_cargo_reserved = false
	current_delay_between_cycle = delay_between_cycle
	
func produce_output() -> bool:
	if sp_output_stockpile == null:
		return true
		
	if sp_output_stockpile.try_deliver(false, 1):
		return true
					
	return false

func _on_MoneyAnimationPlayer_animation_finished(anim_name):
	sp_money_animation_player.play("RESET")

func _on_StaticBody_mouse_entered():
	if Game.Data.deliver_phase:
		return
	
	scale = Vector3(1.20,1.20,1.20)

func _on_StaticBody_mouse_exited():
	if Game.Data.deliver_phase:
		return
	
	scale = Vector3.ONE

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
	Game.Data.complete_tutorial_step("click_me_%s" % display_name.to_lower().replace(" ", "_"))
	Game.Map.map_ui.on_factory_pressed(self)

func _on_Input_NewCargo(quantity:int):
	if cycle_money_generation != 0:
		Game.Data.add_money(cycle_money_generation * quantity)
		sp_money_animation_player.play("CoinUp")
		progress_goals(quantity)

func transfert_stockpiles_to_output():
	var inputs = {}
	var outputs = {}
	
	for stockpile in sp_storage_stockpile_container.get_children():
		if stockpile.import:
			inputs[stockpile.cargo_type] = stockpile
		else:
			outputs[stockpile.cargo_type] = stockpile
			
	for cargo_type in inputs:
		if not inputs.has(cargo_type):
			continue
			
		if not outputs.has(cargo_type):
			continue
			
		var in_stockpile:Stockpile = inputs[cargo_type]
		var out_stockpile:Stockpile = outputs[cargo_type]
		
		for i in in_stockpile.cargo_count:
			if not out_stockpile.has_free_space(1):
				break
			
			if out_stockpile.try_deliver(false, 1):
				in_stockpile.try_pickup(false, 1)
	
