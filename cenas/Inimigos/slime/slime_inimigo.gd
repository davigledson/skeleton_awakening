# slime_inimigo.gd
extends BaseInimigo

@onready var som_pulo = $sons/som_pulo
@onready var som_morte = $sons/som_morte

var tempo_entre_pulos = 0.8
var altura_pulo = 2.0
var distancia_pulo = 3.0
var timer_pulo = 0.0
var esta_no_ar = false

var cooldown_dano = 1.0
var timer_cooldown_dano = 0.0

func _ready():
	max_health = 30
	move_speed = 0.0
	attack_damage = 5
	
	anim_idle = "parado"
	anim_walk = "andando"
	anim_die = "morrendo"
	tem_animacao_atordoamento = false
	duracao_morte = 1.0
	
	super._ready()

func _physics_process(delta: float) -> void:
	if timer_cooldown_dano > 0:
		timer_cooldown_dano -= delta
	
	super._physics_process(delta)
	verificar_colisao_jogador()

func verificar_colisao_jogador():
	if is_dead or timer_cooldown_dano > 0:
		return
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("player"):
			atacar_jogador(collider)
			return

func atacar_jogador(player: Node3D):
	timer_cooldown_dano = cooldown_dano
	
	if player.has_method("take_damage"):
		player.take_damage(attack_damage, global_position)
	
	if anim_sprite:
		anim_sprite.modulate = Color(0.5, 1.0, 0.5)
		await get_tree().create_timer(0.2).timeout
		if anim_sprite:
			anim_sprite.modulate = Color.WHITE

func processar_movimento(delta: float):
	timer_pulo -= delta
	
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	
	if anim_sprite and direction.x != 0:
		anim_sprite.flip_h = direction.x < 0
	
	if is_on_floor():
		esta_no_ar = false
		
		if timer_pulo <= 0.0:
			pular(direction)
			timer_pulo = tempo_entre_pulos
		else:
			if anim_sprite:
				anim_sprite.play(anim_idle)
			velocity = Vector3.ZERO
	else:
		esta_no_ar = true
		if anim_sprite:
			anim_sprite.play(anim_walk)
		
		velocity.y -= 9.8 * delta
	
	move_and_slide()

func pular(direction: Vector3):
	velocity.y = altura_pulo
	velocity.x = direction.x * distancia_pulo
	velocity.z = direction.z * distancia_pulo
	
	if som_pulo:
		som_pulo.pitch_scale = randf_range(0.9, 1.1)
		som_pulo.play()
	
	if anim_sprite:
		anim_sprite.scale = Vector3(1.3, 0.7, 1.0)
		await get_tree().create_timer(0.1).timeout
		if anim_sprite:
			anim_sprite.scale = Vector3.ONE

func on_atordoado(duracao: float):
	timer_pulo = duracao

func on_morte():
	if som_morte:
		som_morte.play()
