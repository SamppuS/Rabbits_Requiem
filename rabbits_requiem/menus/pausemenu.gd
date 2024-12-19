extends CanvasLayer

var paused = false  # Add at top of script
var pausable = true

@onready var slider = $"CenterContainer/Settings buttons/Brightness slider"
@onready var slider_label = $"CenterContainer/Settings buttons/Label"


# Called when the node enters the scene tree for the first time.
@onready var vbox = $CenterContainer/VBoxContainer
func _ready() -> void:
	visible = false
	#vbox.size_flags_horizontal = Control.SIZE_FILL
	slider.value = Settings.gamma
	slider_label.text = "Bringtness: " + str(slider.value)
	
	$"CenterContainer/Settings buttons/Brightness slider".value = Settings.gamma
	$"CenterContainer/Settings buttons/Label".text = "Bringtness: " + str(Settings.gamma)
	
	
	var volume = AudioServer.get_bus_volume_db(0)
	$"CenterContainer/Settings buttons/Volume slider".value = volume
	volume = round(100 * (volume + 45) / 55)
	$"CenterContainer/Settings buttons/Label2".text = "Volume: " + str(volume)
	
	if Settings.debugger: $Label.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event):
	if event.is_action_pressed("esc") and pausable: # ESC key
		toggle_pause()

func toggle_pause():
	paused = !paused
	get_tree().paused = paused
	visible = paused  # Show/hide menu


func _on_resume_pressed() -> void:
	toggle_pause()


func _on_settings_pressed() -> void:
	$"CenterContainer/Main buttons".visible = false
	$"CenterContainer/Settings buttons".visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()
	

func _on_close_pressed() -> void:
	$"CenterContainer/Main buttons".visible = true
	$"CenterContainer/Settings buttons".visible = false


func _on_main_menu_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://menus/mainmenu.tscn")


func _on_tunnels_jumping_scaring() -> void:
	pausable = false


func _on_volume_slider_value_changed(value: float) -> void:
	var fake_value = round($"CenterContainer/Settings buttons/Volume slider".ratio * 100)
	$"CenterContainer/Settings buttons/Label2".text = "Volume: " + str(fake_value)
	AudioServer.set_bus_volume_db(0, value)


func _on_brightness_slider_value_changed(value: float) -> void:
	var new = slider.value
	Settings.change(new)
	slider_label.text = "Bringtness: " + str(new)
