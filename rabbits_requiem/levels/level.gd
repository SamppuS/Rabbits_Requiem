extends Node3D

@export var grid_size : int = 50
@export var tile_mesh : PackedScene
@export var cave_mesh : PackedScene

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

func _input(event):
	
	var last_current = current
	if Input.is_action_just_pressed("q"):
		current = next_tile(current, 0)
	if Input.is_action_just_pressed("w"):
		current = next_tile(current, 1)
	if Input.is_action_just_pressed("e"):
		current = next_tile(current, 2)
	if Input.is_action_just_pressed("d"):
		current = next_tile(current, 3)
	if Input.is_action_just_pressed("s"):
		current = next_tile(current, 4)
	if Input.is_action_just_pressed("a"):
		current = next_tile(current, 5)
	
	if current != last_current: print(current); get_node("Spelare").position = pos_from_tile(current)

func generate_maze():
	
	var sp = Vector2i(randi()%grid_size, randi()%grid_size)
	
	var next = grid[sp.y][sp.x].next_paths()
	var next_tiles = []
	for d in next:
		next_tiles.append(
			next_tile(sp, d)
		)
	
	var i = 0
	while len(next_tiles) != 0 and i < 20:
		i += 1
		
		var new_tiles = []
		for tile in next_tiles:
			var tile_obj = grid[tile.y][tile.x]
			if true in tile_obj.paths: continue
	
			var nextpathed : int = 0
			for posdir in range(6):
				var surrounding_pos = next_tile(tile, posdir)
				var surrounding_tile = grid[surrounding_pos.y][surrounding_pos.x]
				if true in surrounding_tile.paths: nextpathed+=1
			if nextpathed > 2: continue
			
			next = tile_obj.next_paths()
			for d in next:
				new_tiles.append(
					next_tile(tile, d)
				)
		
		next_tiles = new_tiles
	
	for y in range(grid_size):
		for x in range(grid_size):
			if not true in grid[y][x].paths: continue
			var tt := cave_mesh.instantiate()
			tt.position = pos_from_tile(Vector2i(x,y))
			add_child(tt)

func pos_from_tile(pos : Vector2i) -> Vector3:
	return Vector3(-pos.x + pos.y%2*0.5, 0, pos.y)

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
