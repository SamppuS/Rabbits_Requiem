extends Node3D

@export_subgroup("Meshes")
@export var player : Node3D
@export var tile_material : StandardMaterial3D
@export var selectable_dir : PackedScene
@export var minimap_scale := 0.3

@export_subgroup("Assets")
@export var walking_sounds : Array[AudioStreamWAV]


@onready var camTop = $Spelare/CamTop
@onready var camFP = $Spelare/CamFP
@onready var minimap_container = $Control/SubViewportContainer
@onready var subviewport = $Control/SubViewportContainer/SubViewport
@onready var minimap = $Control/SubViewportContainer/SubViewport/Minimap

@onready var audioplayer = $Spelare/AudioStreamPlayer3D


var grid: Array
var starting_point: Vector2i
var facing := 2
var cam_mode := 0
var current : Vector2i
var player_height := .2
var cam_default := Vector3(0, 150 ,0)
var cam_tilt : Vector3
var last_movement_dir := 5 # this might be the same as facing

var mesh_size = 1.73233866691589 - .05 # true size - gap between tiles
var tile_offset = mesh_size * 0.22

var s_dir_holder = []

var meshes: Array[Mesh]
var mesh_openings = [ #These are the right patterns but in the wrong phase. So they return the right tile but wrong rotation.
	[true, false, false, false, false, false],  # 10
	[true, false, false, false, false, true],   # 20
	[true, false, false, false, true, false],   # 21
	[true, false, false, true, false, false],   # 22
	[true, false, false, false, true, true],    # 30
	[true, false, false, true, false, true],    # 31
	[true, true, false, true, false, false],    # 32
	[true, false, true, false, true, false],    # 33
	[true, false, false, true, true, true],     # 40
	[true, false, true, true, true, false],     # 41
	[true, false, true, true, false, true]      # 42
]




func _ready(): # we probably don't have grid info here!
	var screen_size = get_viewport().get_visible_rect().size
	var minimap_size = screen_size * minimap_scale
	minimap_container.size = minimap_size
	minimap_container.position = Vector2(10, -200)
	subviewport.size = minimap_size
	## Set size and position
	#minimap_container.custom_minimum_size = Vector2(200, 200)  # Adjust size as needed
	#minimap_container.size = Vector2(200, 200)
	#minimap_container.position = Vector2(10, -210)  # Adjust position as needed
	# Get the minimap's SubViewport
	var minimap_viewport = subviewport
	minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	#minimap.send_grid.connect(_on_grid_received)
	
	# Save meshes under array "meshes"
	var dir = DirAccess.open("res://palikoita/Closed Meshes/")
	if dir:
		dir.list_dir_begin()
		var mesh_files = []
		while true:
			var file_name = dir.get_next()
			if file_name.substr(len(file_name)-3,len(file_name)) == "obj":
				mesh_files.append(file_name)
			if file_name == "":
				break
		dir.list_dir_end()
		# Sort the mesh files alphabetically
		mesh_files.sort()
		# Load the meshes in sorted order and store them in the meshes array
		meshes = []  # Clear the meshes array before loading
		for file_name in mesh_files:
			meshes.append(load("res://palikoita/Closed Meshes/" + file_name))
	draw_cave()

func _on_minimap_send_grid(sent_grid: Variant, sp: Variant) -> void:
	grid = sent_grid
	starting_point = sp
	current = starting_point
	player.position = pos_from_tile(current) + Vector3(0,player_height,0)

func _input(event: InputEvent) -> void:
	if cam_mode == 1:
		if Input.is_action_just_pressed("d"): # turn left
			set_facing((facing + 1) % 6)

		elif Input.is_action_just_pressed("a"): # turn right
			set_facing((facing + 5) % 6)

		elif Input.is_action_just_pressed("w") and tile_obj(current).paths[facing]: # move forwards
			move(facing)
			
		elif Input.is_action_just_pressed("z"): # spawn direction blocks
			print("WE HAVE YOU SURROUNDED")
			surround()

	if Input.is_action_just_pressed("x"): # toggle cam
		change_cam()
			
	if event is InputEventMouseMotion: # looking around with mouse
		var screen_size = get_viewport().get_visible_rect().size
		var mouse_pos = get_viewport().get_mouse_position()
		cam_tilt = Vector3(mouse_pos.y / screen_size.y - .5, mouse_pos.x / screen_size.x - .5, 0) * Vector3(-40,-90,0)
	
	camFP.rotation_degrees = cam_default + cam_tilt 

