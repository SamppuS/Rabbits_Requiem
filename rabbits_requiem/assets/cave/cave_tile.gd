extends Resource
class_name CaveTile

#This part is likely useless.
enum Direction {
	LL, UL, UR, RR, DR, DL
}

# Variables
var paths : Array[bool] = [
	0, 0, 0, 0, 0, 0
]
var pos : Vector2i

func next_paths(seed: int = 1) -> Array[int]:
	
	# choose path directions :)
	#var first : int = randi() % 6
	#var dirs : Array[int] = [first, (first + randi()%5 + 1) % 6]
	#for d in dirs: add_dir(d)
	
	var dirs : Array[int]
	for i in range(randi()%3+1):
		var weighted_p = [[ 2, 3, 3, 4], [1, 2, 2, 3, 3, 3, 4, 4, 5]][1 if seed%5 == 0 else 0] #weighted probability where 2=UL, 3=UU, 2=UR. Notice there are only 3 options!
		var dir = (paths.find(true) + weighted_p[randi() % weighted_p.size()])%6
		dirs.append(dir)
	for d in dirs:
		add_dir(d)
	return dirs

func add_dir(dir: int):
	paths[dir] = 1

func print_tile():
	
	print(pos)
	for i in range(6):
		if !paths[i]: continue
		print("  ", [Direction.LL, Direction.UL, Direction.UR, Direction.RR, Direction.DR, Direction.DL][i])
		
func clear_dirs():
	paths = [0, 0, 0, 0, 0, 0]
	
