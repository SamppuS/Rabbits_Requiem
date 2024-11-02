extends Resource
class_name CaveTile

enum Direction {
	LL, UL, UR, RR, DR, DL
}

# Variables
var paths : Array[bool] = [
	0, 0, 0, 0, 0, 0
]
var pos : Vector2i

func next_paths() -> Array[int]:
	
	# choose path directions :)
	var first : int = randi() % 6
	var dirs : Array[int] = [first, (first + randi()%5 + 1) % 6]
	for d in dirs:
		paths[d] = 1
	
	return dirs

func add_dir(dir: int):
	paths[dir] = 1

func print_tile():
	
	print(pos)
	for i in range(6):
		if !paths[i]: continue
		print("  ", [Direction.LL, Direction.UL, Direction.UR, Direction.RR, Direction.DR, Direction.DL][i])
