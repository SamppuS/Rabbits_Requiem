extends Node3D

@export_subgroup("Parameters")
@export var minimap_scale := 0.3
@export var babi_count : int = 10 # note: this needs to be lower than dead end count set in minimap! 
@export var min_roam_tiles = 7

@export_subgroup("Nodes+")
@export var player : Node3D
@export var tile_material : StandardMaterial3D


@export_subgroup("Scenes+")
@export var walking_sounds : Array[AudioStreamWAV]
@export var selectable_dir : PackedScene
@export var babi_scene : PackedScene
@export var entrance : PackedScene


@onready var camTop = $Spelare/CamTop
@onready var camFP = $Spelare/CamFP
@onready var minimap_container = $Control/SubViewportContainer
@onready var subviewport = $Control/SubViewportContainer/SubViewport
@onready var minimap = $Control/SubViewportContainer/SubViewport/Minimap

@onready var walk_player = $Spelare/WalkSoundplayer
@onready var snake : Node3D = $Snake


var grid: Array
var starting_point: Vector2i
var facing := 2
var cam_mode := 0
var current : Vector2i
const player_height := .2
var cam_default := Vector3(0, 150 ,0)
var cam_tilt : Vector3
var last_movement_dir := 5 # this might be the same as facing

var snak_target
var shine 
var shiny_tiles : Array[Vector2i]

const mesh_size = 1.73233866691589 - .05 # true size - gap between tiles
const tile_offset = mesh_size * 0.22

var snake_roam_distance = mesh_size * 6 # distance form start pos that snake is allowed to roam
var snake_roam_tiles : Array # specific roam tiles
var to_be_roamed : Array # variable to prevent snake camping

var s_dir_holder = []
var babi_holder = [[], []] # [[scenes], [rooms v2i]]
var dead_end_locations : Array[Vector2i]

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
	var environment = $WorldEnvironment.environment
	var screen_size = get_viewport().get_visible_rect().size
	var minimap_size = screen_size * minimap_scale
	var minimap_viewport = subviewport
	#minimap.send_grid.connect(_on_grid_received)
	
	# Save meshes under array "meshes"
	print("Saving meshes...")
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
	print("Drawing cave...")
	draw_cave()
	print("Spawning babis...")
	spawn_babis()
	print("Taking fist snak action...")
	snak_action("babi")
	print("Straightening snake...")
	snake.straighten()
	print("---")
	


func _on_minimap_send_grid(sent_grid: Variant, sp: Variant, dead_ends : Variant) -> void:
	print("grid has been recieved")
	grid = sent_grid
	starting_point = sp
	current = starting_point
	dead_end_locations = dead_ends
	player.position = pos_from_tile(current) + Vector3(0,player_height,0)
	
	# assign roam spots
	print("Making roam tiles...")
	while snake_roam_tiles.size() < min_roam_tiles and snake_roam_tiles.size() < dead_ends.size():
		for tile in dead_ends:
			if distance_in_vec3(tile, starting_point) < snake_roam_distance and tile not in snake_roam_tiles:
				snake_roam_tiles.append(tile)
		snake_roam_distance += mesh_size
		if snake_roam_distance > 1000:
			print("snake roam tiles were reduced to ", snake_roam_tiles.size(), " from ", min_roam_tiles)
			break
	
	# assign shine spots
	print("Making shine tiles...")
	shiny_tiles.append(starting_point)
	while tile_obj(shiny_tiles[-1]).paths[2]:
		shiny_tiles.append(next_tile(shiny_tiles[-1], 2))
	print("---")
	

func _input(event: InputEvent) -> void:
	if cam_mode == 1:
		if Input.is_action_just_pressed("d"): # turn left
			set_facing((facing + 1) % 6)

		elif Input.is_action_just_pressed("a"): # turn right
			set_facing((facing + 5) % 6)

		elif Input.is_action_just_pressed("w") and tile_obj(current).paths[facing]: # move forwards
			move(facing)
			
		elif Input.is_action_just_pressed("z"): # spawn direction blocks
			#print("WE HAVE YOU SURROUNDED")
			surround()

	if Input.is_action_just_pressed("x"): # toggle cam
		change_cam()
		
	if Input.is_action_just_pressed("e"): # snake new target
		snak_action("player")
	
			
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
	if current == starting_point and dir == 5: 
		return # Here would be leaving the game :)
	
	set_facing(dir)
	current = next_tile(current, dir)
	player.position = pos_from_tile(current) + Vector3(0,player_height,0) + dir_to_norm(flip_dir(facing)) * tile_offset
	last_movement_dir = dir
	scatter()
	play("walk")
	
	# check if player moved to snake sight
	if current in snake.sight: 
		snak_action("player")

	# check if player moved to shiny tile
	if current in shiny_tiles and last_movement_dir in [2,5]:
		shine.glare(true)
	else:
		shine.glare(false)

