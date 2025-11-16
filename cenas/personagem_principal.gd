# personagem_principal.gd
extends CharacterBody3D

@onready var sprite = $AnimatedSprite3D
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var posicao_magia = $posicao_magia
@onready var som_dano = $sons/som_dano

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

var is_invulnerable = false
var invulnerability_timer = 0.0
const INVULNERABILITY_DURATION = 1.0
const BLINK_SPEED = 0.1

var is_being_knocked_back = false
var knockback_velocity = Vector3.ZERO
const KNOCKBACK_FORCE = 8.0
const KNOCKBACK_DECAY = 12.0

func _ready():
	add_to_group("player")
	camera_initial_position = camera.position
	update_camera_zoom()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_captured = false
	
	if mouse_captured and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	
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
	sprite.visible = current_zoom >= FIRST_PERSON_THRESHOLD

func _physics_process(delta: float) -> void:
	if is_invulnerable:
		processar_invencibilidade(delta)
	
	if attack_timer > 0:
		attack_timer -= delta
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	check_and_attack_enemies()
	
	if is_being_knocked_back:
		processar_empurrao(delta)
	elif not is_attacking:
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
	get_tree().call_group("inimigos", "update_target_location", global_position)

func processar_invencibilidade(delta: float):
	invulnerability_timer -= delta
	
	var blink_phase = int(invulnerability_timer / BLINK_SPEED) % 2
	sprite.modulate.a = 0.3 if blink_phase == 0 else 1.0
	
	if invulnerability_timer <= 0.0:
		is_invulnerable = false
		sprite.modulate = Color.WHITE

func processar_empurrao(delta: float):
	velocity.x = knockback_velocity.x
	velocity.z = knockback_velocity.z
	
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	
	if knockback_velocity.length() < 0.5:
		is_being_knocked_back = false
		knockback_velocity = Vector3.ZERO

func check_and_attack_enemies():
	if attack_timer > 0:
		return
	
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	
	for inimigo in inimigos:
		var distance = global_position.distance_to(inimigo.global_position)
		
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
	
	var dano_total = 10 + bonus_dano
	if inimigo.has_method("take_damage"):
		inimigo.take_damage(dano_total)
	
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	sprite.play("parado")

func take_damage(dano: int, direcao_inimigo: Vector3 = Vector3.ZERO):
	if is_invulnerable:
		return
	
	health -= dano
	
	if som_dano:
		som_dano.play()
	
	var direcao_empurrao = Vector3.ZERO
	if direcao_inimigo != Vector3.ZERO:
		direcao_empurrao = (global_position - direcao_inimigo).normalized()
	else:
		direcao_empurrao = -transform.basis.z
	
	is_being_knocked_back = true
	is_attacking = false
	knockback_velocity = direcao_empurrao * KNOCKBACK_FORCE
	knockback_velocity.y = 0
	
	is_invulnerable = true
	invulnerability_timer = INVULNERABILITY_DURATION
	
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	
	if health <= 0:
		die()

func die():
	is_invulnerable = false
	is_being_knocked_back = false
	sprite.modulate = Color.WHITE
