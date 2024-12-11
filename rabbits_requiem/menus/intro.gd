extends Control

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://tunnels.tscn")


func _on_button_pressed() -> void:
	$AnimationPlayer.set_speed_scale(10)
