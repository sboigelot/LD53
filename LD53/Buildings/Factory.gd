extends Spatial

export(NodePath) var np_animation_player
export(NodePath) var np_money_animation_player
export(NodePath) var np_input_stockpile
export(NodePath) var np_output_stockpile
export(NodePath) var np_warning_no_input_sprite_3D
export(NodePath) var np_warning_no_output_space_sprite_3D

onready var sp_animation_player = get_node_or_null(np_animation_player) as AnimationPlayer
onready var sp_money_animation_player = get_node_or_null(np_money_animation_player) as AnimationPlayer
onready var sp_input_stockpile = get_node_or_null(np_input_stockpile) as Stockpile
onready var sp_output_stockpile = get_node_or_null(np_output_stockpile) as Stockpile
onready var sp_warning_no_input_sprite_3D = 		get_node(np_warning_no_input_sprite_3D) 		as Sprite3D
onready var sp_warning_no_output_space_sprite_3D = 	get_node(np_warning_no_output_space_sprite_3D) 	as Sprite3D

export var cycle_duration: float = 5.0
export var delay_between_cycle: float = 3.0
export var output_retry_delay: float = 0.5
export var cycle_warning_duration: float = -3.0
export var cycle_money_generation: int = 0

var current_cycle_remaining_duration: float
var current_cycle_paid: bool
var current_output_retry_delay: float
var current_delay_between_cycle: float

func _ready():
	sp_warning_no_input_sprite_3D.visible = false
	sp_warning_no_output_space_sprite_3D.visible = false

func _process(delta):
	
	if not Game.Data.deliver_phase:
		return
		
	if not visible:
		return
		
	if current_delay_between_cycle > 0:
		current_delay_between_cycle -= delta
		return
		
	if not current_cycle_paid:
		sp_warning_no_input_sprite_3D.visible = true
		current_cycle_paid = try_pay_cycle_if_needed()
		if current_cycle_paid:
			start_new_cycle()
			return
	
	if current_output_retry_delay > 0:
		current_output_retry_delay -= delta
		return
	
	if current_cycle_paid:
		progress_cycle(delta)
		
func try_pay_cycle_if_needed() -> bool:
	if current_cycle_paid:
		return true
	
	if sp_input_stockpile == null:
		return true
	
	if sp_input_stockpile.try_reserve_cargo(1):
		if sp_input_stockpile.try_pickup(true, 1):
			return true
	
	return false
	
func start_new_cycle():
	current_cycle_remaining_duration = cycle_duration
	if not sp_animation_player.is_playing():
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
	current_delay_between_cycle = delay_between_cycle
	
	if cycle_money_generation != 0:
		Game.Data.money += cycle_money_generation
		sp_money_animation_player.play("CoinUp")
	
func produce_output() -> bool:
	if sp_output_stockpile == null:
		return true
		
	if sp_output_stockpile.try_deliver(false, 1):
		return true
					
	return false


func _on_MoneyAnimationPlayer_animation_finished(anim_name):
	sp_money_animation_player.play("RESET")