func draw_cave():
	for y in range(len(grid)):
		for x in range(len(grid)):
			var tile = grid[y][x]
			var match = find_match(tile.paths)
			if match[0] != -1:
				var palikka := MeshInstance3D.new()
				palikka.mesh = meshes[match[0]]
				palikka.position = pos_from_tile(tile.pos)
				palikka.rotation_degrees.y = 60*match[1]
				palikka.material_override = tile_material
				add_child(palikka)
	
	shine = entrance.instantiate()
	shine.position = pos_from_tile(starting_point) + tile_offset * dir_to_norm(5) + Vector3.UP * player_height
	add_child(shine)
	shine.look_at(shine.position + dir_to_norm(5), Vector3.UP)

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
	
	var environment = $WorldEnvironment.environment
	if mode == 1:
		camFP.current = true
		cam_mode = 1
		environment.set_background(5) # temp fix probably
		environment.volumetric_fog_enabled = true
	elif mode == 0:
		camTop.current = true
		cam_mode = 0
		environment.set_background(0) # temp fix probably
		environment.volumetric_fog_enabled = false
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
	
	if next_tile(current, direction) in snake.snake_tiles.slice(-2, -1): return
	if current in snake.snake_tiles:
		
		#print("shiver me timbers")
		
		
		var past_dir = flip_dir(last_movement_dir)
		var can_move_here = [false, false, false, false, false, false]
		can_move_here[past_dir] = true
		
		for dir in range(1,5):
			
			if can_move_here[(past_dir + dir - 1) % 6] == true and next_tile(current, (past_dir + dir) % 6) not in snake.snake_tiles:
				can_move_here[(past_dir + dir) % 6] = true
			if can_move_here[(past_dir - dir + 1) % 6] == true and next_tile(current, (past_dir - dir) % 6) not in snake.snake_tiles:
				can_move_here[(past_dir - dir) % 6] = true
			#print(can_move_here)
		
		if !can_move_here[direction]: return
		
		#print("giga chad move bro")
		
	move(direction)
	
func play(sound : String):
	if sound == "walk":
		walk_player.stream = walking_sounds[randi() % len(walking_sounds)]
		walk_player.seek(0)
		walk_player.play()

func spawn_babis():
	dead_end_locations.shuffle() # randomize order
	for location in dead_end_locations.slice(0, babi_count): # pick [babi_count] "random" dead ends
		var babi = babi_scene.instantiate()
		var norm = dir_to_norm((tile_obj(location).paths.find(true)))
		
		babi.position = pos_from_tile(location) + Vector3(0,.035,0)
		add_child(babi)
		babi.look_at(babi.position + norm + Vector3(0,player_height,0), Vector3.UP)
		babi_holder[0].append(babi)
		babi_holder[1].append(location)
		babi.connect("babi_wants_to_die", _on_babi_wants_to_die)
		babi.location = location
	print("there are ", len(babi_holder[0]), " babis, how cute!")
	
func _on_babi_wants_to_die(location):
	if current.distance_to(location) == 0:
		kill_babi(location)
			
func kill_babi(location):
	
	
	var babindex = babi_holder[1].find(location)
	var babi = babi_holder[0][babindex]
	babi_holder[0].pop_at(babindex)
	babi_holder[1].pop_at(babindex)
	babi.die() # :(
	print("We lost a good one today. ", len(babi_holder[0]), " babis remain o7")
	
	if snak_target == location:
		snak_action() # possible trouble maker
	

