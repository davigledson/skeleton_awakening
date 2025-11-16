# carta_drop.gd
extends Node3D

@onready var sprite = $Sprite3D
@onready var area = $Area3D
@onready var som_pegar = $som_pegar

var tempo_flutuacao: float = 0.0
var posicao_inicial: Vector3
var esta_coletada: bool = false

# Configuracoes de spawn
var velocidade_flutuacao: float = 2.0
var altura_flutuacao: float = 0.3
var velocidade_rotacao: float = 2.0

func _ready():
	add_to_group("cartas")
	
	# IMPORTANTE: Garantir altura minima
	if global_position.y < 0.5:
		global_position.y = 1.5
	
	posicao_inicial = global_position
	
	if area:
		area.body_entered.connect(_on_body_entered)
	
	# Animacao de spawn (cresce)
	if sprite:
		sprite.scale = Vector3.ZERO
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _process(delta: float):
	if esta_coletada:
		return
	
	# Flutuacao (sobe e desce)
	tempo_flutuacao += delta * velocidade_flutuacao
	var offset_y = sin(tempo_flutuacao) * altura_flutuacao
	global_position.y = posicao_inicial.y + offset_y
	
	# Rotacao da esquerda para direita (em torno do eixo Y global)
	if sprite:
		# Rotacionar o sprite inteiro no eixo Y (esquerda -> direita)
		sprite.rotation.y += delta * velocidade_rotacao

func _on_body_entered(body: Node3D):
	if esta_coletada:
		return
	
	if body.is_in_group("player"):
		coletar_carta(body)

func coletar_carta(player: Node3D):
	esta_coletada = true
	
	print("Carta coletada!")
	
	# Som
	if som_pegar:
		som_pegar.play()
	
	# Animacao de coleta (voar ate o jogador)
	if sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "scale", Vector3.ZERO, 0.3)
		tween.tween_property(self, "global_position", player.global_position + Vector3(0, 1.5, 0), 0.3)
		
		await tween.finished
	
	# Adicionar carta ao deck do jogador
	adicionar_carta_ao_deck(player)
	
	queue_free()

func adicionar_carta_ao_deck(player: Node3D):
	"""Adiciona a carta ao deck do jogador"""
	# TODO: Implementar logica de adicionar carta ao deck
	print("  Carta adicionada ao deck!")

# ===== FUNCAO ESTATICA PARA SPAWNAR CARTA =====
static func spawnar_carta_na_frente_do_player(cena_carta: PackedScene, player: Node3D) -> Node3D:
	"""Spawna uma carta na frente do jogador"""
	var carta = cena_carta.instantiate()
	
	# Calcular posicao na frente do jogador
	var direcao_frente = -player.transform.basis.z
	direcao_frente.y = 0
	direcao_frente = direcao_frente.normalized()
	
	var pos = player.global_position
	pos += direcao_frente * 3.0  # 3 metros na frente
	pos.y = player.global_position.y + 1.0  # 1 metro de altura
	
	# Adicionar ao mundo
	player.get_tree().current_scene.add_child(carta)
	carta.global_position = pos
	
	print("Carta spawnada na frente do jogador em: ", pos)
	
	return carta
