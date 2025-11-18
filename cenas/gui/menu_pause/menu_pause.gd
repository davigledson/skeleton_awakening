# menu_pause.gd
extends Control

@onready var btn_continuar = $VBoxContainer/BtnContinuar
@onready var btn_opcoes = $VBoxContainer/BtnOpcoes
@onready var btn_controles = $VBoxContainer/BtnControles
@onready var btn_sair = $VBoxContainer/BtnSair
@onready var painel_controles = $PainelControles
@onready var painel_opcoes = $PainelOpcoes  # Painel direto na cena
@onready var btn_voltar_controles = $PainelControles/BtnVoltar
@onready var btn_voltar_opcoes = $PainelOpcoes/BtnVoltar
@onready var slider_volume = $PainelOpcoes/VBoxOpcoes/HBoxVolume/HSliderVolume
@onready var label_volume = $PainelOpcoes/VBoxOpcoes/HBoxVolume/LabelVolume
@onready var btn_mutar_musica = $PainelOpcoes/VBoxOpcoes/BtnMutarMusica
@onready var som_navegar = $SomNavegar
@onready var container_botoes = $VBoxContainer

# Referência para a música do gameplay
var musica_gameplay: AudioStreamPlayer = null
var musica_mutada: bool = false
var volume_antes_mutar: float = 0.0

var botoes_menu = []
var indice_atual = 0
var ultimo_input_time = 0.0
var pode_pressionar = true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 1000
	
	print("[MENU_PAUSE] Menu de pause iniciado!")
	
	# Buscar a música na cena principal
	var cena_principal = get_tree().current_scene
	if cena_principal:
		musica_gameplay = cena_principal.get_node_or_null("musica/AudioStreamPlayer3D")
		if not musica_gameplay:
			musica_gameplay = cena_principal.get_node_or_null("musica")
		
		if musica_gameplay:
			print("[MENU_PAUSE] Música encontrada: ", musica_gameplay.name)
			# Configurar slider com volume atual
			if slider_volume:
				# Garantir que o slider está configurado corretamente
				slider_volume.min_value = 0
				slider_volume.max_value = 100
				slider_volume.step = 1
				
				# Converter dB para porcentagem (0-100)
				var volume_linear = db_to_linear(musica_gameplay.volume_db)
				slider_volume.value = volume_linear * 100
				atualizar_label_volume()
		else:
			print("[MENU_PAUSE] ⚠️ Música não encontrada")
	
	# Lista de botões
	botoes_menu = [btn_continuar, btn_opcoes, btn_controles, btn_sair]
	
	# Conectar sinais
	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_opcoes.pressed.connect(_on_opcoes_pressed)
	btn_controles.pressed.connect(_on_controles_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)
	btn_voltar_controles.pressed.connect(_on_voltar_controles_pressed)
	btn_voltar_opcoes.pressed.connect(_on_voltar_opcoes_pressed)
	
	# Conectar controles de volume
	if slider_volume:
		slider_volume.value_changed.connect(_on_volume_changed)
	if btn_mutar_musica:
		btn_mutar_musica.pressed.connect(_on_mutar_pressed)
		atualizar_texto_botao_mutar()
	
	# Conectar sinais de foco
	for i in range(botoes_menu.size()):
		botoes_menu[i].focus_entered.connect(func(): _on_botao_focus_mudou(i))
	
	painel_controles.hide()
	painel_opcoes.hide()
	configurar_fundo_controles()
	configurar_fundo_opcoes()
	hide()

func _on_botao_focus_mudou(novo_indice: int):
	"""Sincroniza o índice quando o foco muda"""
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

func configurar_fundo_opcoes():
	"""Adiciona fundo escuro ao painel de opções"""
	if not painel_opcoes:
		return
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.8, 0.6, 0.2, 0.5)
	
	painel_opcoes.add_theme_stylebox_override("panel", style)

