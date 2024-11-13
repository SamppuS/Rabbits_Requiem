extends Node3D

signal player_wants_to_move(direction)


@onready var mesh_instance = $StaticBody3D/CollisionShape3D/MeshInstance3D

var new_material

var represent : int # holds information about direction

func _ready():
	new_material = StandardMaterial3D.new()
	new_material.albedo_color = Color("#646464")
	mesh_instance.material_override = new_material


func _on_static_body_3d_mouse_entered() -> void:
	print("great heavens!")
	mesh_instance.material_override.albedo_color = Color("#37ff94")


func _on_static_body_3d_mouse_exited() -> void:
	print("barnicles!")
	mesh_instance.material_override.albedo_color = Color("#646464")


func _on_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#print("YOU HAVE CHOSEN ", represent)
		player_wants_to_move.emit(represent)

func despawn():
	queue_free()
