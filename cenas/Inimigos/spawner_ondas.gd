# spawner_ondas.gd - Sistema de Ondas Simplificado
extends Node3D

# ===== ESTRUTURA DE ONDA =====
class Onda:
	var inimigos: Array[PackedScene] = []
	var quantidades: Array[int] = []
	var intervalo: float
	var descricao: String

# ===== CONFIGURACOES =====
@export_group("Drop de Carta")
@export var cena_carta_drop: PackedScene

@export_group("Controle")
@export var iniciar_automatico: bool = true
@export var tempo_entre_ondas: float = 10.0

@export_group("Spawn ao Redor do Personagem")
@export var raio_spawn_min: float = 1.0
@export var raio_spawn_max: float = 3.0
@export var altura_spawn: float = 0.0

@export_group("ONDA 1")
@export var onda1_inimigo_A: PackedScene
@export var onda1_quantidade_A: int = 5
@export var onda1_inimigo_B: PackedScene
@export var onda1_quantidade_B: int = 0
@export var onda1_inimigo_C: PackedScene
@export var onda1_quantidade_C: int = 0
@export var onda1_intervalo: float = 2.0

@export_group("ONDA 2")
@export var onda2_inimigo_A: PackedScene
@export var onda2_quantidade_A: int = 0
@export var onda2_inimigo_B: PackedScene
@export var onda2_quantidade_B: int = 0
@export var onda2_inimigo_C: PackedScene
@export var onda2_quantidade_C: int = 0
@export var onda2_intervalo: float = 1.5

@export_group("ONDA 3")
@export var onda3_inimigo_A: PackedScene
@export var onda3_quantidade_A: int = 0
@export var onda3_inimigo_B: PackedScene
@export var onda3_quantidade_B: int = 0
@export var onda3_inimigo_C: PackedScene
@export var onda3_quantidade_C: int = 0
@export var onda3_intervalo: float = 1.0

@export_group("ONDA 4")
@export var onda4_inimigo_A: PackedScene
@export var onda4_quantidade_A: int = 0
@export var onda4_inimigo_B: PackedScene
@export var onda4_quantidade_B: int = 0
@export var onda4_inimigo_C: PackedScene
@export var onda4_quantidade_C: int = 0
@export var onda4_intervalo: float = 0.8

@export_group("ONDA 5")
@export var onda5_inimigo_A: PackedScene
@export var onda5_quantidade_A: int = 0
@export var onda5_inimigo_B: PackedScene
@export var onda5_quantidade_B: int = 0
@export var onda5_inimigo_C: PackedScene
@export var onda5_quantidade_C: int = 0
@export var onda5_intervalo: float = 0.5

# ===== VARIAVEIS =====
var ondas: Array[Onda] = []
var onda_atual: int = 0
var inimigos_para_spawnar: Array = []
var timer: float = 0.0
var estado: String = "aguardando"
var personagem: Node3D = null
var total_inimigos_onda_atual: int = 0

func _ready():
	print("Sistema de Ondas inicializado")
	add_to_group("spawner_ondas")
	
	await get_tree().process_frame
	buscar_personagem()
	
	construir_ondas()
	
	if iniciar_automatico and ondas.size() > 0:
		iniciar_ondas()

func buscar_personagem():
	"""Busca o personagem principal"""
	var players = get_tree().get_nodes_in_group("player")
	
	if players.size() > 0:
		personagem = players[0]
		print("  Personagem encontrado: ", personagem.name)
	else:
		print("  [AVISO] Personagem nao encontrado! Usando posicao do spawner")
		personagem = null

func construir_ondas():
	"""Constroi as ondas baseado nas configuracoes"""
	ondas.clear()
	
	adicionar_onda(
		[onda1_inimigo_A, onda1_inimigo_B, onda1_inimigo_C],
		[onda1_quantidade_A, onda1_quantidade_B, onda1_quantidade_C],
		onda1_intervalo, "Onda 1"
	)
	
	adicionar_onda(
		[onda2_inimigo_A, onda2_inimigo_B, onda2_inimigo_C],
		[onda2_quantidade_A, onda2_quantidade_B, onda2_quantidade_C],
		onda2_intervalo, "Onda 2"
	)
	
	adicionar_onda(
		[onda3_inimigo_A, onda3_inimigo_B, onda3_inimigo_C],
		[onda3_quantidade_A, onda3_quantidade_B, onda3_quantidade_C],
		onda3_intervalo, "Onda 3"
	)
	
	adicionar_onda(
		[onda4_inimigo_A, onda4_inimigo_B, onda4_inimigo_C],
		[onda4_quantidade_A, onda4_quantidade_B, onda4_quantidade_C],
		onda4_intervalo, "Onda 4"
	)
	
	adicionar_onda(
		[onda5_inimigo_A, onda5_inimigo_B, onda5_inimigo_C],
		[onda5_quantidade_A, onda5_quantidade_B, onda5_quantidade_C],
		onda5_intervalo, "Onda 5"
	)
	
	print("  ", ondas.size(), " ondas configuradas")

func adicionar_onda(cenas: Array, quantidades: Array, intervalo: float, nome: String):
	"""Adiciona uma onda se tiver pelo menos um inimigo"""
	var onda = Onda.new()
	var total_inimigos = 0
	var tipos_texto = []
	
	for i in range(cenas.size()):
		if cenas[i] != null and quantidades[i] > 0:
			onda.inimigos.append(cenas[i])
			onda.quantidades.append(quantidades[i])
			total_inimigos += quantidades[i]
			
			var nome_inimigo = cenas[i].resource_path.get_file().get_basename()
			tipos_texto.append(str(quantidades[i]) + " " + nome_inimigo)
	
	if total_inimigos > 0:
		onda.intervalo = intervalo
		onda.descricao = nome + ": " + " + ".join(tipos_texto) + " = " + str(total_inimigos) + " total"
		ondas.append(onda)
		print("  [", nome, "] ", total_inimigos, " inimigos configurados")

