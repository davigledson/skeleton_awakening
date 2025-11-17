
# ============================================
# CardContainer.gd - ARQUIVO SEPARADO
# ============================================
extends HBoxContainer

@onready var Game = preload("res://cenas/cartas/Game.gd").new()

var startPosition
var maxCardsAllowed = 6

# ===== NOVAS VARIÁVEIS PARA JOYSTICK =====
var current_card_index = 0  # Índice da carta selecionada
var is_container_active = false  # Se o container está ativo para navegação
var previous_selected_card = null

const JOYSTICK_DEADZONE = 0.3
var joystick_cooldown = 0.0
const JOYSTICK_COOLDOWN_TIME = 0.2
# =========================================

func _ready():
	self.size.x = maxCardsAllowed * 105
	self.pivot_offset.x = maxCardsAllowed * 52.5
	var projectResolution = ProjectSettings.get_setting("display/window/size/viewport_width")
	var projectResolutionHeight = ProjectSettings.get_setting("display/window/size/viewport_height")
	self.global_position.x = projectResolution / 4
	self.global_position.y = (projectResolutionHeight) - 60
	startPosition = self.position

# ===== NOVA FUNÇÃO _process PARA JOYSTICK =====
func _process(delta):
	if joystick_cooldown > 0:
		joystick_cooldown -= delta
	
	# Abrir/Fechar menu de cartas com X (Xbox) / Quadrado (PlayStation)
	if Input.is_joy_button_pressed(0, JOY_BUTTON_X):
		if joystick_cooldown <= 0:
			if is_container_active:
				desativar_navegacao()
			else:
				ativar_navegacao()
			joystick_cooldown = JOYSTICK_COOLDOWN_TIME
	
	if is_container_active:
		processar_navegacao_joystick(delta)
# ==============================================

# ===== NOVAS FUNÇÕES PARA JOYSTICK =====
func ativar_navegacao():
	is_container_active = true
	current_card_index = 0
	mostrar_container()
	atualizar_selecao_carta()
	print("🎮 Navegação de cartas ativada")

func desativar_navegacao():
	is_container_active = false
	if previous_selected_card:
		previous_selected_card.desselecionar_com_joystick()
		previous_selected_card = null
	esconder_container()
	print("🎮 Navegação de cartas desativada")

func processar_navegacao_joystick(delta):
	if joystick_cooldown > 0:
		return
	
	var cartas = get_children()
	if cartas.is_empty():
		desativar_navegacao()
		return
	
	# Navegar com LB (Left Bumper) e RB (Right Bumper)
	if Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER):
		navegar_esquerda()
		joystick_cooldown = JOYSTICK_COOLDOWN_TIME
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER):
		navegar_direita()
		joystick_cooldown = JOYSTICK_COOLDOWN_TIME
	
	# Usar carta com O (Circle - PlayStation) / B (Xbox)
	if Input.is_joy_button_pressed(0, JOY_BUTTON_B):
		usar_carta_selecionada()
		joystick_cooldown = JOYSTICK_COOLDOWN_TIME

func navegar_esquerda():
	var cartas = get_children()
	if cartas.is_empty():
		return
	
	current_card_index = (current_card_index - 1) % cartas.size()
	if current_card_index < 0:
		current_card_index = cartas.size() - 1
	atualizar_selecao_carta()

func navegar_direita():
	var cartas = get_children()
	if cartas.is_empty():
		return
	
	current_card_index = (current_card_index + 1) % cartas.size()
	atualizar_selecao_carta()

func atualizar_selecao_carta():
	var cartas = get_children()
	if cartas.is_empty():
		return
	
	if previous_selected_card and previous_selected_card.has_method("desselecionar_com_joystick"):
		previous_selected_card.desselecionar_com_joystick()
	
	var carta_atual = cartas[current_card_index]
	if carta_atual.has_method("selecionar_com_joystick"):
		carta_atual.selecionar_com_joystick()
	previous_selected_card = carta_atual

func usar_carta_selecionada():
	var cartas = get_children()
	if cartas.is_empty():
		return
	
	var carta = cartas[current_card_index]
	if carta.has_method("usar_carta_com_joystick"):
		carta.usar_carta_com_joystick()
	
	desativar_navegacao()

func mostrar_container():
	var target_position = startPosition + Vector2(0, -100)
	var tween = get_tree().create_tween()
	var tween2 = get_tree().create_tween()
	tween.tween_property(self, "position", target_position, 0.2)
	tween2.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2)

func esconder_container():
	if not Game.cardSelected:
		var tween = get_tree().create_tween()
		var tween2 = get_tree().create_tween()
		tween.tween_property(self, "position", startPosition, 0.2)
		tween2.tween_property(self, "scale", Vector2(1, 1), 0.2)
# =======================================

func _on_mouse_entered():
	mostrar_container()

func _on_mouse_exited():
	if not Game.cardSelected and not is_container_active:
		esconder_container()
