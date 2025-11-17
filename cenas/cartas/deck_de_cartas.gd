# deck_de_cartas.gd
extends Node

@onready var card_container = $UI/CardContainer

func _ready():
	print("[DECK] Inicializando deck...")
	print("[DECK] Cartas salvas: ", Game.cartas_no_deck.size() if Game.cartas_no_deck else 0)
	carregar_deck()

func carregar_deck():
	# NÃO limpar cartas de desenvolvimento
	
	# Verificar se há cartas salvas
	if not Game.cartas_no_deck or Game.cartas_no_deck.is_empty():
		print("[DECK] Nenhuma carta coletada ainda")
		return
	
	print("[DECK] Adicionando ", Game.cartas_no_deck.size(), " cartas coletadas...")
	
	# Adicionar cada carta
	for i in range(Game.cartas_no_deck.size()):
		var carta_data = Game.cartas_no_deck[i]
		adicionar_carta_visual(carta_data, i)

func limpar_container():
	# Remover todas as cartas do container
	for child in card_container.get_children():
		child.queue_free()

func adicionar_carta_visual(carta_data: Dictionary, indice: int):
	# Carregar cena da carta
	var carta_scene = load(carta_data.path)
	if not carta_scene:
		push_error("[DECK] Não foi possível carregar carta: ", carta_data.path)
		return
	
	# Instanciar carta
	var carta = carta_scene.instantiate()
	card_container.add_child(carta)
	
	print("[DECK] Carta adicionada: ", carta_data.nome)
	
	# Animação de entrada com delay
	await get_tree().create_timer(indice * 0.15).timeout
	animar_entrada_carta(carta)

func animar_entrada_carta(carta: Node):
	# Verificar se tem Sprite2D ou Sprite3D
	var sprite = null
	
	if carta.has_node("Sprite2D"):
		sprite = carta.get_node("Sprite2D")
	elif carta.has_node("Sprite3D"):
		sprite = carta.get_node("Sprite3D")
	
	if not sprite:
		return
	
	# Animação
	sprite.modulate.a = 0
	var scale_original = sprite.scale
	sprite.scale = Vector3.ZERO if sprite is Sprite3D else Vector2.ZERO
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.4)
	tween.tween_property(sprite, "scale", scale_original, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func atualizar_deck():
	carregar_deck()

func adicionar_carta_instantanea(carta_path: String):
	"""Adiciona uma carta imediatamente ao CardContainer"""
	print("[DECK] Adicionando carta instantânea: ", carta_path)
	
	var carta_scene = load(carta_path)
	if not carta_scene:
		push_error("[DECK] Erro ao carregar: ", carta_path)
		return
	
	var carta = carta_scene.instantiate()
	card_container.add_child(carta)
	
	print("[DECK] Carta adicionada ao container!")
	
	# Animar entrada
	animar_entrada_carta(carta)

func remover_carta(indice: int):
	if indice < 0 or indice >= Game.cartas_no_deck.size():
		return
	
	Game.cartas_no_deck.remove_at(indice)
	carregar_deck()
