extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Visual blocker".modulate = Color("Black")
	$AnimationPlayer.play("Fade in")

	var volume = AudioServer.get_bus_volume_db(0)
	$"Settings buttons/Volume slider".value = volume
	volume = round(100 * (volume + 45) / 55)
	$"Settings buttons/Label2".text = "Volume: " + str(volume)

	$"Settings buttons/HBoxContainer2/CheckButton".button_pressed = Settings.debugger

	$"Settings buttons/Brightness slider".value = Settings.gamma
	$"Settings buttons/Label".text = "Bringtness: " + str(Settings.gamma)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	$AnimationPlayer.play("Fade out")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	$"Settings buttons".visible = true
	$"Menu buttons".visible = false


func _on_close_pressed() -> void:
	$"Settings buttons".visible = false
	$"Menu buttons".visible = true


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Fade out":
		get_tree().change_scene_to_file("res://menus/Intro.tscn")


func _on_credits_pressed() -> void:
	$Credits.visible = true
	$"Menu buttons".visible = false
	$Label.visible = false

func _on_back_pressed() -> void:
	$Credits.visible = false
	$"Menu buttons".visible = true
	$Label.visible = true
	

func _on_volume_slider_value_changed(value: float) -> void:
	var fake_value = round($"Settings buttons/Volume slider".ratio * 100)
	$"Settings buttons/Label2".text = "Volume: " + str(fake_value)
	AudioServer.set_bus_volume_db(0, value)


func _on_brightness_slider_value_changed(value: float) -> void:
	var new = $"Settings buttons/Brightness slider".value
	Settings.change(new)
	$"Settings buttons/Label".text = "Bringtness: " + str(new)


func _on_check_button_toggled(toggled_on: bool) -> void:
	Settings.debugger = toggled_on
