extends Node
signal settings_updated()

var gamma = 1

func change(new: float):
	gamma = new
	print("gamma is now ", new)
	emit_signal("settings_updated")
	
