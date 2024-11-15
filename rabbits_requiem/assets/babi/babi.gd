extends Node3D

signal babi_wants_to_die(location)

@export var cruches : Array[AudioStreamWAV]

@onready var body = $StaticBody3D
@onready var mumbling = $Mumbling
@onready var cruncher = $Crunch

var location : Vector2i 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	

func die():
	body.visible = false
	mumbling.playing = false
	#cruncher
	cruncher.stream = cruches[randi() % len(cruches)]
	cruncher.seek(0)
	cruncher.play()
	#continues in "_on_crunch_finished()"
	

func _on_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		babi_wants_to_die.emit(location)


func _on_crunch_finished() -> void:
	#print("I hav deid :(")
	queue_free()
