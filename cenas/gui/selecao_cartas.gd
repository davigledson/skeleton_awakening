# selecao_cartas.gd
extends CanvasLayer

@onready var carta1 = $Control/HBoxContainer/Carta1
@onready var carta2 = $Control/HBoxContainer/Carta2
@onready var carta3 = $Control/HBoxContainer/Carta3
@onready var som_select = $som_select
@onready var som_hover = $som_hover

var cartas_disponiveis = [
	"res://cenas/cartas/carta_explosao/carta_explosao.tscn",
	"res://cenas/cartas/carta_bola_de_fogo/carta_bola_de_fogo.tscn",
	"res://cenas/cartas/carta_bola_de_agua/carta_magia_de_agua.tscn",
	"res://cenas/cartas/carta_magia_negra/carta_magia_negra.tscn",
	"res://cenas/cartas/carta_tornado/carta_tornado.tscn"
]

var cartas_sorteadas = []
var cartas_info = []
var carta_hover_atual = null

# ===== VARIÁVEL CONFIGURADA PELA CARTA DROP =====
var eh_ultima_onda: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	sortear_cartas()
	carregar_info_cartas()
	configurar_botoes()
	
	print("[SELECAO_CARTAS] Tela inicializada. É última onda: ", eh_ultima_onda)

func configurar_botoes():
	for i in range(3):
		var botao = get_node("Control/HBoxContainer/Carta" + str(i + 1))
		if botao:
			configurar_hover(botao)
			botao.pressed.connect(_on_carta_selecionada.bind(i))

func configurar_hover(botao: Button):
	botao.mouse_entered.connect(func():
		if carta_hover_atual != botao and som_hover:
			carta_hover_atual = botao
			som_hover.play()
		animar_botao(botao, Vector2(1.1, 1.1))
	)
	botao.mouse_exited.connect(func(): animar_botao(botao, Vector2.ONE))

func animar_botao(botao: Button, escala: Vector2):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(botao, "scale", escala, 0.2)

func sortear_cartas():
	cartas_sorteadas.clear()
	var cartas_temp = cartas_disponiveis.duplicate()
	cartas_temp.shuffle()
	for i in range(min(3, cartas_temp.size())):
		cartas_sorteadas.append(cartas_temp[i])

func carregar_info_cartas():
	cartas_info.clear()
	for i in range(cartas_sorteadas.size()):
		var info = extrair_info_carta(cartas_sorteadas[i])
		cartas_info.append(info)
		atualizar_botao_carta(get_node("Control/HBoxContainer/Carta" + str(i + 1)), info)

func extrair_info_carta(carta_path: String) -> Dictionary:
	var info = {"nome": "Carta Desconhecida", "descricao": "Sem descricao", "sprite": null}
	
	var carta_scene = load(carta_path)
	if not carta_scene:
		return info
	
	var carta_temp = carta_scene.instantiate()
	add_child(carta_temp)
	
	if "carta_nome" in carta_temp:
		info.nome = carta_temp.carta_nome
	if "carta_descricao" in carta_temp:
		info.descricao = carta_temp.carta_descricao
	
	for child in carta_temp.get_children():
		if child is Sprite2D or child is Sprite3D:
			info.sprite = child.texture
			break
	
	remove_child(carta_temp)
	carta_temp.queue_free()
	return info

func atualizar_botao_carta(botao: Button, info: Dictionary):
	if not botao:
		return
	
	var sprite_node = botao.get_node_or_null("MarginContainer/VBoxContainer/CardPanel/Sprite")
	if not sprite_node:
		criar_estrutura_botao(botao)
		sprite_node = botao.get_node("MarginContainer/VBoxContainer/CardPanel/Sprite")
	
	sprite_node.texture = info.sprite if info.sprite else null
	botao.get_node("MarginContainer/VBoxContainer/Nome").text = info.nome
	botao.get_node("MarginContainer/VBoxContainer/Descricao").text = info.descricao

func criar_estrutura_botao(botao: Button):
	botao.text = ""
	botao.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var margin = criar_container(MarginContainer, "MarginContainer", {"margin_left": 20, "margin_right": 20, "margin_top": 20, "margin_bottom": 20})
	botao.add_child(margin)
	
	var vbox = criar_container(VBoxContainer, "VBoxContainer", {"separation": 20})
	margin.add_child(vbox)
	
	var panel = criar_panel()
	vbox.add_child(panel)
	
	var sprite = criar_sprite()
	panel.add_child(sprite)
	
	vbox.add_child(criar_label("Nome", 24, Color(1, 0.95, 0.7), 4))
	vbox.add_child(criar_label("Descricao", 15, Color(0.95, 0.95, 1.0), 6, 80))