func a_star(start: Vector2i, target: Vector2i) -> Array:
	
	var to_search = {} # dictionary for tiles to search
	var processed = {} # dictionary for tiles that don't need to be searched
	
	# define first tile:
	to_search[start] = {"G": 0,"H": distance_in_vec3(start,target)}
	to_search[start]["F"] = to_search[start]["G"] + to_search[start]["H"]
	
	while !to_search.is_empty():
		
		# find best tile to search
		var checking = to_search.keys()[0]
		for tile in to_search: 
			if to_search[tile]["F"] < to_search[checking]["F"] or (to_search[tile]["F"] == to_search[checking]["F"] and to_search[tile]["H"] < to_search[checking]["H"]):
				checking = tile
	
		# put current to processed
		processed[checking] = to_search[checking]
		to_search.erase(checking)
		
		if checking == target:
			var current_path_tile = target
			var path = []
			while current_path_tile != start:
				path.append(current_path_tile)
				if current_path_tile in to_search.keys():
					current_path_tile = to_search[current_path_tile]["C"]
				else:
					current_path_tile = processed[current_path_tile]["C"]
			path.append(start)
			path.reverse()
			return path
		
		
		# Loop through neighbours
		for dir in range(6):
			if checking == starting_point and dir == 5: continue # snake cant go through entrance lol
			var neighbour = next_tile(checking, dir)
			if tile_obj(checking).paths[dir] == false or neighbour in processed: continue
			
			var in_search = neighbour in to_search.keys() # is the neighbour already in "to_search"
			var cost_to_neighbour = processed[checking]["G"] + distance_in_vec3(checking, neighbour)
			
			if neighbour in snake.goals[1]:
				cost_to_neighbour += 5000 # NO OVERLAPPING
	
			if !in_search:
				to_search[neighbour] = {"G": cost_to_neighbour,"H": distance_in_vec3(neighbour, target),"C": checking}
				to_search[neighbour]["F"] = to_search[neighbour]["G"] + to_search[neighbour]["H"]
				
			elif cost_to_neighbour < to_search[neighbour]["G"]:
				to_search[neighbour]["G"] = cost_to_neighbour
				to_search[neighbour]["C"] = checking
				to_search[neighbour]["F"] = to_search[neighbour]["G"] + to_search[neighbour]["H"]
			
	return []


func distance_in_vec3(start: Vector2i, target: Vector2i):
	return pos_from_tile(start).distance_to(pos_from_tile(target))
	

func _on_snake_snaking_complete() -> void:
	if snak_target in babi_holder[1]:
		kill_babi(snak_target)
	snak_action() # trouble maker 2
	
func  snak_action(action : String = ""):
	var start
	
	# check for snake starting pos
	if snake.goals[0].is_empty():
		start = starting_point
	else:
		start = snake.next[1]
		snake.clear_path()
	
	if to_be_roamed.is_empty():
		to_be_roamed = snake_roam_tiles.duplicate()
	
	# choose target
	match action:
		"player": # hunt player
			if snak_target != current:
				snake.alert()
			snak_target = current
			
		"babi": # hunt babi
			# find furthest babi (this is to prevent bugs caused from first babi being near start area)
			var furthest
			var max_distance = 0
			for babi in range(babi_holder.size()):
				var distance = distance_in_vec3(babi_holder[1][babi], starting_point)
				if  distance > max_distance:
					max_distance = distance
					furthest = babi_holder[1][babi]
					
			snak_target = furthest
		_:
			if babi_holder[0].size() > 0:
				snak_target = babi_holder[1][randi() % babi_holder[0].size()]
			else: # roam
				snak_target = to_be_roamed[randi() % to_be_roamed.size()]
				to_be_roamed.remove_at(to_be_roamed.find(snak_target))

	# pathfind
	var path = a_star(start, snak_target)
	for i in path: 
		snake.add_destination(pos_from_tile(i), i)
		

#func pull_map():
	#minimap_container.size = minimap_size
	#minimap_container.position = Vector2(10, -200)
	#subviewport.size = minimap_size
	#minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _on_snake_snake_moved() -> void:
	if current in snake.sight and (babi_holder[0].size() != babi_count or snake.next[2]>3):
		#print("player seen!")
		await get_tree().create_timer(0.1).timeout # wait fixed weird generation bug
		snak_action("player")
