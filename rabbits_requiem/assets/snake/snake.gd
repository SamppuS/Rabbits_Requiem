extends Node3D

var goals : Array[Array] = [[],[]] # array of points that the snake will trace from start to finish. [v3, v2i]
var old_goals : Array[Array] = [[],[]] # copy of goals to recognize updates

var snake_path = []

var path_index = 0.0  # Current progress along the path
var speed = 1.0  # Speed of movement

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
			hahaa.scale = Vector3(.1, .1, .1)
			hahaa.position = a + Vector3.UP * .1
			add_child(hahaa)
			print(hahaa.position)
			
			
	old_goals = goals
	

func add_destination(d3 : Vector3, d2i : Vector2i) : 
	goals[0].append(d3)
	goals[1].append(d2i)
	
func remove_first(): 
	goals[0].remove_at(0)
	goals[1].remove_at(0)

func generate_path():
	
	# generate initial smooth curve along goals
	var curve = Curve3D.new()
	for point in goals[0]:
		curve.add_point(point)
		
	# Bake path and apply sine displacement
	var slither_path = []
	var frequency = 6
	var amplitude = 0.05
	var step_size = 0.05  # Now supports smaller step sizes
	var offset = 0.0  # Initial offset
	var small_increment = step_size  # Small increment to sample the forward point for tangent calculation

	# Use a while loop to iterate with floating-point step size
	while offset < curve.get_baked_length():
		var base_point = curve.sample_baked(offset)

		# Calculate the tangent by sampling a point slightly ahead on the path
		var next_point = curve.sample_baked(min(offset + small_increment, curve.get_baked_length()))
		var tangent = (next_point - base_point).normalized()

		# Create a perpendicular vector for displacement
		var perpendicular = tangent.cross(Vector3.UP).normalized()  # Ensure this is perpendicular

		# Apply sine wave displacement
		var sine_offset = amplitude * sin(frequency * offset)
		var slither_point = base_point + perpendicular * sine_offset
		slither_path.append(slither_point)

		# Increment the offset by the step size
		offset += step_size
	
	return slither_path
