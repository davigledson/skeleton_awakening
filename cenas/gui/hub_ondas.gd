# hud_ondas.gd
extends CanvasLayer

@onready var label_onda = $MarginContainer/VBoxContainer/LabelOnda
@onready var label_inimigos = $MarginContainer/VBoxContainer/LabelInimigos
@onready var label_inimigos_vivos = $MarginContainer/VBoxContainer/LabelInimigosVivos

var spawner: Node3D = null
var total_inimigos_onda: int = 0

func _ready():
	# Buscar o spawner de ondas
	await get_tree().process_frame
	buscar_spawner()
	
	# Verificar se os labels existem
	if not label_onda:
		print("[ERRO] LabelOnda não encontrado!")
	if not label_inimigos:
		print("[ERRO] LabelInimigos não encontrado!")
	if not label_inimigos_vivos:
		print("[ERRO] LabelInimigosVivos não encontrado!")
	else:
		print("[OK] LabelInimigosVivos encontrado!")

func buscar_spawner():
	"""Busca o spawner_ondas na cena"""
	var spawners = get_tree().get_nodes_in_group("spawner_ondas")
	
	if spawners.size() > 0:
		spawner = spawners[0]
		print("HUD conectado ao spawner: ", spawner.name)
	else:
		print("[AVISO] Spawner não encontrado! Adicione ao grupo 'spawner_ondas'")

func _process(_delta):
	if not spawner:
		return
	
	atualizar_interface()

func atualizar_interface():
	"""Atualiza os textos da interface no formato 1/10"""
	
	# Atualizar label de onda
	if spawner.has_method("obter_onda_atual"):
		var onda_atual = spawner.obter_onda_atual()
		var total_ondas = spawner.obter_total_ondas()
		label_onda.text = "ONDAS: " + str(onda_atual) + "/" + str(total_ondas)
	
	# Contar inimigos vivos no mapa
	var inimigos_vivos = get_tree().get_nodes_in_group("inimigos").size()
	var inimigos_aguardando = 0
	
	if spawner.has_method("obter_inimigos_restantes"):
		inimigos_aguardando = spawner.obter_inimigos_restantes()
	
	# Total da onda = vivos no mapa + aguardando spawn
	var total_onda_atual = inimigos_vivos + inimigos_aguardando
	
	# Quando nova onda inicia, salvar o total
	if total_onda_atual > total_inimigos_onda:
		total_inimigos_onda = total_onda_atual
	
	# Se não tem total salvo ainda (primeira onda)
	if total_inimigos_onda == 0:
		total_inimigos_onda = total_onda_atual
	
	# Calcular quantos foram eliminados
	var eliminados = total_inimigos_onda - total_onda_atual
	
	# Label 1: Progresso da onda (X/Y inimigos)
	label_inimigos.text = str(eliminados) + "/" + str(total_inimigos_onda) + " INIMIGOS"
	
	# Label 2: Inimigos vivos no mapa AGORA
	if label_inimigos_vivos:
		label_inimigos_vivos.text = "INIMIGOS VIVOS: " + str(inimigos_vivos)
	
	# Quando onda termina (todos mortos e nenhum aguardando)
	if inimigos_vivos == 0 and inimigos_aguardando == 0 and total_inimigos_onda > 0:
		# Resetar para próxima onda
		total_inimigos_onda = 0
	
	# Verificar se completou todas as ondas
	if spawner.has_method("esta_completo") and spawner.esta_completo():
		label_onda.text = "✅ VITÓRIA!"
		label_inimigos.text = "Todas as ondas completas!"
		if label_inimigos_vivos:
			label_inimigos_vivos.text = ""
