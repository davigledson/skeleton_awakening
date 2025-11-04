# personagem_principal.gd
extends CharacterBody3D

@onready var sprite = $AnimatedSprite3D
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

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
	camera_initial_position = camera.position
	update_camera_zoom()

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
	
	# Calcular direção do inimigo
	var direction_to_enemy = inimigo.global_position - global_position
	
	# Escolher animação baseada na direção
	if direction_to_enemy.x < 0:
		# Inimigo à esquerda
		sprite.flip_h = true
		sprite.play("atacando_para_esquerda")  # ou "atacando" se for a mesma
	else:
		# Inimigo à direita
		sprite.flip_h = false
		sprite.play("atacando_para_direita")  # ou "atacando" se for a mesma
	
	# Dar dano no inimigo
	if inimigo.has_method("take_damage"):
		inimigo.take_damage(10)
	
	# Aguardar animação terminar
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	sprite.play("parado")
