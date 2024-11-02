extends Node3D

@export_category("Exports")
@export_subgroup("Maze Settings")
@export var grid_size : int = 30

@export_subgroup("Meshes")
@export var tile_mesh : PackedScene
@export var cave_mesh : PackedScene
@export var sp_mesh : PackedScene
@export var dir_mesh : PackedScene

@export_subgroup("Nodes")
@export var player : Node3D


var grid = []
var current : Vector2i


func _ready():
	
	# Generate grid
	var row = []
	
	grid.resize(grid_size)
	for y in range(grid_size):
		grid[y]=[]
		grid[y].resize(grid_size)
		for x in range(grid_size):
			var tt := tile_mesh.instantiate()
			tt.position = pos_from_tile(Vector2i(x,y))
			add_child(tt)
			grid[y][x] = CaveTile.new()
			grid[y][x].pos = Vector2i(x, y)
			#print(x," - ", y)
	
	
	current = Vector2i(randi()%grid_size, randi()%grid_size)
	generate_maze()
	
	player.position = pos_from_tile(current)
	

func _input(event):
	
	var last_current = current
	var next_dir : int
	var move = false #prevent double movements
	
	if Input.is_action_just_pressed("a"):
		next_dir = 0
		move = true
	elif Input.is_action_just_pressed("w"):
		next_dir = 1
		move = true
	elif Input.is_action_just_pressed("e"):
		next_dir = 2
		move = true
	elif Input.is_action_just_pressed("d"):
		next_dir = 3
		move = true
	elif Input.is_action_just_pressed("x"):
		next_dir = 4
		move = true
	elif Input.is_action_just_pressed("z"):
		next_dir = 5
		move = true
	
	if tile_obj(current).paths[next_dir] && move: current = next_tile(current, next_dir);
	
	if current != last_current: 
		print(current, tile_obj(current).paths); 
		player.position = pos_from_tile(current)

func flip_dir(i: int):
	return (i+3)%6

func generate_maze():
	
	#random start pos
	var sp = current
	
	#draw sp mesh
	var sp_tt := sp_mesh.instantiate()
	sp_tt.position = pos_from_tile(sp)
	add_child(sp_tt)
	
	#generate 2 new tiles from sp
	var next = tile_obj(sp).next_paths()
	var next_tiles = []
	for d in next:
		var new = next_tile(sp, d)
		tile_obj(new).add_dir(flip_dir(d)) #add entraces to new tiles
		next_tiles.append(new)
	
	#start generating new tiles until we have 20.
	var i = 0
	while len(next_tiles) != 0 and i < 20:
		i += 1
		
		var new_tiles = []
		for tile in next_tiles:
			var tile_obj = tile_obj(tile) #grid[tile.y][tile.x]
			if tile_obj.paths.filter(func(item): return item).size() > 1: continue #skip if tile already has ANY direction written
	
			#skip if tile already has 2 or more neighbours
			var neighbours : int = 0
			for dir in range(6):
				var surrounding_pos = next_tile(tile, dir)
				var surrounding_tile = tile_obj(surrounding_pos) #grid[surrounding_pos.y][surrounding_pos.x]
				if true in surrounding_tile.paths: neighbours+=1
			if neighbours > 2: continue
			
			#generate cave
			next = tile_obj.next_paths()
			for d in next:
				var new = next_tile(tile, d)
				tile_obj(new).add_dir(flip_dir(d)) #add entraces to new tiles
				new_tiles.append(new)
		
		next_tiles = new_tiles
	
	#draw cave icons
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if not true in tile.paths: continue
			var tt := cave_mesh.instantiate()
			tt.position = pos_from_tile(Vector2i(x,y))
			add_child(tt)
			
			#draw directional blobs
			for dir in range(6):
				if tile.paths[dir]:
					var ttt := dir_mesh.instantiate()
					ttt.position = pos_from_tile(tile.pos) + dir_to_norm(dir) * 0.35
					add_child(ttt)

func pos_from_tile(pos : Vector2i) -> Vector3:
	return Vector3(-pos.x + pos.y%2*0.5, 0, float(pos.y) - pos.y * (1-sqrt(3)/2))

func tile_obj(pos: Vector2i):
	return grid[pos.y][pos.x]

func next_tile(pos : Vector2i, dir : int) -> Vector2i:
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
	
	newpos = Vector2i(newpos.x%grid_size, newpos.y%grid_size)
	if newpos.x < 0: newpos.x = grid_size-newpos.x-2
	if newpos.y < 0: newpos.y = grid_size-newpos.y-2
	return newpos

func dir_to_norm(dir: int):
	var normals = [
		Vector3(cos(0), 0, sin(0)),                  # (1, 0)
		Vector3(cos(PI / 3), 0, sin(PI / 3)),        # (1/2, √3 / 2)
		Vector3(cos(2 * PI / 3), 0, sin(2 * PI / 3)), # (-1/2, √3 / 2)
		Vector3(cos(PI), 0, sin(PI)),                # (-1, 0)
		Vector3(cos(4 * PI / 3), 0, sin(4 * PI / 3)), # (-1/2, -√3 / 2)
		Vector3(cos(5 * PI / 3), 0, sin(5 * PI / 3))  # (1/2, -√3 / 2)
	]

	return normals[dir]
