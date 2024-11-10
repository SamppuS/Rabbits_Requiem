extends Node3D

@export var player : Node3D
@export var tile_material : StandardMaterial3D

@onready var camTop = $Spelare/CamTop
@onready var camFP = $Spelare/CamFP

var grid: Array
var starting_point: Vector2i
var facing = 2
var cam_mode = 0
var current : Vector2i
var player_height = .2

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

var mesh_size = 1.73233866691589 - .01 # true size - gap between tiles


func _ready(): # we probably don't have grid info here!
	var minimap = get_node("Minimap")
	#minimap.send_grid.connect(_on_grid_received)
	
	# Save meshes under array "meshes"
	var dir = DirAccess.open("res://palikoita/Closed Meshes/")
	if dir:
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name.substr(len(file_name)-3,len(file_name)) == "obj":
				meshes.append(load("res://palikoita/Closed Meshes/" + file_name))
			if file_name == "":
				break
		dir.list_dir_end()
	draw_cave()

func _on_minimap_send_grid(sent_grid: Variant, sp: Variant) -> void:
	grid = sent_grid
	starting_point = sp
	current = starting_point
	player.position = pos_from_tile(current) + Vector3(0,player_height,0)

func _input(event: InputEvent) -> void:
	if cam_mode == 1:
		if Input.is_action_just_pressed("d"): # turn left
			facing = (facing + 1) % 6
			set_facing(facing)
			print(facing)
		elif Input.is_action_just_pressed("a"): # turn right
			facing = (facing + 5) % 6
			set_facing(facing)
			print(facing)
		elif Input.is_action_just_pressed("w") and tile_obj(current).paths[facing]:
			current = next_tile(current, facing)
			player.position = pos_from_tile(current) + Vector3(0,player_height,0)
			print("CHARGING!! ", current, facing)
			
	if Input.is_action_just_pressed("x"):
			change_cam()
		

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
	camFP.rotation_degrees.y = 150 - 60 * (dir-2)
	
func dir_to_norm(dir: int): # copy from minimap
	var normals = [
		Vector3(cos(0), 0, sin(0)),                  # (1, 0)
		Vector3(cos(PI / 3), 0, sin(PI / 3)),        # (1/2, √3 / 2)
		Vector3(cos(2 * PI / 3), 0, sin(2 * PI / 3)), # (-1/2, √3 / 2)
		Vector3(cos(PI), 0, sin(PI)),                # (-1, 0)
		Vector3(cos(4 * PI / 3), 0, sin(4 * PI / 3)), # (-1/2, -√3 / 2)
		Vector3(cos(5 * PI / 3), 0, sin(5 * PI / 3))  # (1/2, -√3 / 2)
	]

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
