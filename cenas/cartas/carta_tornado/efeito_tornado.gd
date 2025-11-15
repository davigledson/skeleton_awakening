# efeito_tornado.gd
extends Node3D

@onready var sprite = $AnimatedSprite3D
@onready var som = $AudioStreamPlayer3D

# Configurações do tornado (AJUSTÁVEIS)
var dano = 10
var velocidade = 3.0  # Velocidade para frente
var amplitude_zigzag = 2.0  # Largura do zig-zag (lateral)
var frequencia_zigzag = 1.0  # Quantos zig-zags por segundo
var duracao_total = 4.0  # Quanto tempo o tornado existe
var alcance_maximo = 15.0  # Distância máxima que percorre
var raio_dano = 2.0  # Raio de detecção de inimigos
var configurado = false
var personagem = null



# Estado
var tempo_vida = 0.0
var posicao_inicial = Vector3.ZERO
var direcao_frente = Vector3.ZERO
var esta_formando = true
var esta_encerrando = false

# Detecção de colisão
var inimigos_atingidos = []

func _ready():
	print("🌪️ Tornado _ready() chamado")
	
	# Garantir que o sprite está visível
	if sprite:
		sprite.visible = true
	
	# Começar animação de formação
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("formacao"):
			sprite.play("formacao")
			print("  Animação 'formacao' iniciada")
		else:
			print("  [AVISO] Animação 'formacao' não encontrada! Usando 'ataque'")
			sprite.play("ataque")
	else:
		print("  [AVISO] Sprite ou sprite_frames não encontrado!")

func configurar(personagem_ref: Node3D, valor_dano: int):
	if configurado:
		print("  [AVISO] Tornado já estava configurado!")
		return
	
	configurado = true
	personagem = personagem_ref
	dano = valor_dano
	
	# Tocar som
	if som:
		som.play()
		print("  🔊 Som do tornado!")
	
	# Capturar posição e direção inicial
	posicao_inicial = global_position
	
	# Direção para frente do personagem
	direcao_frente = -personagem.transform.basis.z
	direcao_frente.y = 0
	direcao_frente = direcao_frente.normalized()
	
	print("  Configurado - Posição inicial: ", posicao_inicial)
	print("  Direção: ", direcao_frente)
	print("  Dano: ", dano)
	
	# Aguardar animação de formação terminar
	await get_tree().create_timer(0.5).timeout
	esta_formando = false
	
	# Trocar para animação principal
	if sprite:
		sprite.play("ataque")
		print("  Animação 'ataque' iniciada")

func _process(delta):
	if not configurado or esta_formando:
		return
	
	# Billboard (sprite olha para câmera)
	var camera = get_viewport().get_camera_3d()
	if camera and sprite:
		sprite.look_at(camera.global_position, Vector3.UP)
	
	# Verificar se acabou o tempo de vida
	tempo_vida += delta
	
	if tempo_vida >= duracao_total and not esta_encerrando:
		iniciar_encerramento()
		return
	
	if esta_encerrando:
		return
	
	# === MOVIMENTO ZIG-ZAG ===
	mover_zigzag(delta)
	
	# === DETECTAR E CAUSAR DANO EM INIMIGOS ===
	detectar_inimigos()

func mover_zigzag(delta: float):
	"""Move o tornado em zig-zag para frente"""
	
	# Calcular movimento para frente
	var movimento_frente = direcao_frente * velocidade * delta
	
	# Calcular movimento lateral (zig-zag usando seno)
	var direcao_lateral = Vector3(-direcao_frente.z, 0, direcao_frente.x).normalized()
	var offset_zigzag = sin(tempo_vida * frequencia_zigzag * TAU) * amplitude_zigzag
	var movimento_lateral = direcao_lateral * offset_zigzag * delta * 2.0
	
	# Aplicar movimento total
	global_position += movimento_frente + movimento_lateral
	
	# Verificar se alcançou distância máxima
	var distancia_percorrida = posicao_inicial.distance_to(global_position)
	if distancia_percorrida >= alcance_maximo:
		iniciar_encerramento()

func detectar_inimigos():
	"""Detecta e causa dano em inimigos próximos"""
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	
	for inimigo in inimigos:
		if not is_instance_valid(inimigo):
			continue
		
		# Verificar se já atingiu este inimigo
		if inimigos_atingidos.has(inimigo):
			continue
		
		# Verificar distância
		var distancia = global_position.distance_to(inimigo.global_position)
		
		if distancia <= raio_dano:
			atingir_inimigo(inimigo)

func atingir_inimigo(inimigo: Node3D):
	"""Causa dano e efeito no inimigo"""
	print("🌪️ Tornado atingiu: ", inimigo.name)
	
	# Marcar como atingido (para não bater de novo)
	inimigos_atingidos.append(inimigo)
	
	# Causar dano
	if inimigo.has_method("take_damage"):
		inimigo.take_damage(dano)
		print("  💨 Causou ", dano, " de dano!")
	
	# Empurrar para cima e para o lado (efeito de tornado)
	if inimigo.has_method("empurrar"):
		var direcao_empurrao = (inimigo.global_position - global_position).normalized()
		direcao_empurrao.y = 1.0  # Empurrar para cima também
		inimigo.empurrar(direcao_empurrao, 4.0)
		print("  🌪️ Inimigo foi arremessado!")
	
	# Aplicar atordoamento leve
	if inimigo.has_method("aplicar_atordoamento"):
		inimigo.aplicar_atordoamento(1.5)

func iniciar_encerramento():
	"""Inicia animação de encerramento do tornado"""
	if esta_encerrando:
		return
	
	esta_encerrando = true
	print("🌪️ Tornado encerrando...")
	
	# Parar de processar movimento
	set_process(false)
	
	# Tocar animação de encerramento
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("encerrando"):
			sprite.play("encerrando")
			print("  Animação 'encerrando' iniciada")
		else:
			print("  [AVISO] Animação 'encerrando' não encontrada!")
	
	# Aguardar animação e destruir
	await get_tree().create_timer(1.0).timeout
	print("  Destruindo tornado")
	queue_free()
