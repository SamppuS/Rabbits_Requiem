extends CanvasLayer

@export var victory_phases: Array[CompressedTexture2D]


var won = false  # Add at top of script

# Called when the node enters the scene tree for the first time.
@onready var vbox = $CenterContainer/VBoxContainer
func _ready() -> void:
	visible = false
	#vbox.size_flags_horizontal = Control.SIZE_FILL


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_main_menu_pressed() -> void:
	$AnimationPlayer.play("Fade out")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_tunnels_game_over(type: String, count: int) -> void:
	if type == "left":
		won = true
		visible = true
		$AnimationPlayer.play("Fade in")
		$Control/TextureRect.texture = victory_phases[-1]


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Fade out":
		get_tree().change_scene_to_file("res://menus/mainmenu.tscn")
