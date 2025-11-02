# cardHolder.gd
extends Container

func _process(_delta):
	# Seguir o mouse (centralizado)
	self.global_position = get_global_mouse_position() - self.size / 2
