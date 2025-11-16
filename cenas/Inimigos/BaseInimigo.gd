# base_inimigo.gd
extends CharacterBody3D
class_name BaseInimigo

@onready var nav_agent = $NavigationAgent3D
@onready var anim_sprite = $AnimatedSprite3D

@export_group("Estatísticas")
@export var max_health: int = 30
@export var move_speed: float = 1.0
@export var attack_damage: int = 10
@export var attack_range: float = 1.5

@export_group("Animações")
@export var anim_idle: String = "parado"
@export var anim_walk: String = "andando"
@export var anim_attack: String = "atacando"
@export var anim_die: String = "morrendo"
@export var anim_stunned: String = "parado"

@export_group("Efeitos")
@export var tem_animacao_atordoamento: bool = false
@export var duracao_morte: float = 1.0

var health: int
var is_dead: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0

var wobble_time: float = 0.0
var original_rotation: float = 0.0

var is_burning: bool = false
var burn_timer: float = 0.0
var burn_damage_per_tick: int = 0
var burn_tick_timer: float = 0.0
var burn_tick_interval: float = 0.5

func _ready():
	health = max_health
	add_to_group("inimigos")
	nav_agent.target_desired_distance = 0.1
	
	if anim_sprite:
		original_rotation = anim_sprite.rotation.z
	
	animacao_spawn_papel()
	on_inimigo_ready()

func animacao_spawn_papel():
	if not anim_sprite:
		return
	
	anim_sprite.rotation.x = deg_to_rad(180)
	anim_sprite.modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(anim_sprite, "rotation:x", 0.0, 0.8)
	
	await tween.finished
	
	var tween2 = create_tween()
	tween2.tween_property(anim_sprite, "scale", Vector3(1.1, 1.1, 1.0), 0.1)
	await tween2.finished
	
	var tween3 = create_tween()
	tween3.tween_property(anim_sprite, "scale", Vector3.ONE, 0.1)

func on_inimigo_ready():
	pass

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	atualizar_billboard()
	
	if is_burning:
		processar_queimadura(delta)
	
	if is_stunned:
		processar_atordoamento(delta)
		return
	
	processar_movimento(delta)

func atualizar_billboard():
	var camera = get_viewport().get_camera_3d()
	if camera and anim_sprite:
		anim_sprite.look_at(camera.global_position, Vector3.UP)

func processar_atordoamento(delta: float):
	stun_timer -= delta
	wobble_time += delta
	
	if anim_sprite:
		var wobble_angle = sin(wobble_time * 8.0) * 0.3
		anim_sprite.rotation.z = original_rotation + wobble_angle
		
		if tem_animacao_atordoamento:
			anim_sprite.play(anim_stunned)
		else:
			anim_sprite.play(anim_idle)
	
	if stun_timer <= 0.0:
		is_stunned = false
		if anim_sprite:
			anim_sprite.rotation.z = original_rotation
			anim_sprite.modulate = Color.WHITE
	
	velocity = Vector3.ZERO
	move_and_slide()

func processar_movimento(delta: float):
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	
	if anim_sprite:
		anim_sprite.play(anim_walk)
		
		if direction.x != 0:
			anim_sprite.flip_h = direction.x < 0
	
	velocity = direction * move_speed
	move_and_slide()
	
	on_movimento_customizado(delta, direction)

func on_movimento_customizado(delta: float, direction: Vector3):
	pass

func update_target_location(target_location: Vector3):
	if not is_dead and not is_stunned:
		nav_agent.target_position = target_location

func take_damage(damage: int):
	if is_dead:
		return
	
	health -= damage
	
	await aplicar_efeito_dano()
	
	if health <= 0:
		die()
	else:
		on_dano_recebido(damage)

func aplicar_efeito_dano():
	if anim_sprite:
		anim_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		
		if is_stunned:
			anim_sprite.modulate = Color(0.5, 0.7, 1.0)
		else:
			anim_sprite.modulate = Color.WHITE

func on_dano_recebido(damage: int):
	pass

func aplicar_atordoamento(duracao: float = 2.0):
	if is_dead:
		return
	
	is_stunned = true
	stun_timer = duracao
	wobble_time = 0.0
	
	if anim_sprite:
		anim_sprite.modulate = Color(0.5, 0.7, 1.0)
	
	on_atordoado(duracao)

func on_atordoado(duracao: float):
	pass

func aplicar_queimadura(duracao: float = 3.0, dano_por_tick: int = 3):
	if is_dead:
		return
	
	is_burning = true
	burn_timer = duracao
	burn_damage_per_tick = dano_por_tick
	burn_tick_timer = 0.0
	
	on_queimando(duracao, dano_por_tick)

func processar_queimadura(delta: float):
	burn_timer -= delta
	burn_tick_timer -= delta
	
	if anim_sprite:
		var t = sin(burn_timer * 10.0) * 0.5 + 0.5
		anim_sprite.modulate = Color(1.0, 0.3 + t * 0.4, 0.0)
	
	if burn_tick_timer <= 0.0:
		burn_tick_timer = burn_tick_interval
		
		if not is_dead:
			health -= burn_damage_per_tick
			
			if health <= 0:
				die()
				return
	
	if burn_timer <= 0.0:
		is_burning = false
		if anim_sprite and not is_stunned:
			anim_sprite.modulate = Color.WHITE

func on_queimando(duracao: float, dano_por_tick: int):
	pass

func empurrar(direcao: Vector3, forca: float = 3.0):
	if is_dead:
		return
	
	velocity = direcao.normalized() * forca
	velocity.y = 0
	
	aplicar_atordoamento(1.0)
	on_empurrado(direcao, forca)

func on_empurrado(direcao: Vector3, forca: float):
	pass

func die():
	if is_dead:
		return
	
	is_dead = true
	is_stunned = false
	
	velocity = Vector3.ZERO
	
	if anim_sprite:
		anim_sprite.rotation.z = original_rotation
		anim_sprite.play(anim_die)
	
	on_morte()
	
	await get_tree().create_timer(duracao_morte).timeout
	on_antes_destruir()
	
	queue_free()

func on_morte():
	pass

func on_antes_destruir():
	pass
