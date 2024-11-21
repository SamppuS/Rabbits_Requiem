extends Node3D
signal snaking_complete()


@onready var head := $Head

var goals : Array[Array] = [[],[]] # array of points that the snake will trace from start to finish. [v3, v2i]
var old_goals : Array[Array] = [[],[]] # copy of goals to recognize updates

var snake_path = []

var path_index = 0  # Current progress along the path
var speed = .15 * 4  # Speed of movement

var current = [Vector3(0,0,0), Vector2i(0,0), 0]
var next = [Vector3(0,0,0), Vector2i(0,0), 0]

var keep_on_clear : int = 3

var path_blobs = []

const pt_frequency = 168 # point per tunnel frequency
var sin_phase = 0


@export var thingy : PackedScene
var bump
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bump = thingy.instantiate() # oonpas mä hyvä nimee variableita :)
	bump.scale = Vector3(8, .02, 8)
	add_child(bump)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !goals[0].is_empty() and goals != old_goals:
		snake_path = generate_path()
		if path_index > 100:
			path_index = find_best_index()
		draw_path()
		
		#print("wowie, we can slither up to ", len(snake_path), " with the power of ", goals[0].size() - 1, " giving ratio of ", len(snake_path)/(goals[0].size() - 1))
	
	if head.position.distance_to(goals[0][next[2]]) < 0.3 and !goals[0].is_empty() and next[2] < len(goals[0]) -1:
			advance()
	
	old_goals = goals.duplicate()

	bump.position = next[0]
	
	if !goals[0].is_empty() and int(path_index * speed) < len(snake_path) - 2 :
		move()
	elif !goals[0].is_empty() and int(path_index * speed) >= len(snake_path) - 2:
		emit_signal("snaking_complete")
	

func move():
	path_index += 1
	head.position = snake_path[path_index * speed]

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
		
		var sine_offset = amplitude * sin(frequency *  point_index - sin_phase)
		var slither_point = base_point + perpendicular * sine_offset
		
		slither_path.append(slither_point)
		

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

	#current = [next[0], next[1], 0]
	goals[0] = goals[0].slice(max(0, next[2] - keep_on_clear ), max(next[2] + 1, 2))
	goals[1] = goals[1].slice(max(0, next[2] - keep_on_clear ), max(next[2] + 1, 2))
	
	sin_phase += max(0, next[2] - keep_on_clear) * pt_frequency
	
	current[2] = 0
	next[2] = len(goals[0]) - 1 
	
	for i in path_blobs:
		i.queue_free()
	path_blobs = []
	
	
		
func find_best_index():
	var best = [0, 100]
	for i in range(min(len(snake_path) - pt_frequency * 2, pt_frequency * 2), len(snake_path)):
		var dist = snake_path[i].distance_to(head.position)
		if  dist < best[1]:
			best[1] = dist
			best[0] = i
		if i - best[0] > 40:
			break
	return int(best[0] / speed) 
	
func draw_path():
	for a in snake_path:
		var hahaa = thingy.instantiate()
		hahaa.scale = Vector3(.4, .05, .4)
		hahaa.position = a + Vector3.UP * .1
		add_child(hahaa)
		path_blobs.append(hahaa)

func advance():
	current = next
	next[2] = next[2] + 1
	next = [goals[0][next[2]], goals[1][next[2]], next[2]]

	
