extends Control

var paused = false  # Add at top of script

# Called when the node enters the scene tree for the first time.
@onready var vbox = $CenterContainer/VBoxContainer
func _ready() -> void:
	visible = false
	vbox.size_flags_horizontal = Control.SIZE_FILL


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func toggle_pause():
	paused = !paused
	get_tree().paused = paused
	visible = paused  # Show/hide menu

func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_respawn_pressed() -> void:
	get_tree().change_scene_to_file("res://tunnels.tscn")
