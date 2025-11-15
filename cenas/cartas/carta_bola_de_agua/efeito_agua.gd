# efeito_agua.gd
extends Node3D

@onready var sprite = $AnimatedSprite3D
@onready var som = $AudioStreamPlayer3D

var velocidade = 12.0
var alvo = null
var dano = 0
var atingiu = false
var configurado = false

# Variáveis para trajetória curva
var posicao_inicial = Vector3.ZERO
var ponto_intermediario = Vector3.ZERO
var tempo_viagem = 0.0
var duracao_viagem = 1.5

func _ready():
	print("Bola _ready() chamado")
	
	# NÃO tocar som aqui - só depois de configurar!
	
	# Começar animação
	if sprite and sprite.sprite_frames:
		sprite.play("ataque")
		print("  Animacao 'ataque' iniciada")
	else:
		print("  [AVISO] Sprite ou sprite_frames nao encontrado!")

func configurar(inimigo_alvo: Node3D, valor_dano: int):
	if configurado:
		print("  [AVISO] Bola ja estava configurada!")
		return
	
	configurado = true
	alvo = inimigo_alvo
	dano = valor_dano
	
	# TOCAR SOM AGORA (depois de configurar)
	if som:
		som.play()
		print("  🔊 Som da bola de água!")
	
	# Capturar posição inicial
	posicao_inicial = global_position
	print("  Configurada - Posicao inicial: ", posicao_inicial)
	print("  Vai perseguir: ", alvo.name if alvo else "NULL")
	
	if alvo:
		print("  Posicao do alvo: ", alvo.global_position)
		calcular_ponto_intermediario()
	
	print("  Dano: ", dano)

func calcular_ponto_intermediario():
	"""Calcula o ponto intermediário para criar a curva LATERAL de 90 graus"""
	if not alvo:
		return
	
	var vetor_ate_alvo = alvo.global_position - posicao_inicial
	var distancia = posicao_inicial.distance_to(alvo.global_position)
	
	var meio = (posicao_inicial + alvo.global_position) / 2.0
	
	# Criar offset LATERAL
	var direcao_lateral = Vector3(-vetor_ate_alvo.z, 0, vetor_ate_alvo.x).normalized()
	
	var offset_curva = distancia * 0.4
	var lado = 1 if randf() > 0.5 else -1
	
	ponto_intermediario = meio + (direcao_lateral * offset_curva * lado)
	ponto_intermediario.y = meio.y
	
	print("  Ponto intermediario LATERAL: ", ponto_intermediario)

func _process(delta):
	if atingiu or not configurado:
		return
	
	# Billboard
	var camera = get_viewport().get_camera_3d()
	if camera and sprite:
		sprite.look_at(camera.global_position, Vector3.UP)
	
	# Verificar se alvo ainda existe
	if not alvo or not is_instance_valid(alvo):
		print("Alvo perdido, destruindo bola")
		queue_free()
		return
	
	# Atualizar posição do alvo
	if tempo_viagem == 0.0:
		calcular_ponto_intermediario()
	
	tempo_viagem += delta
	var progresso = min(tempo_viagem / duracao_viagem, 1.0)
	
	# Curva de Bézier
	var posicao_alvo_atual = alvo.global_position + Vector3(0, 0.5, 0)
	var nova_posicao = bezier_quadratico(posicao_inicial, ponto_intermediario, posicao_alvo_atual, progresso)
	
	global_position = nova_posicao
	
	# Verificar se chegou
	if progresso >= 1.0:
		impacto()

func bezier_quadratico(p0: Vector3, p1: Vector3, p2: Vector3, t: float) -> Vector3:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)

func impacto():
	if atingiu:
		return
	
	atingiu = true
	print("💥 IMPACTO!")
	
	# Parar de processar movimento
	set_process(false)
	
	# Animação de impacto
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("impacto"):
			sprite.play("impacto")
			print("  Tocando animacao 'impacto'")
	
	# === NOVO: APLICAR EFEITO DE ATORDOAMENTO ===
	if alvo and is_instance_valid(alvo):
		# Causar dano
		if alvo.has_method("take_damage"):
			alvo.take_damage(dano)
			print("  💧 Causou ", dano, " de dano!")
		
		# Aplicar atordoamento (zonzo)
		if alvo.has_method("aplicar_atordoamento"):
			alvo.aplicar_atordoamento(2.5)  # 2.5 segundos zonzo
			print("  😵 Inimigo ficou ZONZO!")
		
		# OPCIONAL: Empurrar para trás
		# var direcao_empurrao = (alvo.global_position - posicao_inicial).normalized()
		# if alvo.has_method("empurrar"):
		#     alvo.empurrar(direcao_empurrao, 2.0)
		#     print("  👊 Inimigo empurrado!")
	
	# Destruir após animação
	await get_tree().create_timer(0.8).timeout
	print("  Destruindo bola")
	queue_free()
