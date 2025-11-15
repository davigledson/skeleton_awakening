# efeito_magia_negra.gd - Curva para cada inimigo
extends Node3D

@onready var sprite = $AnimatedSprite3D
@onready var som = $AudioStreamPlayer3D

# Configurações
var velocidade = 15.0
var dano = 15
var max_inimigos = 5

# Estado
var configurado = false
var alvo_atual = null
var inimigos_atingidos = []

# Curva
var pos_inicial = Vector3.ZERO
var ponto_meio = Vector3.ZERO
var tempo = 0.0
var duracao = 0.6

func _ready():
	print("🌑 Magia Negra _ready()")
	
	if sprite:
		sprite.visible = true
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("ataque"):
			sprite.play("ataque")

func configurar(personagem: Node3D, valor_dano: int):
	configurado = true
	dano = valor_dano
	
	if som:
		som.play()
	
	print("🌑 Orbe configurado - Dano: ", dano)
	
	# Buscar primeiro alvo
	buscar_proximo_alvo()

func buscar_proximo_alvo():
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var mais_proximo = null
	var menor_dist = 999999.0
	
	for inimigo in inimigos:
		if not is_instance_valid(inimigo):
			continue
		
		# Pular inimigos já atingidos
		if inimigos_atingidos.has(inimigo):
			continue
		
		var dist = global_position.distance_to(inimigo.global_position)
		if dist < menor_dist:
			menor_dist = dist
			mais_proximo = inimigo
	
	if mais_proximo:
		iniciar_curva(mais_proximo)
	else:
		print("🌑 Sem mais alvos!")
		explodir()

func iniciar_curva(novo_alvo: Node3D):
	alvo_atual = novo_alvo
	pos_inicial = global_position
	tempo = 0.0
	
	# Calcular ponto intermediário (curva lateral)
	var pos_alvo = alvo_atual.global_position + Vector3(0, 0.3, 0)
	var meio = (pos_inicial + pos_alvo) / 2.0
	
	var direcao_lateral = Vector3(-(pos_alvo.z - pos_inicial.z), 0, (pos_alvo.x - pos_inicial.x)).normalized()
	var dist = pos_inicial.distance_to(pos_alvo)
	var offset = dist * 0.3
	var lado = 1 if randf() > 0.5 else -1
	
	ponto_meio = meio + (direcao_lateral * offset * lado)
	ponto_meio.y = meio.y
	
	print("🌑 Indo para: ", alvo_atual.name)

func _process(delta):
	if not configurado:
		return
	
	# Billboard
	var camera = get_viewport().get_camera_3d()
	if camera and sprite:
		sprite.look_at(camera.global_position, Vector3.UP)
	
	# Se não tem alvo, parar
	if not alvo_atual:
		return
	
	# Verificar se alvo ainda existe
	if not is_instance_valid(alvo_atual):
		buscar_proximo_alvo()
		return
	
	# Mover em curva
	tempo += delta
	var progresso = min(tempo / duracao, 1.0)
	
	# Curva de Bézier
	var pos_alvo = alvo_atual.global_position + Vector3(0, 0.3, 0)
	var q0 = pos_inicial.lerp(ponto_meio, progresso)
	var q1 = ponto_meio.lerp(pos_alvo, progresso)
	global_position = q0.lerp(q1, progresso)
	
	# Chegou no alvo?
	if progresso >= 1.0:
		atingir_alvo_atual()

func atingir_alvo_atual():
	if not alvo_atual:
		return
	
	print("🌑 Atingiu: ", alvo_atual.name, " (", inimigos_atingidos.size() + 1, "/", max_inimigos, ")")
	
	inimigos_atingidos.append(alvo_atual)
	
	# Dano
	if alvo_atual.has_method("take_damage"):
		alvo_atual.take_damage(dano)
	
	# Atordoamento
	if alvo_atual.has_method("aplicar_atordoamento"):
		alvo_atual.aplicar_atordoamento(2.0)
	
	alvo_atual = null
	
	# Verificar limite
	if inimigos_atingidos.size() >= max_inimigos:
		print("🌑 Atingiu ", max_inimigos, " inimigos!")
		explodir()
	else:
		# Buscar próximo
		buscar_proximo_alvo()

func explodir():
	print("🌑 Explodindo!")
	set_process(false)
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("explode"):
		sprite.play("explode")
	
	await get_tree().create_timer(0.8).timeout
	queue_free()
