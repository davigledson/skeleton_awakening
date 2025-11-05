# cardHolder.gd
extends Container

func _ready():
	print(" CardHolder criado")
	add_to_group("card_holders")  # Adicionar ao grupo para limpeza forçada

func _process(_delta):
	# Verificar se ainda há uma carta sendo arrastada
	if not Game.cardSelected:
		# Nenhuma carta está sendo selecionada, se auto-destruir
		print(" CardHolder se auto-destruindo (carta não selecionada)")
		queue_free()
		return
	
	# Seguir o mouse (centralizado)
	self.global_position = get_global_mouse_position() - self.size / 2

func _exit_tree():
	print(" CardHolder destruído")
	remove_from_group("card_holders")