func iniciar_ondas():
	"""Inicia o sistema de ondas"""
	if ondas.size() == 0:
		print("  [AVISO] Nenhuma onda configurada!")
		return
	
	onda_atual = 0
	estado = "spawnando"
	iniciar_onda_atual()

func iniciar_onda_atual():
	"""Inicia a onda atual"""
	if onda_atual >= ondas.size():
		print("TODAS AS ONDAS COMPLETAS!")
		estado = "completo"
		return
	
	var onda = ondas[onda_atual]
	timer = 0.0
	
	inimigos_para_spawnar.clear()
	
	for i in range(onda.inimigos.size()):
		for j in range(onda.quantidades[i]):
			inimigos_para_spawnar.append(onda.inimigos[i])
	
	inimigos_para_spawnar.shuffle()
	total_inimigos_onda_atual = inimigos_para_spawnar.size()
	
	print(onda.descricao, " INICIANDO!")
	print("  Total: ", total_inimigos_onda_atual, " inimigos")
	print("  Intervalo: ", onda.intervalo, "s")

func _process(delta: float) -> void:
	if estado == "spawnando":
		processar_spawn(delta)
	elif estado == "aguardando_morte":
		verificar_inimigos_vivos()
	elif estado == "descansando":
		processar_descanso(delta)

func processar_spawn(delta: float):
	"""Processa spawn da onda atual"""
	if inimigos_para_spawnar.size() == 0:
		return
	
	var onda = ondas[onda_atual]
	timer -= delta
	
	if timer <= 0.0:
		var cena = inimigos_para_spawnar.pop_front()
		spawnar_inimigo(cena)
		timer = onda.intervalo
		
		# Terminou de spawnar todos?
		if inimigos_para_spawnar.size() == 0:
			print("Todos os inimigos spawnados! Aguardando morte...")
			estado = "aguardando_morte"

func verificar_inimigos_vivos():
	"""Verifica se ainda tem inimigos vivos"""
	var inimigos_vivos = get_tree().get_nodes_in_group("inimigos")
	
	if inimigos_vivos.size() == 0:
		finalizar_onda()

func finalizar_onda():
	"""Finaliza a onda e dropa carta"""
	print("Onda ", onda_atual + 1, " completa!")
	
	# Dropar carta de recompensa
	dropar_carta()
	
	onda_atual += 1
	
	if onda_atual < ondas.size():
		estado = "descansando"
		timer = tempo_entre_ondas
		print("  Descanso de ", tempo_entre_ondas, "s...")
	else:
		estado = "completo"
		print("TODAS AS ONDAS COMPLETAS!")

func processar_descanso(delta: float):
	"""Processa tempo de descanso entre ondas"""
	timer -= delta
	
	if timer <= 0.0:
		estado = "spawnando"
		iniciar_onda_atual()

func spawnar_inimigo(cena: PackedScene):
	"""Spawna um inimigo ao redor do personagem"""
	var inimigo = cena.instantiate()
	
	var pos: Vector3
	
	if personagem:
		var angulo = randf() * TAU
		var distancia = randf_range(raio_spawn_min, raio_spawn_max)
		
		pos = personagem.global_position
		pos.x += cos(angulo) * distancia
		pos.z += sin(angulo) * distancia
		pos.y = altura_spawn
	else:
		var angulo = randf() * TAU
		var distancia = randf_range(raio_spawn_min, raio_spawn_max)
		
		pos = global_position
		pos.x += cos(angulo) * distancia
		pos.z += sin(angulo) * distancia
		pos.y = altura_spawn
	
	inimigo.position = pos
	get_tree().current_scene.call_deferred("add_child", inimigo)

func dropar_carta():
	"""Dropa carta na frente do personagem usando funcao estatica"""
	if not cena_carta_drop:
		print("  [AVISO] Nenhuma carta configurada!")
		return
	
	if not personagem:
		print("  [AVISO] Personagem nao encontrado!")
		return
	
	# Usar funcao estatica do carta_drop.gd
	var CartaDrop = preload("res://cenas/cartas/drop_carta/carta_drop.gd")
	CartaDrop.spawnar_carta_na_frente_do_player(cena_carta_drop, personagem)
	
	print("Carta dropada na frente do jogador!")

# ===== FUNCOES PUBLICAS =====

func pausar():
	set_process(false)
	print("Ondas pausadas")

func retomar():
	set_process(true)
	print("Ondas retomadas")

func pular_onda():
	inimigos_para_spawnar.clear()
	onda_atual += 1
	if onda_atual < ondas.size():
		estado = "spawnando"
		iniciar_onda_atual()

func resetar():
	onda_atual = 0
	estado = "aguardando"
	inimigos_para_spawnar.clear()
	construir_ondas()
	print("Sistema resetado")

func obter_onda_atual() -> int:
	return onda_atual + 1

func obter_total_ondas() -> int:
	return ondas.size()

func esta_completo() -> bool:
	return estado == "completo"

func obter_inimigos_restantes() -> int:
	return inimigos_para_spawnar.size()

func obter_inimigos_vivos() -> int:
	return get_tree().get_nodes_in_group("inimigos").size()

func obter_total_inimigos_onda() -> int:
	"""Retorna o total de inimigos da onda atual"""
	return total_inimigos_onda_atual
