extends Node3D

var grid: Array
var starting_point: Vector2i

var meshes: Array[PackedScene]
var mesh_openings = [ #These are the right patterns but in the wrong phase. So they return the right tile but wrong rotation.
	[true, false, false, false, false, false],  # 10
	[true, true, false, false, false, false],   # 20 
	[true, false, true, false, false, false],   # 21
	[true, false, false, true, false, false],   # 22
	[true, true, true, false, false, false],    # 30
	[true, true, false, true, false, false],    # 31
	[true, false, false, true, false, true],    # 32
	[true, false, true, false, true, false],    # 33
	[true, true, true, true, false, false],     # 40
	[true, true, true, false, true, false],     # 41
	[true, true, false, true, true, false]      # 42
]

func _ready(): # we probably don't have grid info here!
	var minimap = get_node("Minimap")
	minimap.send_grid.connect(_on_grid_received)
	
	# Save meshes under array "meshes"
	var dir = DirAccess.open("res://palikoita/Open models/")
	if dir:
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name.substr(len(file_name)-3,len(file_name)) == "glb":
				meshes.append(load("res://palikoita/Open models/" + file_name))
			if file_name == "":
				break
		dir.list_dir_end()
		
	for i in range(len(meshes)):
		#print(i, meshes[i].resource_path)
		pass


func _on_grid_received(new_grid, sp):
	grid = new_grid
	# Now you can use the received grid data
	print("Received new grid data: ", grid)


func _on_minimap_send_grid(sent_grid: Variant, sp: Variant) -> void:
	grid = sent_grid
	starting_point = sp
	for y in range(len(grid)):
		for x in range(len(grid)):
			print(grid[y][x].paths, find_match(grid[y][x].paths))

			
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
