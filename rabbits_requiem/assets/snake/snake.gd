extends Node3D
signal snaking_complete()
signal snake_moved()

@export var debug_draw : bool = false

@export var segment : PackedScene
@export var debug_mesh : PackedScene

@export var hissing_sounds : Array[AudioStreamWAV]
@export var alert_sounds : Array[AudioStreamWAV]

var alert_cooldown = 0

var marker
var markers = []


@onready var head := $Head

@onready var hisser := $"Head/Snake noises"
@onready var alerter := $"Head/Alert player"

const snake_lenght = 15
const segment_frequency = 20
const snake_height = Vector3.UP * .1
const shrink_len = 4
const shrink_ratio = .1

const mesh_size = 1.73233866691589 - .05

var tunnel_grid : Array

var goals : Array[Array] = [[],[]] # array of points that the snake will trace from start to finish. [v3, v2i]
var old_goals : Array[Array] = [[],[]] # copy of goals to recognize updates

var snake_path = []
var snake_body = []

var snake_tiles = []

var path_index = 0  # Current progress along the path
var speed = .25   # Speed of movement

var current = [Vector3(0,0,0), Vector2i(0,0), 0]
var next = [Vector3(0,0,0), Vector2i(0,0), 0]
var sight = []

var keep_on_clear : int = 3

var path_markers = []

const pt_frequency = 168 # point per tunnel frequency
var sin_phase = 0

var tangent_path = []

var times_moved = 0 # this is to make sure snake got started correctly


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if debug_draw:
		marker = debug_mesh.instantiate() # oonpas mä hyvä nimee variableita :)
		marker.scale = Vector3(8, .02, 8)
		add_child(marker)
	
	for i in snake_lenght:
		var seg = segment.instantiate()
		if i+shrink_len>snake_lenght:
			seg.scale = Vector3(1-(i+shrink_len-snake_lenght)*shrink_ratio, 1-(i+shrink_len-snake_lenght)*shrink_ratio, 1)
		var arr = [seg, 0] # obj, index
		
		add_child(seg)
		snake_body.append(arr)
		
	# simple hisser loop
	hiss()
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !goals[0].is_empty() and goals != old_goals:
		snake_path = generate_path()
		if path_index > 100 and times_moved > 3: # times moved is to make game start correctly
			path_index = find_best_index()
		get_tangents()
		if debug_draw: draw_path()
		
		
		#print("wowie, we can slither up to ", len(snake_path), " with the power of ", goals[0].size() - 1, " giving ratio of ", len(snake_path)/(goals[0].size() - 1))
	
	if head.position.distance_to(goals[0][next[2]]) < 0.3 and !goals[0].is_empty() and next[2] < len(goals[0]) -1:
			advance()
	
	old_goals = goals.duplicate()
	
	if debug_draw:
		marker.position = next[0]
	
	if !goals[0].is_empty() and int(path_index * speed) < len(snake_path) - 2 :
		move()
	elif !goals[0].is_empty() and int(path_index * speed) >= len(snake_path) - 2:
		emit_signal("snaking_complete")
	

func move():
	
	#if tangent_path.is_empty(): get_tangents()
	
	path_index += 1
	var head_index = path_index * speed
	head.position = snake_path[head_index] + snake_height
	head.look_at(head.position + tangent_path[head_index], Vector3.UP)
	for segment in snake_lenght:
		var seg_index = max(head_index - segment_frequency * (segment + 1), 0)
		snake_body[segment][0].position = snake_path[seg_index] + snake_height
		snake_body[segment][0].look_at(snake_body[segment][0].position + tangent_path[seg_index], Vector3.UP)
		
		

func add_destination(d3 : Vector3, d2i : Vector2i) :
	if !goals[0].is_empty():
		if d2i == goals[1][-1]: # skip back to back dublicates
			return
	goals[0].append(d3)
	goals[1].append(d2i)
	
func remove_first(): 
	goals[0].remove_at(0)
	goals[1].remove_at(0)
	
func remove_index(n: int): 
	goals[0].remove_at(n)
	goals[1].remove_at(n)

func generate_path():
	
	var slither_path : PackedVector3Array
	var frequency =  .05
	var amplitude = 0.075
	var step_size = 0.01  # Now supports smaller step sizes

	# generate path along goals
	var path = Curve3D.new()
	for point in goals[0]:
		path.add_point(point)
	
	# subdivide path
	var discrete_path = []
	var i = 0
	while i < path.get_baked_length():
		discrete_path.append(path.sample_baked(i))
		i += step_size
	
	# smooth curve
	discrete_path = moving_average(discrete_path, 50)
	
	# add slithering
	for point_index in range(1, len(discrete_path)):
		var base_point = discrete_path[point_index]
		var last_point = discrete_path[point_index - 1]
		
		var tangent = (base_point - last_point).normalized()
		var perpendicular = tangent.cross(Vector3.UP).normalized()
		
		tangent_path.append(tangent)
		
		var sine_offset = amplitude * sin(frequency *  point_index - sin_phase)
		var slither_point = base_point + perpendicular * sine_offset
		
		slither_path.append(slither_point)
		
	slither_path = redistribute_path(slither_path)
	
	return slither_path

func moving_average(arr: PackedVector3Array, window: int = 0):
	var new_array = []
	for i in range(len(arr)):
		var vectorsum = arr[i]
		var mid_point = arr[i]
		
		var max_n = 0
		for n in range(window):
			if i-n >= 0 and i+n <= len(arr) - 1:
				vectorsum += arr[i-n]
				vectorsum += arr[i+n]
				max_n += 1

		new_array.append(vectorsum / (max_n * 2 + 1 ))
		
	return new_array
		