func _input(event):
	# Debug
	if event is InputEventKey and event.pressed:
		print("[MENU_PAUSE] Tecla: ", event.keycode, " | ESC = ", KEY_ESCAPE)
	
	# Verificar se menu inicial está aberto
	var menu_inicial_aberto = get_tree().root.has_node("menu_inicial")
	if menu_inicial_aberto:
		return
	
	# Detectar ESC ou botão START
	var tecla_pause = (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)
	var botao_pause = (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	
	if tecla_pause or botao_pause:
		print("[MENU_PAUSE] Pause detectado! Visível: ", visible)
		
		if visible:
			# Menu visível - verificar se pode fechar
			if not painel_controles.visible and not painel_opcoes.visible:
				print("[MENU_PAUSE] Despausando...")
				_on_continuar_pressed()
				get_viewport().set_input_as_handled()
		else:
			# Menu invisível - abrir
			print("[MENU_PAUSE] Pausando...")
			abrir_menu_pause()
			get_viewport().set_input_as_handled()
		return
	
	# Ignorar se menu invisível
	if not visible:
		return
	
	# Painel de controles aberto
	if painel_controles.visible:
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
			btn_voltar_controles.pressed.emit()
		return
	
	# Painel de opções aberto
	if painel_opcoes.visible:
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
			btn_voltar_opcoes.pressed.emit()
		return
	
	# Navegação do menu principal
	var tempo_atual = Time.get_ticks_msec() / 1000.0
	if tempo_atual - ultimo_input_time < 0.2:
		return
	
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

func abrir_menu_pause():
	"""Abre o menu de pause"""
	print("[MENU_PAUSE] Abrindo menu...")
	show()
	get_tree().paused = true
	btn_continuar.grab_focus()
	indice_atual = 0
	pode_pressionar = true
	print("[MENU_PAUSE] Jogo pausado!")

func _on_continuar_pressed():
	"""Despausar e continuar"""
	hide()
	get_tree().paused = false
	print("[MENU_PAUSE] Jogo despausado!")

func _on_opcoes_pressed():
	"""Abrir painel de opções"""
	painel_opcoes.show()
	container_botoes.hide()
	btn_voltar_opcoes.grab_focus()
	pode_pressionar = true

func _on_voltar_opcoes_pressed():
	"""Voltar das opções"""
	painel_opcoes.hide()
	container_botoes.show()
	botoes_menu[indice_atual].grab_focus()
	pode_pressionar = true

func _on_controles_pressed():
	"""Abrir painel de controles"""
	painel_controles.show()
	container_botoes.hide()
	btn_voltar_controles.grab_focus()
	pode_pressionar = true

func _on_voltar_controles_pressed():
	"""Voltar dos controles"""
	painel_controles.hide()
	container_botoes.show()
	botoes_menu[indice_atual].grab_focus()
	pode_pressionar = true

func _on_sair_pressed():
	"""Sair do jogo"""
	get_tree().quit()

# ===== CONTROLE DE VOLUME =====

func _on_volume_changed(value: float):
	"""Ajusta o volume da música"""
	if not musica_gameplay:
		return
	
	# Garantir que o valor está entre 0 e 100
	value = clamp(value, 0, 100)
	
	# Atualizar o slider para garantir que não ultrapasse 100
	if slider_volume and slider_volume.value != value:
		slider_volume.value = value
	
	# Converter de porcentagem (0-100) para linear (0-1) e depois para dB
	var volume_linear = value / 100.0
	
	if volume_linear <= 0.01:
		musica_gameplay.volume_db = -80  # Silêncio
	else:
		musica_gameplay.volume_db = linear_to_db(volume_linear)
	
	atualizar_label_volume()
	
	if musica_mutada and value > 1:
		musica_mutada = false
		atualizar_texto_botao_mutar()

func atualizar_label_volume():
	"""Atualiza o label de porcentagem"""
	if not label_volume or not slider_volume:
		return
	
	var porcentagem = int(slider_volume.value)
	label_volume.text = str(porcentagem) + "%"

func _on_mutar_pressed():
	"""Muta/desmuta a música"""
	if not musica_gameplay or not slider_volume:
		return
	
	musica_mutada = !musica_mutada
	
	if musica_mutada:
		volume_antes_mutar = slider_volume.value
		slider_volume.value = 0
		musica_gameplay.volume_db = -80
		print("[MENU_PAUSE] 🔇 Música mutada")
	else:
		var volume_restaurar = volume_antes_mutar if volume_antes_mutar > 1 else 50
		slider_volume.value = volume_restaurar
		musica_gameplay.volume_db = linear_to_db(volume_restaurar / 100.0)
		print("[MENU_PAUSE] 🔊 Música ativada")
	
	atualizar_texto_botao_mutar()
	atualizar_label_volume()

func atualizar_texto_botao_mutar():
	"""Atualiza texto do botão"""
	if not btn_mutar_musica:
		return
	
	if musica_mutada or (slider_volume and slider_volume.value <= 1):
		btn_mutar_musica.text = "🔇 Ativar Música"
	else:
		btn_mutar_musica.text = "🔊 Desativar Música"
