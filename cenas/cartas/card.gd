# card.gd (SCRIPT BASE - NÃO MODIFICAR)
# Este script contém toda a lógica de arrastar/soltar
# Cartas específicas herdam deste script
extends Control
class_name Card

@onready var card_holder_scene = preload("res://cenas/cartas/cardHolder.tscn")
var startPosition
var cardHighlighted = false
var is_dragging = false

# DADOS DA CARTA - Configure no Inspetor ou sobrescreva nas classes filhas
@export var carta_nome: String = "Carta Base"
@export_enum("Ataque", "Cura", "Velocidade", "Dano em Área") var carta_tipo: int = 0
@export var carta_valor: int = 10
@export var carta_descricao: String = "Descrição da carta"

func _ready():
	startPosition = position
	print("🃏 Carta criada: ", carta_nome, " | Tipo: ", carta_tipo, " | Valor: ", carta_valor)
	on_card_ready()

func on_card_ready():
	# Hook para classes filhas sobrescreverem
	pass

func _on_mouse_entered():
	if has_node("Anim"):
		$Anim.play("Select")
	cardHighlighted = true
	print("🖱️ Mouse sobre: ", carta_nome)

func _on_mouse_exited():
	if has_node("Anim"):
		$Anim.play("DeSelect")
	cardHighlighted = false

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Botão pressionado - iniciar arrasto
			if cardHighlighted:
				print("👆 Carta selecionada: ", carta_nome)
				is_dragging = true
				criar_card_holder()
				Game.cardSelected = true
				esconder_visual()
		else:
			# Botão solto - finalizar arrasto
			if is_dragging:
				soltar_carta()

func criar_card_holder():
	"""Cria o visual da carta sendo arrastada"""
	var cardTemp = card_holder_scene.instantiate()
	
	# Copiar visual da carta
	if get_child_count() > 0:
		var sprite_original = get_child(0)
		var sprite_copia = sprite_original.duplicate()
		sprite_copia.show()
		cardTemp.add_child(sprite_copia)
	
	# Adicionar ao CardHolder na hierarquia
	var holder = get_node_or_null("../../../CardHolder")
	if holder:
		holder.add_child(cardTemp)
		print("✅ CardHolder criado")
	else:
		print("❌ CardHolder não encontrado na hierarquia!")

func esconder_visual():
	"""Esconde a carta original durante o arrasto"""
	if get_child_count() > 0:
		var sprite = get_child(0)
		if sprite is Sprite2D or sprite is TextureRect:
			sprite.hide()

func restaurar_visual():
	"""Mostra a carta de volta se cancelar"""
	if get_child_count() > 0:
		var sprite = get_child(0)
		if sprite is Sprite2D or sprite is TextureRect:
			sprite.show()

func soltar_carta():
	"""Chamado quando o jogador solta a carta"""
	is_dragging = false
	
	print("🔍 Mouse na área: ", Game.mouseOnPlacement)
	
	# IMPORTANTE: Desmarcar carta como selecionada PRIMEIRO
	# Isso faz o CardHolder se auto-destruir automaticamente
	Game.cardSelected = false
	
	if !Game.mouseOnPlacement:
		# Soltou fora da área - cancelar
		print("❌ Carta soltada fora da área")
		cardHighlighted = false
		restaurar_visual()
	else:
		# Soltou na área correta - ATIVAR EFEITO!
		print("✅ Carta jogada: ", carta_nome)
		ativar_efeito()
		notificar_placement()
		
		# Destruir a carta original após usar
		queue_free()

func notificar_placement():
	"""Notifica o CardPlacement que uma carta foi jogada"""
	var placement = get_node_or_null("../../CardPlacement")
	if placement and placement.has_method("placeCard"):
		placement.placeCard()

# MÉTODO PRINCIPAL - Classes filhas DEVEM sobrescrever este método
func ativar_efeito():
	"""
	Sobrescreva este método nas cartas específicas!
	Exemplo em carta_atk_basico.gd:
	
	func ativar_efeito():
		Game.ativar_efeito_carta(0, 15)  # Ataque +15
	"""
	print("⚠️ AVISO: ativar_efeito() não foi implementado em ", carta_nome)
	push_warning("Carta " + carta_nome + " não tem efeito implementado!")