func criar_container(tipo, nome: String, margins: Dictionary) -> Control:
	var container = tipo.new()
	container.name = nome
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in margins:
		container.add_theme_constant_override(key, margins[key])
	return container

func criar_panel() -> Panel:
	var panel = Panel.new()
	panel.name = "CardPanel"
	panel.custom_minimum_size = Vector2(280, 280)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.8, 0.7, 0.3)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func criar_sprite() -> TextureRect:
	var sprite = TextureRect.new()
	sprite.name = "Sprite"
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.offset_left = 20
	sprite.offset_top = 20
	sprite.offset_right = -20
	sprite.offset_bottom = -20
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sprite

func criar_label(nome: String, tamanho: int, cor: Color, outline: int, altura: int = 0) -> Label:
	var label = Label.new()
	label.name = nome
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP if altura > 0 else VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", outline)
	
	if altura > 0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(0, altura)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.add_theme_constant_override("shadow_outline_size", 1)
	
	return label

func _on_carta_selecionada(indice: int):
	print("[SELECAO_CARTAS] Carta ", indice + 1, " selecionada")
	
	# Tocar som
	if som_select:
		som_select.play()
		await som_select.finished
	
	# Adicionar carta ao deck
	if indice < cartas_sorteadas.size():
		adicionar_carta_ao_deck(cartas_sorteadas[indice], cartas_info[indice])
	
	# Despausar o jogo
	get_tree().paused = false
	
	# Aguardar um pouco
	await get_tree().create_timer(0.5).timeout
	
	# ===== VERIFICAR SE É ÚLTIMA ONDA =====
	if eh_ultima_onda:
		print("[SELECAO_CARTAS] ========== É A ÚLTIMA ONDA! ==========")
		print("[SELECAO_CARTAS] Iniciando transição de nível...")
		
		# Buscar sistema de transição
		var transicao = get_tree().get_first_node_in_group("transicao_nivel")
		
		if transicao and transicao.has_method("iniciar_transicao_ultima_onda"):
			print("[SELECAO_CARTAS] Sistema de transição encontrado!")
			# Remover interface ANTES da transição
			queue_free()
			# Iniciar transição
			transicao.iniciar_transicao_ultima_onda()
		else:
			print("[SELECAO_CARTAS] [ERRO] Sistema de transição NÃO encontrado!")
			print("[SELECAO_CARTAS] Certifique-se que existe um nó 'transicao_nivel' no grupo 'transicao_nivel'")
			queue_free()
	else:
		print("[SELECAO_CARTAS] Não é a última onda, apenas fechando interface")
		queue_free()

func adicionar_carta_ao_deck(carta_path: String, info: Dictionary):
	print("[SELECAO_CARTAS] Adicionando carta ao deck: ", info.nome)
	
	Game.cartas_no_deck.append({
		"path": carta_path,
		"nome": info.nome,
		"descricao": info.descricao,
		"sprite": info.sprite
	})
	
	var card_container = buscar_node(get_tree().root, "CardContainer")
	if not card_container:
		print("[SELECAO_CARTAS] [AVISO] CardContainer não encontrado")
		return
	
	var carta = load(carta_path).instantiate()
	card_container.add_child(carta)
	
	await get_tree().create_timer(0.1).timeout
	animar_carta_entrada(carta)

func buscar_node(node: Node, nome: String) -> Node:
	if node.name == nome:
		return node
	for child in node.get_children():
		var resultado = buscar_node(child, nome)
		if resultado:
			return resultado
	return null

func animar_carta_entrada(carta: Node):
	var sprite = carta.get_node_or_null("Sprite2D") if carta.has_node("Sprite2D") else carta.get_node_or_null("Sprite3D")
	if not sprite:
		return
	
	sprite.modulate.a = 0
	var scale_original = sprite.scale
	sprite.scale = Vector3.ZERO if sprite is Sprite3D else Vector2.ZERO
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	tween.tween_property(sprite, "scale", scale_original, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
