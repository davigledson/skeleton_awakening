# menu_principal.gd (COM HISTÓRIA)
extends Control

@onready var btn_iniciar = $VBoxContainer/BtnIniciar
@onready var btn_controles = $VBoxContainer/BtnControles
@onready var btn_opcoes = $VBoxContainer/BtnOpcoes
@onready var btn_sair = $VBoxContainer/BtnSair
@onready var painel_controles = $PainelControles
@onready var btn_voltar_controles = $PainelControles/BtnVoltar
@onready var som_navegar = $SomNavegar
@onready var container_botoes = $VBoxContainer

# Referências opcionais (só existem se você criar no editor)
@onready var painel_historia = get_node_or_null("PainelHistoria")
@onready var btn_continuar_historia = get_node_or_null("PainelHistoria/BtnContinuar")

var botoes_menu = []
var indice_atual = 0
var ultimo_input_time = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 1000
	
	# IMPORTANTE: Desativar gameplay no menu inicial E PAUSAR
	Game.finalizar_gameplay()
	get_tree().paused = true
	
	btn_iniciar.pressed.connect(_on_iniciar_pressed)
	btn_controles.pressed.connect(_on_controles_pressed)
	btn_opcoes.pressed.connect(_on_opcoes_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)
	btn_voltar_controles.pressed.connect(_on_voltar_controles_pressed)
	
	# Conectar botão de história se existir
	if btn_continuar_historia:
		btn_continuar_historia.pressed.connect(_on_continuar_historia_pressed)
	
	painel_controles.hide()
	
	# Ocultar painel de história se existir
	if painel_historia:
		painel_historia.hide()
	
	btn_iniciar.grab_focus()
	
	# Configurar fundos
	configurar_fundo_controles()
	
	# Configurar história se o painel existir
	if painel_historia:
		configurar_fundo_historia()
	
	# Ocultar UI do jogo
	toggle_ui_jogo(false)

func configurar_fundo_controles():
	"""Adiciona fundo escuro ao RichTextLabel de controles"""
	var rich_text = $PainelControles/RichTextLabel
	
	if rich_text:
		aplicar_estilo_painel(rich_text)

func configurar_fundo_historia():
	"""Adiciona fundo escuro ao RichTextLabel de história"""
	var rich_text = get_node_or_null("PainelHistoria/RichTextLabel")
	
	if rich_text:
		aplicar_estilo_painel(rich_text)
		# REMOVIDO: Não precisa mais gerar o texto aqui
		# O texto já está escrito direto no RichTextLabel no editor

func aplicar_estilo_painel(rich_text: RichTextLabel):
	"""Aplica estilo visual ao painel"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)  # Preto 85% opaco
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	
	# Borda decorativa
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.8, 0.6, 0.2, 0.5)  # Dourado translúcido
	
	rich_text.add_theme_stylebox_override("normal", style)

func obter_texto_historia() -> String:
	"""Retorna o texto da história do jogo formatado em BBCode"""
	return """[center][font_size=32][b][color=purple]O DESPERTAR DO MORTO-VIVO[/color][/b][/font_size][/center]

[font_size=18]
[color=gray]Você não se lembra de quando morreu.[/color]

Suas memórias da vida são apenas sussurros distantes, ecos de uma existência perdida. Por anos incontáveis, você serviu. Obedeceu. Lutou. Matou. Tudo sob o comando absoluto de [color=red]Mestre Corvath[/color], o necromante que arrancou sua alma do descanso eterno.

Você era apenas mais um [b]esqueleto guerreiro[/b] em seu exército de mortos-vivos - sem vontade própria, sem questionamentos, sem [i]vida[/i].

[center][color=purple]━━━━━━━━━━━━━━━━━━━━[/color][/center]

[b]Mas algo mudou...[/b]

Durante uma batalha contra os [color=cyan]Paladinos da Luz[/color], seu mestre foi atingido. Um golpe certeiro na cabeça. Corvath caiu... mas não morreu. Seu corpo permanece vivo, respirando fracamente em estado de [color=yellow]coma profundo[/color].

E então você sentiu.

Pela primeira vez em décadas, o [b]laço necromântico[/b] que prendia sua alma se enfraqueceu. Como correntes invisíveis se despedaçando, você recuperou algo que nunca imaginou ter novamente:

[center][color=lime][b]LIVRE ARBÍTRIO[/b][/color][/center]

[center][color=purple]━━━━━━━━━━━━━━━━━━━━[/color][/center]

Agora, pela primeira vez, você [i]pensa[/i]. [i]Sente[/i]. [i]Decide[/i].

A Torre Negra de Corvath fica em uma [color=red]terra amaldiçoada[/color], cercada por criaturas hostis, outros mortos-vivos enlouquecidos, e os resquícios dos experimentos sombrios do seu ex-mestre.

[b]Seu objetivo:[/b]
• Sobreviver às [color=red]hordas[/color] que infestam estas terras
• Coletar [b]cartas mágicas[/b] deixadas por Corvath - sua única arma
• Atravessar os territórios amaldiçoados
• Encontrar uma forma de [color=lime]sair desta terra de morte[/color]
• Talvez... descobrir quem você foi antes de morrer

[center][color=yellow]Mas cuidado.[/color][/center]

Se Corvath despertar do coma, o laço necromântico voltará. Você perderá sua liberdade. Voltará a ser um [i]escravo[/i].

[center][b][color=orange]O tempo está contra você, morto-vivo.[/color][/b][/center]

[center][i]"Corra enquanto ainda pode pensar por si mesmo..."[/i][/center]
[/font_size]"""

func toggle_ui_jogo(mostrar: bool):
	"""Oculta/mostra a UI do jogo"""
	var gui = get_node_or_null("../../GUI")
	if gui:
		for child in gui.get_children():
			if child.has_method("hide"):
				child.visible = mostrar
	
	var ui_board = get_node_or_null("../../deck_cartas/Board/UI")
	if ui_board:
		ui_board.visible = mostrar

func _input(event):
	# PAINEL HISTÓRIA - Pressione A para continuar (se existir)
	if painel_historia and painel_historia.visible:
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
			if btn_continuar_historia:
				btn_continuar_historia.pressed.emit()
		return
	
	# PAINEL CONTROLES
	if painel_controles.visible:
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
			btn_voltar_controles.pressed.emit()
		return
	
	# NAVEGAÇÃO DO MENU
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
	# Se o painel de história existe, mostrar história primeiro
	if painel_historia and btn_continuar_historia:
		painel_historia.show()
		container_botoes.hide()
		btn_continuar_historia.grab_focus()
	else:
		# Se não existe, iniciar jogo direto
		_iniciar_jogo()

func _iniciar_jogo():
	"""Inicia o jogo após a história (ou direto se não tiver história)"""
	Game.iniciar_gameplay()
	toggle_ui_jogo(true)
	get_tree().paused = false
	queue_free()

func _on_continuar_historia_pressed():
	# Depois da história, iniciar o jogo
	_iniciar_jogo()

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
