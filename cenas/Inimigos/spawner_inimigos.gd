# spawner_inimigos.gd
# Sistema de spawn de inimigos
extends Node3D

# ===== CONFIGURAÇÕES EXPORTADAS =====
@export_group("Spawn Básico")
@export var ativar_spawn: bool = true  # Ativar/desativar spawn
@export var intervalo_spawn: float = 5.0  # Tempo entre spawns (segundos)
@export var max_inimigos_vivos: int = 10  # Máximo de inimigos ao mesmo tempo

@export_group("Inimigos")
@export var cenas_inimigos: Array[PackedScene] = []  # Arraste as cenas aqui!
@export var spawn_aleatorio: bool = true  # Spawna tipo aleatório?

@export_group("Área de Spawn")
@export var raio_spawn: float = 15.0  # Distância do spawner
@export var altura_spawn: float = 10.0  # Altura Y do spawn

@export_group("Limite de Spawns")
@export var tem_limite: bool = false  # Limitar total de spawns?
@export var total_spawns: int = 50  # Total máximo (se tem_limite = true)

# ===== VARIÁVEIS INTERNAS =====
var timer_spawn: float = 0.0
var contador_spawns: int = 0
var inimigos_spawnados: Array = []

func _ready():
	print("🎯 Spawner inicializado")
	
	if cenas_inimigos.size() == 0:
		print("  ⚠️ AVISO: Nenhuma cena de inimigo configurada!")
		ativar_spawn = false
	
	if ativar_spawn:
		print("  ✅ Spawn ativado")
		print("  Intervalo: ", intervalo_spawn, "s")
		print("  Máximo vivos: ", max_inimigos_vivos)
		print("  Tipos de inimigos: ", cenas_inimigos.size())

func _process(delta: float) -> void:
	if not ativar_spawn:
		return
	
	# Limpar referências de inimigos mortos
	limpar_inimigos_mortos()
	
	# Atualizar timer
	timer_spawn -= delta
	
	# Hora de spawnar?
	if timer_spawn <= 0.0:
		tentar_spawnar()
		timer_spawn = intervalo_spawn

func limpar_inimigos_mortos():
	"""Remove referências de inimigos que já morreram"""
	var vivos = []
	for inimigo in inimigos_spawnados:
		if is_instance_valid(inimigo):
			vivos.append(inimigo)
	inimigos_spawnados = vivos

func tentar_spawnar():
	"""Tenta spawnar um inimigo"""
	
	# Verificar limite de inimigos vivos
	if inimigos_spawnados.size() >= max_inimigos_vivos:
		return
	
	# Verificar limite total de spawns
	if tem_limite and contador_spawns >= total_spawns:
		print("🎯 Limite de spawns atingido (", total_spawns, ")")
		ativar_spawn = false
		return
	
	# Spawnar!
	spawnar_inimigo()

func spawnar_inimigo():
	"""Spawna um inimigo em posição aleatória"""
	
	# Escolher cena do inimigo
	var cena_inimigo: PackedScene
	
	if spawn_aleatorio:
		cena_inimigo = cenas_inimigos[randi() % cenas_inimigos.size()]
	else:
		# Spawnar em ordem circular
		cena_inimigo = cenas_inimigos[contador_spawns % cenas_inimigos.size()]
	
	# Instanciar
	var inimigo = cena_inimigo.instantiate()
	
	# Adicionar ao mundo
	get_tree().current_scene.add_child(inimigo)
	
	# Posicionar
	var pos = calcular_posicao_spawn()
	inimigo.global_position = pos
	
	# Registrar
	inimigos_spawnados.append(inimigo)
	contador_spawns += 1
	
	print("🎯 Inimigo spawnado: ", inimigo.name, " (", inimigos_spawnados.size(), "/", max_inimigos_vivos, ")")

func calcular_posicao_spawn() -> Vector3:
	"""Calcula posição aleatória ao redor do spawner"""
	
	# Ângulo aleatório
	var angulo = randf() * TAU  # 0 a 2π
	
	# Distância aleatória (do centro até o raio)
	var distancia = randf() * raio_spawn
	
	# Calcular posição X e Z
	var offset_x = cos(angulo) * distancia
	var offset_z = sin(angulo) * distancia
	
	# Posição final
	var pos = global_position
	pos.x += offset_x
	pos.z += offset_z
	pos.y = altura_spawn
	
	return pos

# ===== FUNÇÕES PÚBLICAS (para chamar de fora) =====

func pausar_spawn():
	"""Para o spawn temporariamente"""
	ativar_spawn = false
	print("🎯 Spawn pausado")

func retomar_spawn():
	"""Retoma o spawn"""
	ativar_spawn = true
	print("🎯 Spawn retomado")

func spawnar_agora():
	"""Força spawn imediato (ignora timer)"""
	spawnar_inimigo()

func limpar_todos_inimigos():
	"""Remove todos os inimigos spawnados"""
	for inimigo in inimigos_spawnados:
		if is_instance_valid(inimigo):
			inimigo.queue_free()
	
	inimigos_spawnados.clear()
	print("🎯 Todos os inimigos removidos")

func resetar_spawner():
	"""Reseta o spawner para o estado inicial"""
	limpar_todos_inimigos()
	contador_spawns = 0
	timer_spawn = 0.0
	print("🎯 Spawner resetado")
