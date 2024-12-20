extends Node2D
signal send_grid(grid, sp, dead_ends)


@export_category("Exports")
@export_subgroup("Maze Settings")
@export var cave_depth : int = 11 # generates cave systems that are n steps away from sp.
@export var average_tile_count : int = 100 # the closer the av_tilecount is to cave depth tile average, the faster cave is generated 
@export var max_variance: int = 10 # higher variance leads to faster cave generation but more random results

@export var traffic_limit: int = 20 # controls how densely caves are generated (around 20 seems good!!!)

@export var min_dead_ends: int = 20 # this is to allow for more babi spawns
@export var min_loops: int = 13 #20 # this is to allow for more babi spawns

# Varying the ratio between cave_depth and average_tile_count leads to differently shaped caves!
# Examples:
#   - high ratio leads to more cross roads and dead ends
#   - low ratio leads to more straight caves and less dead ends
#
# Good combinations: 
# 14 : 80 : 10 = seems like a good balance
# 8 : 100 : 10 = leads to less deep but more maze like structure
# n>50 : ? : n>10000 = leads to huge caves FAST!!

var grid_size = (cave_depth+1) * 2 # grid size is based on longest possible cave system. DO NOT CHANGE!!
var babihodler

@export_subgroup("Meshes")
@export var tile_mesh : PackedScene
@export var cave_mesh : PackedScene
@export var sp_mesh : PackedScene
@export var dir_mesh : PackedScene
@export var babikuva : CompressedTexture2D
@export var jexit : CompressedTexture2D

@export_subgroup("Nodes")
@export var player : Node3D


var grid = []
var current : Vector2i
var sp : Vector2i
@onready var camera = $Camera3D
@onready var cam2d = $Camera2D

var dead_ends : Array[Vector2i] # this will be sent to tunnels.gd


func _ready():

	# Generate grid
	var row = []
	grid.resize(grid_size)
	for y in range(grid_size):
		grid[y]=[]
		grid[y].resize(grid_size)
		for x in range(grid_size):
			#var tt := tile_mesh.instantiate()
			#tt.position = pos_from_tile(Vector2i(x,y))
			#add_child(tt)
			grid[y][x] = CaveTile.new()
			grid[y][x].pos = Vector2i(x, y)
			#print(x," - ", y)
	
	
	current = Vector2i(cave_depth, cave_depth)
	var generations = 0
	var start_time = Time.get_ticks_usec()
	while true:
		generate_maze()
		generations += 1
		if generations % 100 == 0:
			var time = (Time.get_ticks_usec() - start_time) / 1000000.0
			
			print("%.2f: " % time, "Generating maze... ", generations)
		
		var cavern = count_cave_tiles()
		var rooms = count_dead_ends()
		var loops = count_loops()
		if (cavern > average_tile_count + max_variance/2 
			or cavern < average_tile_count - max_variance/2
			or rooms < min_dead_ends
			or loops < min_loops): # whoa long if statement
			clear_cave()
		else:
			var time = (Time.get_ticks_usec() - start_time) / 1000000.0
			time 
			print("cave took ", generations, " generations and %.2f" % time, " s" )
			print("We have ", cavern, " tiles and ", loops, " loops")
			print("---")
			break
	send_grid.emit(grid, sp, dead_ends)
	#draw_cave()
	#_draw()
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
		#print(current, tile_obj(current).paths); 
		player.position = pos_from_tile(current)

func flip_dir(i: int):
	return (i+3)%6

func generate_maze():
	
	#random start pos
	sp = current
	
	var next_tiles = []
	
	
	tile_obj(sp).add_dir(2)
	next_tiles.append(next_tile(sp,2))
	tile_obj(next_tile(sp,2)).add_dir(flip_dir(2))
	
	tile_obj(sp).add_dir(5)
	
	#start generating new tiles until we have wanted depth
	var i = 0
	while len(next_tiles) != 0 and i < cave_depth: # creates caves with depth cave_depth + 1
		i += 1
		
		var new_tiles = []
		for tile in next_tiles:
			var tile_obj = tile_obj(tile) #grid[tile.y][tile.x]
			if tile_obj.paths.count(true) > 1: continue #skip if tile is not a deadend.
	
			#skip if tile has neighbours with already existing paths. This prevents traffic :)
			var traffic_points : int = 0
			for dir in range(6):
				var surrounding_pos = next_tile(tile, dir)
				var surrounding_tile = tile_obj(surrounding_pos) #grid[surrounding_pos.y][surrounding_pos.x]
				#if true in surrounding_tile.paths: traffic_points+=1
				traffic_points+=surrounding_tile.paths.count(true) ** 2 #squared number emphasises large traffic squares
			if traffic_points > traffic_limit: continue
			
			#generate cave
			var next = tile_obj.next_paths(randi())
			
			
			for d in next:
				var new = next_tile(tile, d)
				
				if new == sp: # remove connection to start pos if one exists
					#print("I tried to be cringe")
					tile_obj(next_tile(new, flip_dir(d))).paths[d] = false
					continue # no new connections to start pos
				
				tile_obj(new).add_dir(flip_dir(d)) #add entraces to new tiles
				new_tiles.append(new)
		
		next_tiles = new_tiles


