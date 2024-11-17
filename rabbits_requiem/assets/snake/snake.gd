extends Node3D

@onready var head := $Head

var goals : Array[Array] = [[],[]] # array of points that the snake will trace from start to finish. [v3, v2i]
var old_goals : Array[Array] = [[],[]] # copy of goals to recognize updates

var snake_path = []

var path_index = 0  # Current progress along the path
var speed = .15  # Speed of movement

@export var thingy : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if position.distance_to(goals[2]) < 0.1:
		#remove_first()
	if !goals[0].is_empty() and goals != old_goals:
		print("we got path at")
		for i in goals[1]: print(i)
		snake_path = generate_path()
		print("wowie, we can slither up to ", len(snake_path))
		for a in snake_path:
			var hahaa = thingy.instantiate()
			hahaa.scale = Vector3(.05, .05, .05)
			hahaa.position = a + Vector3.UP * .1
			add_child(hahaa)
			
			
	old_goals = goals
	move()
	

func move():
	path_index += 1
	path_index = path_index % int(len(snake_path) / speed)
	head.position = snake_path[path_index * speed]

func add_destination(d3 : Vector3, d2i : Vector2i) : 
	goals[0].append(d3)
	goals[1].append(d2i)
	
func remove_first(): 
	goals[0].remove_at(0)
	goals[1].remove_at(0)

func generate_path():
	
	var slither_path : PackedVector3Array
	var frequency = (1.73233866691589 - .05) * 3
	var amplitude = 0.05
	var step_size = 0.01  # Now supports smaller step sizes

	# generate path along goals
	var path = Curve3D.new()
	for point in goals[0]:
		path.add_point(point)
	
	
	# subdivide path
	var discrete_path = []
	var i = 0.0
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
		
		var sine_offset = amplitude * sin(frequency * path.get_baked_length() * point_index / (len(discrete_path) - 1))
		var slither_point = base_point + perpendicular * sine_offset
		
		slither_path.append(slither_point)
	#
	return slither_path

func moving_average(arr: PackedVector3Array, window: int = 0):
	var new_array = []
	for i in range(len(arr)):
		var vectorsum = arr[i]
		var mid_point = arr[i]
		for n in range(window):
			if i-n >= 0 and i+n <= len(arr) - 1:
				vectorsum += arr[i-n]
				vectorsum += arr[i-n]
				
		new_array.append(vectorsum / (window * 2 + 1))
		#print(mid_point, " turned into ", vectorsum / (window * 2 + 1), " with ", (window * 2 + 1))
		
	return new_array
		