func surround(): # spawn direction blocks around player
	for dir in range(6): # loop through possible directions
		var value = tile_obj(current).paths[dir]
		
		if value == true: 
			var norm = dir_to_norm(dir)
			var surrounder = selectable_dir.instantiate()
			
			surrounder.position = pos_from_tile(current) + norm * .5 + Vector3(0,player_height,0)
			add_child(surrounder)
			surrounder.look_at(surrounder.position + norm, Vector3.UP)
			surrounder.represent = dir
			
			s_dir_holder.append(surrounder)
			surrounder.connect("player_wants_to_move", _on_player_wants_to_move)

func scatter(): # despawn direction blocks
	for dir in s_dir_holder:
		dir.despawn()
	s_dir_holder = []

func move(dir: int): # move player in direction
	set_facing(dir)
	current = next_tile(current, dir)
	player.position = pos_from_tile(current) + Vector3(0,player_height,0) + dir_to_norm(flip_dir(facing)) * tile_offset
	last_movement_dir = dir
	scatter()
	play("walk")

func draw_cave():
	for y in range(len(grid)):
		for x in range(len(grid)):
			var tile = grid[y][x]
			var match = find_match(tile.paths)
			#print(tile.paths, match)
			if match[0] != -1:
				var palikka := MeshInstance3D.new()
				palikka.mesh = meshes[match[0]]
				palikka.position = pos_from_tile(tile.pos)
				palikka.rotation_degrees.y = 60*match[1]
				palikka.material_override = tile_material
				add_child(palikka)
				


func find_match(paths: Array[bool]): # from cave_tile.paths to mesh_openings index
	var paths_copy = paths.duplicate() # non-destructive
	var rotations = 0
	while true:
		if paths_copy in mesh_openings: # we have found a match!
			break
		elif paths_copy == paths and rotations > 0: # match will never be found (will return -1 on index 0)
			#print("no pair ??")
			break
		rotations += 1
		paths_copy.insert(0, paths_copy.pop_back()) #shift values by 1
	return [mesh_openings.find(paths_copy), rotations]

func pos_from_tile(pos : Vector2i) -> Vector3:
	return Vector3(-pos.x + pos.y%2*0.5, 0, float(pos.y) - pos.y * (1-sqrt(3)/2)) * mesh_size

func change_cam(mode: int = -1):
	if mode == 1:
		camFP.current = true
		cam_mode = 1
	elif mode == 0:
		camTop.current = true
		cam_mode = 0
	else:
		change_cam((cam_mode + 1) % 2) # whoa recursion!
		
		

func set_facing(dir: int):
	cam_default = Vector3(0, 150 - 60 * (dir-2),0)
	facing = dir
	camFP.rotation_degrees = cam_default + cam_tilt
	
func dir_to_norm(dir: int): # copy from minimap
	var normals = [
		Vector3(cos(0), 0, sin(0)),                  # (1, 0)
		Vector3(cos(PI / 3), 0, sin(PI / 3)),        # (1/2, √3 / 2)
		Vector3(cos(2 * PI / 3), 0, sin(2 * PI / 3)), # (-1/2, √3 / 2)
		Vector3(cos(PI), 0, sin(PI)),                # (-1, 0)
		Vector3(cos(4 * PI / 3), 0, sin(4 * PI / 3)), # (-1/2, -√3 / 2)
		Vector3(cos(5 * PI / 3), 0, sin(5 * PI / 3))  # (1/2, -√3 / 2)
	]
	return normals[dir]

func tile_obj(pos: Vector2i): # copy form minimap
	return grid[pos.y][pos.x]
	
func next_tile(pos : Vector2i, dir : int) -> Vector2i: # copy from minimap
	var right = pos.y % 2
	var newpos = pos
	match dir:
		0:
			newpos = pos + Vector2i(-1, 0)
		3:
			newpos = pos + Vector2i(1, 0)
		1:
			newpos = pos + Vector2i(-right, 1)
		2:
			newpos = pos + Vector2i(1-right, 1)
		4:
			newpos = pos + Vector2i(1-right, -1)
		5:
			newpos = pos + Vector2i(-right, -1)
	
	newpos = Vector2i(newpos.x, newpos.y)
	return newpos

func flip_dir(i: int): # copy from minimap
	return (i+3)%6

func _on_player_wants_to_move(direction) -> void:
	move(direction)
	#print("I swear bro, I moved ", direction)
	
func play(sound : String):
	if sound == "walk":
		audioplayer.stream = walking_sounds[randi() % len(walking_sounds)]
		audioplayer.seek(0)
		audioplayer.play()
