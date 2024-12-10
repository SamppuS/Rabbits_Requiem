extends CanvasLayer

var won = false  # Add at top of script

# Called when the node enters the scene tree for the first time.
@onready var vbox = $CenterContainer/VBoxContainer
func _ready() -> void:
	visible = false
	vbox.size_flags_horizontal = Control.SIZE_FILL


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/mainmenu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_tunnels_game_over(type: String, count: int) -> void:
	won = true
	visible = true
