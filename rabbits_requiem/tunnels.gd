extends Node3D

var received_grid: Array

func _ready():
	var minimap = get_node("Minimap")
	minimap.grid_updated.connect(_on_grid_received)

func _on_grid_received(new_grid):
	received_grid = new_grid
	# Now you can use the received grid data
	print("Received new grid data: ", received_grid)
