extends Node

var last_screenshot_os_path = ""

var photo_shoot: bool = false
var photo_shoot_delay: float = 5

func _ready():
	var dir = Directory.new()
	if not dir.dir_exists("user://Screenshots"):
		dir.make_dir("user://Screenshots")
	
	if photo_shoot:
		do_photo_shoot()

func do_photo_shoot():
	while true:
		yield(get_tree().create_timer(photo_shoot_delay), "timeout")
		take_screenshot("user://Screenshots")
		
func _input(event):
	if event.is_action_pressed("screenshot"):
		take_screenshot("user://Screenshots")
		
func take_screenshot(path, filename = ""):
		# start screen capture
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		var time = OS.get_datetime(false)
		if filename == "":
			filename = "screensihot_%s_%s_%s_%s%s%s" % [
				time.year,
				time.month,
				time.day,
				time.hour,
				time.minute,
				time.second,
			]
		
		filename = "%s.png" % filename
			
		var fullpath = "%s/%s" % [path, filename]
		image.save_png(fullpath)
		
		var screenshot_dir_os_path = "%s/%s/" % [
			OS.get_user_data_dir(),
			path.replace("user://","")
		]
		last_screenshot_os_path = "%s%s" % [
			screenshot_dir_os_path,
			filename]
		print("Screenshot saved in %s" % last_screenshot_os_path)
