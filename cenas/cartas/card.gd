# card.gd (SCRIPT BASE - CORRIGIDO)
extends Control
class_name Card

@onready var card_holder_scene = preload("res://cenas/cartas/cardHolder.tscn")

var startPosition
var cardHighlighted = false
var is_dragging = false
var carta_sendo_destruida = false

@export var carta_nome: String = "Carta Base"
@export_enum("Ataque", "Cura", "Velocidade", "Dano em Área") var carta_tipo: int = 0
@export var carta_valor: int = 10
@export var carta_descricao: String = "Descrição da carta"
@export var requer_inimigos: bool = true  # Se a carta precisa de inimigos para funcionar

func _ready():
	startPosition = position
	print("🃏 Carta criada: ", carta_nome, " | Tipo: ", carta_tipo, " | Valor: ", carta_valor)
	on_card_ready()

func on_card_ready():
	pass

func _on_mouse_entered():
	if has_node("Anim"):
		$Anim.play("Select")
	cardHighlighted = true

func _on_mouse_exited():
	if has_node("Anim"):
		$Anim.play("DeSelect")
	cardHighlighted = false

func _on_gui_input(event):
	if carta_sendo_destruida:
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
		var sprite_original = get_child(0)
		var sprite_copia = sprite_original.duplicate()
		sprite_copia.show()
		cardTemp.add_child(sprite_copia)
	
	var holder = get_node_or_null("../../../CardHolder")
	if holder:
		holder.add_child(cardTemp)

func esconder_visual():
	if get_child_count() > 0:
		var sprite = get_child(0)
		if sprite is Sprite2D or sprite is TextureRect:
			sprite.hide()

func restaurar_visual():
	if get_child_count() > 0:
		var sprite = get_child(0)
		if sprite is Sprite2D or sprite is TextureRect:
			sprite.show()

func tem_inimigos_disponiveis() -> bool:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	return not inimigos.is_empty()

func soltar_carta():
	if carta_sendo_destruida:
		return
	
	# Verificar se a carta precisa de inimigos e se existem inimigos
	if requer_inimigos and not tem_inimigos_disponiveis():
		print("⚠️ Não há inimigos! Carta cancelada: ", carta_nome)
		cancelar_carta()
		return
	
	carta_sendo_destruida = true
	is_dragging = false
	Game.cardSelected = false
	
	print("✅ Carta jogada: ", carta_nome)
	
	await ativar_efeito()
	await get_tree().create_timer(0.5).timeout
	
	print("🗑️ Destruindo carta: ", carta_nome)
	queue_free()

func cancelar_carta():
	"""Cancela o uso da carta e restaura ao estado inicial"""
	is_dragging = false
	Game.cardSelected = false
	restaurar_visual()
	
	# Remover o CardHolder temporário
	var holder = get_node_or_null("../../../CardHolder")
	if holder:
		for child in holder.get_children():
			child.queue_free()
	
	# Feedback visual de cancelamento (opcional)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func ativar_efeito():
	print("⚠️ AVISO: ativar_efeito() não foi implementado em ", carta_nome)
	push_warning("Carta " + carta_nome + " não tem efeito implementado!")
