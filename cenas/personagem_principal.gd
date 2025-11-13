# personagem_principal.gd
extends CharacterBody3D

@onready var sprite = $AnimatedSprite3D
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

var health = 100
var max_health = 100
var bonus_dano = 0

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
const ZOOM_SPEED = 0.1
const MIN_ZOOM = 0.3
const MAX_ZOOM = 2.0
const FIRST_PERSON_THRESHOLD = 0.6
const ATTACK_RANGE = 1.0
const ATTACK_COOLDOWN = 1.0

var mouse_captured = false
var current_zoom = 1.0
var camera_initial_position = Vector3.ZERO
var attack_timer = 0.0
var is_attacking = false

func _ready():
	# IMPORTANTE: Adicionar ao grupo "player"
	add_to_group("player")
	
	camera_initial_position = camera.position
	update_camera_zoom()
	
	print("🎮 Personagem pronto e adicionado ao grupo 'player'")

func _input(event):
	# Capturar/liberar mouse com botão esquerdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_captured = false
	
	# Rotacionar PERSONAGEM quando mouse estiver capturado
	if mouse_captured and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	
	# ZOOM com scroll do mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_zoom -= ZOOM_SPEED
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_zoom += ZOOM_SPEED
		
		current_zoom = clamp(current_zoom, MIN_ZOOM, MAX_ZOOM)
		update_camera_zoom()

func update_camera_zoom():
	var direction = camera_initial_position.normalized()
	camera.position = direction * current_zoom
	
	if current_zoom < FIRST_PERSON_THRESHOLD:
		sprite.visible = false
	else:
		sprite.visible = true

func _physics_process(delta: float) -> void:
	# Atualizar cooldown do ataque
	if attack_timer > 0:
		attack_timer -= delta
	
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Verificar inimigos próximos e atacar
	check_and_attack_enemies()
	
	# Movimento (só se não estiver atacando)
	if not is_attacking:
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			sprite.play("andando")
			
			if input_dir.x != 0:
				sprite.flip_h = input_dir.x < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			sprite.play("parado")
	
	move_and_slide()
	
	# Inimigos perseguem
	get_tree().call_group("inimigos", "update_target_location", global_position)

func check_and_attack_enemies():
	# Se ainda está em cooldown, não atacar
	if attack_timer > 0:
		return
	
	# Buscar todos os inimigos
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	
	for inimigo in inimigos:
		var distance = global_position.distance_to(inimigo.global_position)
		
		# Se inimigo está no alcance
		if distance <= ATTACK_RANGE:
			attack_enemy(inimigo)
			return

func attack_enemy(inimigo):
	is_attacking = true
	attack_timer = ATTACK_COOLDOWN
	
	var direction_to_enemy = inimigo.global_position - global_position
	
	if direction_to_enemy.x < 0:
		sprite.flip_h = true
		sprite.play("atacando_para_esquerda")
	else:
		sprite.flip_h = false
		sprite.play("atacando_para_direita")
	
	# Dar dano com bônus da carta!
	var dano_total = 10 + bonus_dano
	if inimigo.has_method("take_damage"):
		inimigo.take_damage(dano_total)
		print("⚔️ Ataque! Dano: ", dano_total, " (Base: 10 + Bônus: ", bonus_dano, ")")
	
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	sprite.play("parado")

func ativar_carta(tipo: int, valor: int):
	print("✅ Personagem recebeu a carta! Tipo: ", tipo, ", Valor: ", valor)

	match tipo:
		0: # Ataque (Bônus de Dano)
			print("⚔️ Buff de dano ativado! Dano extra: +", valor)
			bonus_dano += valor
			
		1: # Cura
			print("❤️ Cura ativada! Vida recuperada: +", valor)
			health += valor
			health = min(health, max_health)
			print("💚 Vida atual: ", health, "/", max_health)
			
		2: # Velocidade
			print("💨 Buff de velocidade ativado! (Implementar lógica)")
			
		3: # Dano em Área
			print("💥 Carta de dano em área recebida! (Efeito visual controlado pela carta)")
			# O efeito visual é spawnado pela própria carta
			# Aqui só registramos que recebemos o comando

func take_damage(dano: int):
	health -= dano
	print("💔 Personagem recebeu ", dano, " de dano! Vida: ", health)
	
	if health <= 0:
		die()

func die():
	print("☠️ Personagem morreu!")
	# Adicionar lógica de morte (game over, respawn, etc)

func dano_em_area_posicao(dano: int, posicao_centro: Vector3):
	"""Causa dano em área em uma posição específica"""
	print("💥 Causando ", dano, " de dano em área na posição: ", posicao_centro)
	
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var inimigos_atingidos = 0
	
	for inimigo in inimigos:
		var distancia = posicao_centro.distance_to(inimigo.global_position)
		if distancia <= 5.0:  # Raio de 5 metros da explosão
			if inimigo.has_method("take_damage"):
				inimigo.take_damage(dano)
				inimigos_atingidos += 1
				print("  💥 Inimigo atingido a ", distancia, "m de distância")
	
	print("💥 Total de ", inimigos_atingidos, " inimigos atingidos!")
