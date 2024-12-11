extends CanvasLayer

#var paused = false  # Add at top of script
var action: String


# Called when the node enters the scene tree for the first time.
@onready var vbox = $CenterContainer/VBoxContainer
func _ready() -> void:
	visible = false
	#vbox.size_flags_horizontal = Control.SIZE_FILL


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func toggle_pause():
	#paused = !paused
	#get_tree().paused = paused
	#visible = paused  # Show/hide menu

func _on_settings_pressed() -> void: # this is main menu button. Too lazy to change function name
	action = "menu"
	$AnimationPlayer.play("Fade out")

func _on_quit_pressed() -> void:
	get_tree().quit()
	action = "quit"
	$AnimationPlayer.play("Fade out")


func _on_respawn_pressed() -> void:
	$AnimationPlayer.play("Fade out")


func _on_tunnels_game_over(type: String, count: int) -> void:
	if type == "eated":
		$"Control/Visual blocker".visible = true
		visible = true
		$AnimationPlayer.play("Fade in")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Fade out":
		if action == "quit":
			get_tree().quit()
		elif action == "menu":
			get_tree().change_scene_to_file("res://menus/mainmenu.tscn")
		else: 
			get_tree().change_scene_to_file("res://tunnels.tscn")
