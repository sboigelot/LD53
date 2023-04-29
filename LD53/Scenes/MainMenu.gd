extends Control

export(NodePath) var np_ui_audio_master
export(NodePath) var np_ui_audio_music
export(NodePath) var np_ui_audio_soundfx
export(NodePath) var np_better_ai_button

export(float) var volume_min = -40.0
export(float) var volume_max = 6.0

onready var ui_audio_master = get_node(np_ui_audio_master) as HSlider
onready var ui_audio_music = get_node(np_ui_audio_music) as HSlider
onready var ui_audio_soundfx = get_node(np_ui_audio_soundfx) as HSlider
onready var better_ai_button = get_node(np_better_ai_button) as Button

func _on_StartGameButton_pressed():
	SfxManager.play("buttonpress")
	Game.new_game()
	Game.data.better_ai = better_ai_button.pressed
	Game.transition_to_scene("res://scenes/WorldMap.tscn")

func _on_NoBombButton_pressed():
	SfxManager.play("buttonpress")
	Game.new_game()
	Game.data.no_bomb_challenge = true
	Game.data.better_ai = better_ai_button.pressed
	Game.transition_to_scene("res://scenes/WorldMap.tscn")

func _on_NoTaxesButton_pressed():
	SfxManager.play("buttonpress")
	Game.new_game()
	Game.data.no_taxes_challenge = true
	Game.data.better_ai = better_ai_button.pressed
	Game.transition_to_scene("res://scenes/WorldMap.tscn")
	
func _on_FullscreenButton_pressed():
	OS.window_fullscreen = !OS.window_fullscreen
	SfxManager.play("buttonpress")

func _ready():
	update_sound_sliders()
	
func update_sound_sliders():
	var master_volume:float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	var music_volume:float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	var sfx_volume:float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
	
	ui_audio_master.min_value = volume_min
	ui_audio_master.max_value = volume_max
	ui_audio_master.value = master_volume
	
	ui_audio_music.min_value = volume_min
	ui_audio_music.max_value = volume_max
	ui_audio_music.value = music_volume
	
	ui_audio_soundfx.min_value = volume_min
	ui_audio_soundfx.max_value = volume_max
	ui_audio_soundfx.value = sfx_volume
	
func _on_MasterVolumeSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)

func _on_MusicVolumeSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	
func _on_SoundFxVolumeSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)

func _on_MasterVolumeSlider_drag_ended(_value_changed):
	SfxManager.play("confirm")

func _on_MusicVolumeSlider_drag_ended(_value_changed):
	SfxManager.play("confirm")

func _on_SoundFxVolumeSlider_drag_ended(_value_changed):
	SfxManager.play("confirm")
