extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Visual blocker".modulate = Color("Black")
	$AnimationPlayer.play("Fade in")


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


func _on_h_slider_drag_ended(value_changed: bool) -> void:
	var slider = $"Settings buttons/Brightness slider"
	var label = $"Settings buttons/Label"
	var new = slider.value
	Settings.change(new)
	label.text = "Bringtness: " + str(new)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Fade out":
		get_tree().change_scene_to_file("res://menus/Intro.tscn")
