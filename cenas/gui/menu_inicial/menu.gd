# menu_principal.gd (SIMPLIFICADO)
extends Control

@onready var btn_iniciar = $VBoxContainer/BtnIniciar
@onready var btn_controles = $VBoxContainer/BtnControles
@onready var btn_opcoes = $VBoxContainer/BtnOpcoes
@onready var btn_sair = $VBoxContainer/BtnSair
@onready var painel_controles = $PainelControles
@onready var btn_voltar_controles = $PainelControles/BtnVoltar
@onready var som_navegar = $SomNavegar
@onready var container_botoes = $VBoxContainer

var botoes_menu = []
var indice_atual = 0
var ultimo_input_time = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 1000
	
	# IMPORTANTE: Desativar gameplay no menu inicial E PAUSAR
	Game.finalizar_gameplay()
	get_tree().paused = true  # Pausar enquanto estiver no menu
	
	botoes_menu = [btn_iniciar, btn_controles, btn_opcoes, btn_sair]
	
	btn_iniciar.pressed.connect(_on_iniciar_pressed)
	btn_controles.pressed.connect(_on_controles_pressed)
	btn_opcoes.pressed.connect(_on_opcoes_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)
	btn_voltar_controles.pressed.connect(_on_voltar_controles_pressed)
	
	painel_controles.hide()
	btn_iniciar.grab_focus()
	
	# Configurar fundo escuro do RichTextLabel
	configurar_fundo_controles()
	
	# Ocultar UI do jogo
	toggle_ui_jogo(false)

func configurar_fundo_controles():
	"""Adiciona fundo escuro ao RichTextLabel de controles"""
	var rich_text = $PainelControles/RichTextLabel
	
	if rich_text:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.75)  # Preto 75% opaco
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 20
		style.content_margin_bottom = 20
		
		# Adicionar borda sutil (opcional)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(1, 1, 1, 0.2)  # Branco 20% transparente
		
		rich_text.add_theme_stylebox_override("normal", style)

func toggle_ui_jogo(mostrar: bool):
	"""Oculta/mostra a UI do jogo"""
	# Ocultar GUI (hub_ondas, HubVida)
	var gui = get_node_or_null("../../GUI")
	if gui:
		for child in gui.get_children():
			if child.has_method("hide"):
				child.visible = mostrar
	
	# Ocultar Board/UI (deck de cartas)
	var ui_board = get_node_or_null("../../deck_cartas/Board/UI")
	if ui_board:
		ui_board.visible = mostrar

func _input(event):
	if painel_controles.visible:
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
			btn_voltar_controles.pressed.emit()
		return
	
	var tempo_atual = Time.get_ticks_msec() / 1000.0
	if tempo_atual - ultimo_input_time < 0.2:
		return
	
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_DOWN:
			indice_atual = (indice_atual + 1) % botoes_menu.size()
			botoes_menu[indice_atual].grab_focus()
			som_navegar.play()
			ultimo_input_time = tempo_atual
			
		elif event.button_index == JOY_BUTTON_DPAD_UP:
			indice_atual = (indice_atual - 1) if indice_atual > 0 else botoes_menu.size() - 1
			botoes_menu[indice_atual].grab_focus()
			som_navegar.play()
			ultimo_input_time = tempo_atual
			
		elif event.button_index == JOY_BUTTON_A:
			botoes_menu[indice_atual].pressed.emit()

func _on_iniciar_pressed():
	# IMPORTANTE: Ativar gameplay ao iniciar o jogo
	Game.iniciar_gameplay()
	
	toggle_ui_jogo(true)
	get_tree().paused = false
	queue_free()

func _on_controles_pressed():
	painel_controles.show()
	container_botoes.hide()
	btn_voltar_controles.grab_focus()

func _on_voltar_controles_pressed():
	painel_controles.hide()
	container_botoes.show()
	botoes_menu[indice_atual].grab_focus()

func _on_opcoes_pressed():
	pass # TODO: Implementar opções

func _on_sair_pressed():
	get_tree().quit()
