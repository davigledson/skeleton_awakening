# card.gd - Com suporte a Joystick e Cooldown
extends Control
class_name Card

@onready var card_holder_scene = preload("res://cenas/cartas/cardHolder.tscn")

var startPosition
var cardHighlighted = false
var is_dragging = false
var is_selected_by_joystick = false  # Seleção via controle

@export var carta_nome: String = "Carta Base"
@export_enum("Ataque", "Cura", "Velocidade", "Dano em Área") var carta_tipo: int = 0
@export var carta_valor: int = 10
@export var carta_descricao: String = "Descrição da carta"
@export var requer_inimigos: bool = true

# Sistema de Cooldown
var em_cooldown = false
var tempo_cooldown = 5.0
var cooldown_atual = 0.0

# Nó de feedback visual do cooldown
var cooldown_overlay: ColorRect
var cooldown_label: Label

func _ready():
	startPosition = position
	print("🃏 Carta criada: ", carta_nome, " | Tipo: ", carta_tipo, " | Valor: ", carta_valor)
	
	# Criar overlay de cooldown
	criar_overlay_cooldown()
	
	on_card_ready()
	
	# Conectar ao sistema de seleção por controle
	add_to_group("cartas_selecionaveis")

func criar_overlay_cooldown():
	"""Cria o overlay visual que mostra o cooldown"""
	cooldown_overlay = ColorRect.new()
	cooldown_overlay.color = Color(0, 0, 0, 0.7)  # Preto semi-transparente
	cooldown_overlay.anchors_preset = Control.PRESET_FULL_RECT
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_overlay.hide()
	add_child(cooldown_overlay)
	
	# Label para mostrar o tempo
	cooldown_label = Label.new()
	cooldown_label.anchors_preset = Control.PRESET_CENTER
	cooldown_label.anchor_left = 0.5
	cooldown_label.anchor_top = 0.5
	cooldown_label.anchor_right = 0.5
	cooldown_label.anchor_bottom = 0.5
	cooldown_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cooldown_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Estilo do texto
	cooldown_label.add_theme_font_size_override("font_size", 32)
	cooldown_label.add_theme_color_override("font_color", Color.WHITE)
	cooldown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	cooldown_label.add_theme_constant_override("outline_size", 4)
	
	cooldown_overlay.add_child(cooldown_label)

func _process(delta):
	if em_cooldown:
		processar_cooldown(delta)

func processar_cooldown(delta):
	"""Atualiza o cooldown da carta"""
	cooldown_atual -= delta
	
	# Atualizar o texto do label
	cooldown_label.text = str(ceil(cooldown_atual))
	
	if cooldown_atual <= 0:
		finalizar_cooldown()

func iniciar_cooldown():
	"""Inicia o cooldown da carta"""
	em_cooldown = true
	cooldown_atual = tempo_cooldown
	cooldown_overlay.show()
	
	# Desabilitar interações
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	print("⏳ Cooldown iniciado: ", carta_nome, " (", tempo_cooldown, "s)")

func finalizar_cooldown():
	"""Finaliza o cooldown e torna a carta utilizável novamente"""
	em_cooldown = false
	cooldown_atual = 0.0
	cooldown_overlay.hide()
	
	# Reabilitar interações
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Feedback visual de carta pronta
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	print("✅ Cooldown finalizado: ", carta_nome, " - Carta pronta!")

func on_card_ready():
	pass

func selecionar_com_joystick():
	"""Chamado quando a carta é selecionada via controle"""
	if em_cooldown:
		return
	
	is_selected_by_joystick = true
	if has_node("Anim"):
		$Anim.play("Select")
	
	# Feedback visual extra para seleção por controle
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.2)

func desselecionar_com_joystick():
	"""Chamado quando a carta é desselecionada via controle"""
	is_selected_by_joystick = false
	if has_node("Anim"):
		$Anim.play("DeSelect")
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2)

func usar_carta_com_joystick():
	"""Ativa a carta quando o botão de usar (A/X) é pressionado"""
	if em_cooldown:
		print("⏳ Carta em cooldown: ", carta_nome)
		feedback_cooldown()
		return
	
	print("🎮 Carta usada com controle: ", carta_nome)
	is_dragging = true
	criar_card_holder()
	Game.cardSelected = true
	esconder_visual()
	
	# Aguardar um frame e soltar
	await get_tree().process_frame
	soltar_carta()

func feedback_cooldown():
	"""Feedback visual quando tenta usar carta em cooldown"""
	var tween = create_tween()
	tween.tween_property(self, "rotation", -0.1, 0.05)
	tween.tween_property(self, "rotation", 0.1, 0.1)
	tween.tween_property(self, "rotation", 0, 0.05)

func _on_mouse_entered():
	if em_cooldown:
		return
	
	if has_node("Anim"):
		$Anim.play("Select")
	cardHighlighted = true

func _on_mouse_exited():
	if em_cooldown:
		return
	
	if has_node("Anim"):
		$Anim.play("DeSelect")
	cardHighlighted = false

func _on_gui_input(event):
	if em_cooldown:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			feedback_cooldown()
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if cardHighlighted:
				print("👆 Carta selecionada: ", carta_nome)
				is_dragging = true
				criar_card_holder()
				Game.cardSelected = true
				esconder_visual()
		else:
			if is_dragging:
				soltar_carta()

func criar_card_holder():
	var cardTemp = card_holder_scene.instantiate()
	
	if get_child_count() > 0:
		for child in get_children():
			if child != cooldown_overlay and (child is Sprite2D or child is TextureRect):
				var sprite_copia = child.duplicate()
				sprite_copia.show()
				cardTemp.add_child(sprite_copia)
				break
	
	var holder = get_node_or_null("../../../CardHolder")
	if holder:
		holder.add_child(cardTemp)

func esconder_visual():
	for child in get_children():
		if child != cooldown_overlay and child != cooldown_label:
			if child is Sprite2D or child is TextureRect:
				child.hide()

func restaurar_visual():
	for child in get_children():
		if child != cooldown_overlay and child != cooldown_label:
			if child is Sprite2D or child is TextureRect:
				child.show()

func tem_inimigos_disponiveis() -> bool:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	return not inimigos.is_empty()

func soltar_carta():
	if em_cooldown:
		return
	
	if requer_inimigos and not tem_inimigos_disponiveis():
		print("⚠️ Não há inimigos! Carta cancelada: ", carta_nome)
		cancelar_carta()
		return
	
	is_dragging = false
	Game.cardSelected = false
	
	print("✅ Carta jogada: ", carta_nome)
	
	# Ativar efeito
	await ativar_efeito()
	
	# Restaurar visual e iniciar cooldown
	restaurar_visual()
	iniciar_cooldown()

func cancelar_carta():
	is_dragging = false
	Game.cardSelected = false
	restaurar_visual()
	
	var holder = get_node_or_null("../../../CardHolder")
	if holder:
		for child in holder.get_children():
			child.queue_free()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func ativar_efeito():
	print("⚠️ AVISO: ativar_efeito() não foi implementado em ", carta_nome)
	push_warning("Carta " + carta_nome + " não tem efeito implementado!")