func draw_cave():
	#draw cave icons
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if not true in tile.paths: continue
			#var tt := cave_mesh.instantiate()
			#tt.position = pos_from_tile(Vector2i(x,y))
			#add_child(tt)
			
			
			
			# draw paths
			#var col = "Black"
			#for dir in range(6):
				#if tile.paths[dir]:
					#
			
			#draw directional blobs
			for dir in range(6):
				if tile.paths[dir]:
					var ttt := dir_mesh.instantiate()
					ttt.position = pos_from_tile(tile.pos) + dir_to_norm(dir) * 0.35
					add_child(ttt)
	#draw sp mesh
	var sp_tt := sp_mesh.instantiate()
	sp_tt.position = pos_from_tile(sp)
	camera.position = pos_from_tile(sp)
	camera.position.y += 20
	add_child(sp_tt)

func _draw():
	#draw_circle(Vector2.ZERO, 9999, Color.)
	var posses = []
	var miny = 9999
	var maxy = 0
	var col : Color = Color.DARK_SLATE_GRAY
	for y in range(grid_size):
		for x in range(grid_size):
			
			var tile = grid[y][x]
			if not true in tile.paths: continue
			
			var pos3 = pos_from_tile(tile.pos)
			var pos2 = Vector2(pos3.x, pos3.z) * 5
			
			posses.append(pos2)
			
			if pos2.y > maxy:
				maxy = pos2.y
			if pos2.y > miny:
				miny = pos2.y
			
			draw_circle(pos2, 1, col)
			
			for dir in range(6):
				if tile.paths[dir]:
					var norm = dir_to_norm(dir)
					norm = Vector2(norm.x, norm.z) * 3
					var rect = Rect2(pos2 + norm, Vector2(3,2))
					
					var B = pos2 + norm
					
					var normal = (B - pos2).normalized()
					var perp = Vector2(-normal.y, normal.x) * (2 / 2)

					# Calculate rectangle corners
					var top_left = pos2 - perp
					var top_right = pos2 + perp
					var bottom_right = B + perp
					var bottom_left = B - perp

					# Draw the rectangle
					draw_polygon([top_left, top_right, bottom_right, bottom_left], [col])

	
	var total = Vector2.ZERO
	for i in posses:
		total += i

	var zooom = (maxy-miny) / 2750
	cam2d.zoom = Vector2(zooom, zooom)
	total /= posses.size()
	cam2d.position = total


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

func clear_cave():
	for y in range(grid_size):
		for x in range(grid_size):
			grid[y][x].clear_dirs()

func count_cave_tiles():
	var sum = 0
	for y in range(grid_size):
		for x in range(grid_size):
			if true in grid[y][x].paths:
				sum+=1
	return sum

func count_dead_ends():
	var total = 0
	dead_ends = []
	for y in range(len(grid)):
		for x in range(len(grid)):
			if grid[y][x].paths.count(true) == 1 and Vector2i(x,y) != sp:
				dead_ends.append(Vector2i(x,y))
				total += 1
	return total

func count_loops():
	# checks paths from right to left
	
	#print("sp is ", sp)
	
	var count = 0
	var been_here = [sp]
	var cross_road = [[sp, [2]]] # [tile with cross (v2i), [unchecked directions]]
	var checking = sp
	var last_dir = 2
	
	
	while !cross_road.is_empty():
		
		if cross_road[-1][1].size() == 0:
			print("WARNING WARNING WARNING WARNING WARNING")
			break
		
		last_dir = cross_road[-1][1][-1]
		checking = next_tile(cross_road[-1][0], last_dir)
		
		#print("I chose to go ", last_dir, " from ", cross_road[-1][0])
		
		#print("I removed ", cross_road[-1][1][-1], " from ", cross_road[-1][0])
		cross_road[-1][1].remove_at(cross_road[-1][1].size() - 1)
		#print("Now ", cross_road[-1][0], " is ", cross_road[-1][1])
		if cross_road[-1][1].is_empty():
			#print("I removed ", cross_road[-1][0])
			cross_road.remove_at(cross_road.size() - 1)
			
		
		var directions = []
		
		 # loop directions from left to right relative to last_dir
		for dir in range(5):
			var checking_dir = (last_dir -2 + 6 + dir) % 6
			
			# if path was found
			if tile_obj(checking).paths[checking_dir]:
				var neighbour = next_tile(checking, checking_dir)
				
				# check if path leads to visited tile
				if neighbour in been_here:
					count += 1
					#print("we reached loop by going ", checking_dir, " from ", checking," total count is " , count)
					
					# remove opposing road.
					for item in range(cross_road.size()):
						if cross_road[item][0] == neighbour:
							cross_road[item][1].remove_at(cross_road[item][1].find(flip_dir(checking_dir)))
							#print("yippee double removal!")
							
							if cross_road[item][1].is_empty():
								#print("I removed ", cross_road[-1][0])
								cross_road.remove_at(item)
							
							break
					continue # go to next dir
					
				# if not, add direction to cross roads
				directions.append(checking_dir)
		
		# add direction array to cross roads along with relative tile
		if !directions.is_empty():
			cross_road.append([checking, directions])
		#else: print("I hit a dead end.")
		
		# mark tile as checked
		been_here.append(checking)
	return count


func _on_tunnels_babi_locations(babeis: Array) -> void:
	babihodler = babeis
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if not true in tile.paths: continue
	
			var pos3 = pos_from_tile(tile.pos)
			var pos2 = Vector2(pos3.x, pos3.z) * 5
	
			if tile.pos in babihodler:
				var kuva = Sprite2D.new()
				kuva.texture = babikuva
				kuva.scale = Vector2(1,1) * -0.04
				kuva.position = pos2
				add_child(kuva)
				
	var kuva = Sprite2D.new()
	kuva.texture = jexit
	kuva.scale = Vector2(1,1) * -0.04
	var possible = pos_from_tile(sp)
	kuva.position = Vector2(possible.x, possible.z) * 5
	add_child(kuva)
	#_draw()
