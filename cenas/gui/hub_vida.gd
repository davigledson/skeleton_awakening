# hud_vida.gd
extends CanvasLayer

# Referências aos elementos da UI
@onready var barra_vida = $MarginContainer/VBoxContainer/BarraVida
@onready var label_vida = $MarginContainer/VBoxContainer/BarraVida/LabelVida

var personagem: Node3D = null

func _ready():
	print("HUD de Vida inicializado")
	
	# Buscar personagem
	await get_tree().process_frame
	buscar_personagem()
	
	# Configurar barra
	if barra_vida:
		barra_vida.show_percentage = false  # Não mostrar % automático

func buscar_personagem():
	"""Busca o personagem principal"""
	var players = get_tree().get_nodes_in_group("player")
	
	if players.size() > 0:
		personagem = players[0]
		print("  HUD conectado ao personagem: ", personagem.name)
		atualizar_vida()
	else:
		print("  [AVISO] Personagem não encontrado!")

func _process(_delta):
	if personagem:
		atualizar_vida()

func atualizar_vida():
	"""Atualiza a barra de vida"""
	if not personagem:
		return
	
	# Pegar vida do personagem (verificar se propriedade existe)
	var vida_atual = 100
	var vida_maxima = 100
	
	if "health" in personagem:
		vida_atual = personagem.health
	
	if "max_health" in personagem:
		vida_maxima = personagem.max_health
	
	# Atualizar barra
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual
		
		# Mudar cor baseado na vida
		atualizar_cor_barra(vida_atual, vida_maxima)
	
	# Atualizar texto
	if label_vida:
		label_vida.text = str(vida_atual) + " / " + str(vida_maxima)

func atualizar_cor_barra(vida: int, vida_max: int):
	"""Muda a cor da barra baseado na % de vida"""
	var percentual = float(vida) / float(vida_max)
	
	# Obter o stylebox da barra
	var style = barra_vida.get_theme_stylebox("fill")
	
	if style:
		if percentual > 0.6:
			# Verde (vida alta)
			style.bg_color = Color(0.2, 0.8, 0.2)  # Verde
		elif percentual > 0.3:
			# Amarelo (vida média)
			style.bg_color = Color(0.9, 0.9, 0.2)  # Amarelo
		else:
			# Vermelho (vida baixa)
			style.bg_color = Color(0.9, 0.2, 0.2)  # Vermelho

func atualizar_vida_manual(vida: int, vida_max: int):
	"""Função pública para atualizar vida manualmente"""
	if barra_vida:
		barra_vida.max_value = vida_max
		barra_vida.value = vida
	
	if label_vida:
		label_vida.text = str(vida) + " / " + str(vida_max)
	
	atualizar_cor_barra(vida, vida_max)