func clear_path(): # Calling before snake having moved at least "keep_on_clear" amount of tiles causes snap back. (this shouldn't be problem often)
	#print("claring!")
	#current = [next[0], next[1], 0]
	goals[0] = goals[0].slice(max(0, next[2] - keep_on_clear ), max(next[2] + 1, 2))
	goals[1] = goals[1].slice(max(0, next[2] - keep_on_clear ), max(next[2] + 1, 2))
	
	sin_phase += max(0, next[2] - keep_on_clear) * pt_frequency
	
	current[2] = 0
	next[2] = len(goals[0]) - 1 
	
	if debug_draw:
		for i in path_markers:
			i.queue_free()
		path_markers = []
		
	#get_tangents()
	

func find_best_index():
	var best = [0, 100]
	for i in range(min(len(snake_path) - pt_frequency * 2, pt_frequency * 2), len(snake_path)):
		var dist = snake_path[i].distance_to(head.position)
		if  dist < best[1]:
			best[1] = dist
			best[0] = i
		if i - best[0] > 40:
			break
	return int(best[0] / speed)  - 50 # not sure why - 50. Somehow it makes snake smother
	
func draw_path():
	for a in range(snake_path.size() -1):
		var blob = debug_mesh.instantiate()
		blob.scale = Vector3(.4, .05, .4)
		blob.position = snake_path[a] + Vector3.UP * .1
		add_child(blob)
		path_markers.append(blob)
		
		var bap = debug_mesh.instantiate()
		bap.scale = Vector3(.01, .1, 1)
		bap.position = snake_path[a] + Vector3.UP * .1 + tangent_path[a] * .1
		add_child(bap)
		bap.look_at(blob.position + tangent_path[a], Vector3.UP)
		path_markers.append(bap)

func advance():
	times_moved += 1
	current = next
	next[2] = next[2] + 1
	next = [goals[0][next[2]], goals[1][next[2]], next[2]]
	
	#set snake sight tiles
	sight = []
	for dir in range(6):
		var checking = next[1]
		for distance in range(3):
			var tile_dirs = tile_obj(checking).paths
			if tile_dirs[dir] == true:
				var neighbour = next_tile(checking, dir)
				if neighbour != current[1] and neighbour not in sight:
					sight.append(neighbour)
					checking = neighbour
				else: continue
	
	emit_signal("snake_moved")
	
	get_snake_tiles()
	
	#drawing sight
	if debug_draw:
		for mark in markers:
			mark.queue_free()
		markers = []
		for tile in sight:
			var marker2 = debug_mesh.instantiate() # oonpas mä hyvä nimee variableita :)
			marker2.scale = Vector3(4, .4, 4)
			marker2.position = pos_from_tile(tile)
			add_child(marker2)
			markers.append(marker2)
	

func get_tangents():
	tangent_path = []
	for i in len(snake_path) - 1:
		var tangent = (snake_path[i + 1] - snake_path[i]).normalized()
		
		# FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX

		#if tangent_path.size() > 2 and tangent.angle_to(tangent_path[i - 1]) > deg_to_rad(5):
			#var rotation_angle = min(deg_to_rad(5), tangent.angle_to(tangent_path[i - 1]))  # Fixed small rotation step
			## Determine the sign of the angle to know which direction to rotate
			#var cross_product = tangent.cross(tangent_path[i - 1])
			#var direction = sign(cross_product.y)  # Assuming rotation around Y-axis
			## Rotate tangent by the small step in the correct direction
			#tangent = tangent_path[i-1].rotated(Vector3.UP, rotation_angle * direction)
			
		# FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX FIX
			
		tangent_path.append(tangent)

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

func tile_obj(pos: Vector2i): # copy form minimap
	return tunnel_grid[pos.y][pos.x]

func _on_minimap_send_grid(grid: Variant, sp: Variant, dead_ends: Variant) -> void:
	tunnel_grid = grid

func pos_from_tile(pos : Vector2i) -> Vector3:
	return Vector3(-pos.x + pos.y%2*0.5, 0, float(pos.y) - pos.y * (1-sqrt(3)/2)) * mesh_size
	
func straighten():
	print(path_index)
	advance()
	advance()
	advance()
	path_index = 1500 # if snake len is adjusted this also needs to be adjusted

func redistribute_path(points: Array[Vector3]) -> Array[Vector3]:
	var curve = Curve3D.new()
	
	# Add points to the curve
	for point in points:
		curve.add_point(point)
	
	# Get the total length of the curve
	var total_length = curve.get_baked_length()
	
	# Redistribute the points along the curve
	var redistributed_points : Array[Vector3] = []
	for i in range(points.size()):
		var t = i / float(points.size() - 1)  # Get the normalized position
		var position = curve.sample_baked(t * total_length)  # Use sample_baked() instead
		redistributed_points.append(position)
	
	return redistributed_points
	

func hiss():
	hisser.stream = hissing_sounds[randi() % hissing_sounds.size()]
	hisser.seek(0)
	hisser.pitch_scale = randf_range(1,2.5) 
	hisser.play()
	
func alert():
	if Time.get_unix_time_from_system() > alert_cooldown:
		alerter.stream = alert_sounds[randi() % alert_sounds.size()]
		alerter.seek(0)
		#alerter.pitch_scale = randf_range(0.8,1.2) 
		alerter.play()
		alert_cooldown = Time.get_unix_time_from_system() + 5
		#print(Time.get_unix_time_from_system(), " ", alert_cooldown)


func _on_snake_noises_finished() -> void:
	var wait = randi() % 100 / 100.0
	print("waiting for ", wait)
	await get_tree().create_timer(wait).timeout
	hiss()


func get_snake_tiles():
	snake_tiles = goals[1].slice(max(next[2]-3, 0), next[2] + 1)
