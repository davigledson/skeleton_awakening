# slime_inimigo.gd
extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var anim_sprite = $AnimatedSprite3D

var SPEED = 1.0
var health = 30
var is_dead = false  # Flag para saber se já morreu

func _ready():
	add_to_group("inimigos")
	nav_agent.target_desired_distance = 0.1

func _physics_process(delta):
	# Se morreu, não fazer mais nada
	if is_dead:
		return
	
	# FAZER SPRITE OLHAR PARA CÂMERA
	var camera = get_viewport().get_camera_3d()
	if camera:
		anim_sprite.look_at(camera.global_position, Vector3.UP)
	
	# Calcular direção
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	
	# Animação andando
	anim_sprite.play("andando")
	
	# Virar sprite
	if direction.x != 0:
		anim_sprite.flip_h = direction.x < 0
	
	# Mover
	velocity = direction * SPEED
	move_and_slide()

func update_target_location(target_location):
	if not is_dead:  # Só perseguir se não estiver morto
		nav_agent.target_position = target_location

func take_damage(damage: int):
	if is_dead:  # Não receber dano se já morreu
		return
	
	health -= damage
	print("Inimigo recebeu ", damage, " de dano! Vida: ", health)
	
	# Efeito visual (piscar vermelho)
	anim_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	anim_sprite.modulate = Color.WHITE
	
	# Morrer se vida acabar
	if health <= 0:
		die()

func die():
	is_dead = true
	print("Inimigo morreu!")
	
	# Parar movimento
	velocity = Vector3.ZERO
	
	# Tocar animação de morte
	anim_sprite.play("morrendo")
	
	# Aguardar a animação terminar antes de remover
	# Ajuste o tempo conforme a duração da sua animação
	await get_tree().create_timer(1.0).timeout  # 1 segundo - ajuste conforme necessário
	
	# Remover o inimigo da cena
	queue_free()
