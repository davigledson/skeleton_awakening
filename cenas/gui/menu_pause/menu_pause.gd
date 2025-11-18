# menu_pause.gd
extends Control

@onready var btn_continuar = $VBoxContainer/BtnContinuar
@onready var btn_controles = $VBoxContainer/BtnControles
@onready var btn_sair = $VBoxContainer/BtnSair
@onready var painel_controles = $PainelControles
@onready var btn_voltar_controles = $PainelControles/BtnVoltar
@onready var som_navegar = $SomNavegar
@onready var container_botoes = $VBoxContainer

# Caminho do menu principal (não usado mais, mas mantido por compatibilidade)
# @export_file("*.tscn") var cena_menu_principal: String = "res://cenas/menu_inicial.tscn"

var botoes_menu = []
var indice_atual = 0
var ultimo_input_time = 0.0
var pode_pressionar = true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 1000
	
	# Lista de botões corrigida (sem Menu Principal)
	botoes_menu = [btn_continuar, btn_controles, btn_sair]
	
	# Conectar sinais
	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_controles.pressed.connect(_on_controles_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)
	btn_voltar_controles.pressed.connect(_on_voltar_controles_pressed)
	
	# Conectar sinais de foco para sincronizar o índice
	for i in range(botoes_menu.size()):
		botoes_menu[i].focus_entered.connect(func(): _on_botao_focus_mudou(i))
	
	painel_controles.hide()
	
	# Configurar fundo escuro do RichTextLabel
	configurar_fundo_controles()
	
	# Iniciar escondido (NÃO mexer no paused aqui!)
	hide()

func _on_botao_focus_mudou(novo_indice: int):
	"""Sincroniza o índice quando o foco muda (por mouse ou teclado)"""
	indice_atual = novo_indice

func configurar_fundo_controles():
	"""Adiciona fundo escuro ao RichTextLabel de controles"""
	var rich_text = $PainelControles/RichTextLabel
	
	if rich_text:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.75)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 20
		style.content_margin_bottom = 20
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(1, 1, 1, 0.2)
		
		rich_text.add_theme_stylebox_override("normal", style)

func _input(event):
	# Só permite pausar se o gameplay estiver ativo
	if not Game.gameplay_ativo:
		return
	
	# Debug - remova depois de funcionar
	if event is InputEventKey and event.pressed:
		print("Tecla pressionada: ", event.keycode)
	if event is InputEventJoypadButton and event.pressed:
		print("Botão joystick pressionado: ", event.button_index)
	
	# Detectar ESC ou botão START do joystick para pausar/despausar
	# Testar primeiro com tecla ESC diretamente
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or \
	   (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		print("Pause detectado! Menu visível: ", visible)
		if visible:
			# Se o menu estiver visível, despausar
			if not painel_controles.visible:
				_on_continuar_pressed()
				get_viewport().set_input_as_handled()
		else:
			# Se o menu estiver invisível, pausar
			abrir_menu_pause()
			get_viewport().set_input_as_handled()
		return
	
	# Ignorar inputs se o menu estiver invisível
	if not visible:
		return
	
	# Ignorar se painel de controles estiver aberto
	if painel_controles.visible:
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
			btn_voltar_controles.pressed.emit()
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
			# Permitir pressionar novamente após um delay
			get_tree().create_timer(0.3).timeout.connect(func(): pode_pressionar = true)
			
		elif event.button_index == JOY_BUTTON_DPAD_UP:
			indice_atual = (indice_atual - 1) if indice_atual > 0 else botoes_menu.size() - 1
			botoes_menu[indice_atual].grab_focus()
			if som_navegar:
				som_navegar.play()
			ultimo_input_time = tempo_atual
			pode_pressionar = false
			# Permitir pressionar novamente após um delay
			get_tree().create_timer(0.3).timeout.connect(func(): pode_pressionar = true)
			
		elif event.button_index == JOY_BUTTON_A and pode_pressionar:
			botoes_menu[indice_atual].pressed.emit()
			pode_pressionar = false
			# Permitir pressionar novamente após um delay
			get_tree().create_timer(0.3).timeout.connect(func(): pode_pressionar = true)

func abrir_menu_pause():
	"""Abre o menu de pause"""
	print("Abrindo menu de pause...")
	show()
	get_tree().paused = true
	btn_continuar.grab_focus()
	indice_atual = 0
	pode_pressionar = true
	print("Menu aberto. Jogo pausado: ", get_tree().paused)

func _on_continuar_pressed():
	"""Despausar e continuar jogando"""
	hide()
	get_tree().paused = false

func _on_controles_pressed():
	painel_controles.show()
	container_botoes.hide()
	btn_voltar_controles.grab_focus()
	pode_pressionar = true

func _on_voltar_controles_pressed():
	painel_controles.hide()
	container_botoes.show()
	botoes_menu[indice_atual].grab_focus()
	pode_pressionar = true

func _on_sair_pressed():
	"""Sair do jogo"""
	get_tree().quit()
