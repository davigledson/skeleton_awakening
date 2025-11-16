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

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	sortear_cartas()
	carregar_info_cartas()
	
	if carta1:
		configurar_botao_hover(carta1)
		carta1.pressed.connect(_on_carta_selecionada.bind(0))
	
	if carta2:
		configurar_botao_hover(carta2)
		carta2.pressed.connect(_on_carta_selecionada.bind(1))
	
	if carta3:
		configurar_botao_hover(carta3)
		carta3.pressed.connect(_on_carta_selecionada.bind(2))

func configurar_botao_hover(botao: Button):
	botao.mouse_entered.connect(func():
		# Só tocar som se for uma carta diferente
		if carta_hover_atual != botao:
			carta_hover_atual = botao
			if som_hover:
				som_hover.play()
		
		# Cancelar qualquer tween anterior
		var tweens = get_tree().get_processed_tweens()
		for tween in tweens:
			if tween.is_valid():
				tween.kill()
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(botao, "scale", Vector2(1.1, 1.1), 0.2)
	)
	
	botao.mouse_exited.connect(func():
		# Cancelar qualquer tween anterior
		var tweens = get_tree().get_processed_tweens()
		for tween in tweens:
			if tween.is_valid():
				tween.kill()
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(botao, "scale", Vector2.ONE, 0.2)
	)

func sortear_cartas():
	cartas_sorteadas.clear()
	
	var cartas_temp = cartas_disponiveis.duplicate()
	cartas_temp.shuffle()
	
	var quantidade = min(3, cartas_temp.size())
	for i in range(quantidade):
		cartas_sorteadas.append(cartas_temp[i])

func carregar_info_cartas():
	cartas_info.clear()
	
	for i in range(cartas_sorteadas.size()):
		var carta_path = cartas_sorteadas[i]
		var info = extrair_info_carta(carta_path)
		cartas_info.append(info)
		
		match i:
			0: atualizar_botao_carta(carta1, info)
			1: atualizar_botao_carta(carta2, info)
			2: atualizar_botao_carta(carta3, info)

func extrair_info_carta(carta_path: String) -> Dictionary:
	var info = {
		"nome": "Carta Desconhecida",
		"descricao": "Sem descricao",
		"sprite": null
	}
	
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
	var nome_node = botao.get_node_or_null("MarginContainer/VBoxContainer/Nome")
	var desc_node = botao.get_node_or_null("MarginContainer/VBoxContainer/Descricao")
	
	if not sprite_node or not nome_node or not desc_node:
		criar_estrutura_botao(botao)
		sprite_node = botao.get_node("MarginContainer/VBoxContainer/CardPanel/Sprite")
		nome_node = botao.get_node("MarginContainer/VBoxContainer/Nome")
		desc_node = botao.get_node("MarginContainer/VBoxContainer/Descricao")
	
	if sprite_node and info.sprite:
		sprite_node.texture = info.sprite
	
	if nome_node:
		nome_node.text = info.nome
	
	if desc_node:
		desc_node.text = info.descricao

func criar_estrutura_botao(botao: Button):
	botao.text = ""
	botao.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	botao.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	var panel = Panel.new()
	panel.name = "CardPanel"
	panel.custom_minimum_size = Vector2(280, 280)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(0.8, 0.7, 0.3, 1.0)
	panel.add_theme_stylebox_override("panel", style_box)
	
	vbox.add_child(panel)
	
	var sprite = TextureRect.new()
	sprite.name = "Sprite"
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.offset_left = 20
	sprite.offset_right = -20
	sprite.offset_top = 20
	sprite.offset_bottom = -20
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sprite)
	
	var nome = Label.new()
	nome.name = "Nome"
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.add_theme_font_size_override("font_size", 24)
	nome.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	nome.add_theme_color_override("font_outline_color", Color.BLACK)
	nome.add_theme_constant_override("outline_size", 4)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(nome)
	
	var desc = Label.new()
	desc.name = "Descricao"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 80)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	desc.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	desc.add_theme_constant_override("outline_size", 6)
	desc.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	desc.add_theme_constant_override("shadow_offset_x", 2)
	desc.add_theme_constant_override("shadow_offset_y", 2)
	desc.add_theme_constant_override("shadow_outline_size", 1)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)

func _on_carta_selecionada(indice: int):
	if som_select:
		som_select.play()
	
	if indice < cartas_sorteadas.size():
		var carta_path = cartas_sorteadas[indice]
		var info = cartas_info[indice]
		adicionar_carta_ao_deck(carta_path, info)
	
	if som_select:
		await som_select.finished
	
	get_tree().paused = false
	queue_free()

func adicionar_carta_ao_deck(carta_path: String, info: Dictionary):
	pass
