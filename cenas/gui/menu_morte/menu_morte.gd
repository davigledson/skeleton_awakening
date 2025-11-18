# menu_morte.gd
extends Control

@onready var btn_reiniciar = $VBoxContainer/BtnReiniciar
@onready var btn_sair = $VBoxContainer/BtnSair
@onready var som_navegar = $SomNavegar
@onready var label_morte = $VBoxContainer/Label

var botoes_menu = []
var indice_atual = 0
var ultimo_input_time = 0.0
var pode_pressionar = true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 1000
	
	# Lista de botões
	botoes_menu = [btn_reiniciar, btn_sair]
	
	# Conectar sinais
	btn_reiniciar.pressed.connect(_on_reiniciar_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)
	
	# Conectar sinais de foco
	for i in range(botoes_menu.size()):
		botoes_menu[i].focus_entered.connect(func(): _on_botao_focus_mudou(i))
	
	# Configurar estilo do label
	configurar_label_morte()
	
	# Iniciar escondido
	hide()

func _on_botao_focus_mudou(novo_indice: int):
	"""Sincroniza o índice quando o foco muda"""
	indice_atual = novo_indice

func configurar_label_morte():
	"""Configura o estilo do texto 'VOCÊ MORREU'"""
	if label_morte:
		label_morte.add_theme_font_size_override("font_size", 48)
		label_morte.add_theme_color_override("font_color", Color(0.8, 0, 0))

func _input(event):
	# Ignorar inputs se o menu estiver invisível
	if not visible:
		return
	
	# Cooldown de navegação
	var tempo_atual = Time.get_ticks_msec() / 1000.0
	if tempo_atual - ultimo_input_time < 0.2:
		return
	
	# Navegação com joystick
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_DOWN:
			indice_atual = (indice_atual + 1) % botoes_menu.size()
			botoes_menu[indice_atual].grab_focus()
			if som_navegar:
				som_navegar.play()
			ultimo_input_time = tempo_atual
			pode_pressionar = false
			get_tree().create_timer(0.3).timeout.connect(func(): pode_pressionar = true)
			
		elif event.button_index == JOY_BUTTON_DPAD_UP:
			indice_atual = (indice_atual - 1) if indice_atual > 0 else botoes_menu.size() - 1
			botoes_menu[indice_atual].grab_focus()
			if som_navegar:
				som_navegar.play()
			ultimo_input_time = tempo_atual
			pode_pressionar = false
			get_tree().create_timer(0.3).timeout.connect(func(): pode_pressionar = true)
			
		elif event.button_index == JOY_BUTTON_A and pode_pressionar:
			botoes_menu[indice_atual].pressed.emit()
			pode_pressionar = false
			get_tree().create_timer(0.3).timeout.connect(func(): pode_pressionar = true)

func mostrar_menu_morte():
	"""Mostra o menu de morte"""
	show()
	get_tree().paused = true
	btn_reiniciar.grab_focus()
	indice_atual = 0
	pode_pressionar = true
	
	# Desabilitar gameplay
	if Game.has_method("desativar_gameplay"):
		Game.desativar_gameplay()

func _on_reiniciar_pressed():
	"""Reinicia a fase atual"""
	get_tree().paused = false
	
	# Reativar gameplay
	if Game.has_method("ativar_gameplay"):
		Game.ativar_gameplay()
	
	# Recarregar a cena atual
	get_tree().reload_current_scene()

func _on_sair_pressed():
	"""Sai do jogo"""
	get_tree().quit()
