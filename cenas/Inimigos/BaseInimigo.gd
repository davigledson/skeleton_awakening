# base_inimigo.gd
# SCRIPT BASE para todos os inimigos do jogo
extends CharacterBody3D
class_name BaseInimigo

# Componentes obrigatórios (devem existir na cena)
@onready var nav_agent = $NavigationAgent3D
@onready var anim_sprite = $AnimatedSprite3D

# ===== PROPRIEDADES EXPORTADAS (configuráveis no editor) =====
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
@export var anim_stunned: String = "parado"  # Animação quando atordoado

@export_group("Efeitos")
@export var tem_animacao_atordoamento: bool = false  # Se tem animação específica de zonzo
@export var duracao_morte: float = 1.0  # Tempo da animação de morte

# ===== VARIÁVEIS INTERNAS =====
var health: int
var is_dead: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0

# Efeito visual de zonzo
var wobble_time: float = 0.0
var original_rotation: float = 0.0

# Efeito de queimadura (dano ao longo do tempo)
var is_burning: bool = false
var burn_timer: float = 0.0
var burn_damage_per_tick: int = 0
var burn_tick_timer: float = 0.0
var burn_tick_interval: float = 0.5  # Dano a cada 0.5 segundos

# ===== INICIALIZAÇÃO =====
func _ready():
	health = max_health
	add_to_group("inimigos")
	nav_agent.target_desired_distance = 0.1
	
	if anim_sprite:
		original_rotation = anim_sprite.rotation.z
	
	# Chamar hook para classes filhas
	on_inimigo_ready()

# HOOK: Sobrescrever nas classes filhas para adicionar lógica customizada
func on_inimigo_ready():
	pass

# ===== FÍSICA E MOVIMENTO =====
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Billboard (sprite sempre olha para câmera)
	atualizar_billboard()
	
	# Processar atordoamento
	if is_stunned:
		processar_atordoamento(delta)
		return
	
	# Movimento normal
	processar_movimento(delta)

func atualizar_billboard():
	"""Faz o sprite sempre olhar para a câmera"""
	var camera = get_viewport().get_camera_3d()
	if camera and anim_sprite:
		anim_sprite.look_at(camera.global_position, Vector3.UP)

func processar_atordoamento(delta: float):
	"""Lógica de atordoamento (zonzo)"""
	stun_timer -= delta
	wobble_time += delta
	
	# Efeito visual de balanço
	if anim_sprite:
		var wobble_angle = sin(wobble_time * 8.0) * 0.3
		anim_sprite.rotation.z = original_rotation + wobble_angle
		
		# Tocar animação apropriada
		if tem_animacao_atordoamento:
			anim_sprite.play(anim_stunned)
		else:
			anim_sprite.play(anim_idle)
	
	# Fim do atordoamento
	if stun_timer <= 0.0:
		is_stunned = false
		if anim_sprite:
			anim_sprite.rotation.z = original_rotation
			anim_sprite.modulate = Color.WHITE
		print("Inimigo recuperou do atordoamento!")
	
	# Não se mover enquanto atordoado
	velocity = Vector3.ZERO
	move_and_slide()

func processar_movimento(delta: float):
	"""Movimento normal do inimigo"""
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	
	# Tocar animação de andar
	if anim_sprite:
		anim_sprite.play(anim_walk)
		
		# Virar sprite baseado na direção
		if direction.x != 0:
			anim_sprite.flip_h = direction.x < 0
	
	# Aplicar velocidade
	velocity = direction * move_speed
	move_and_slide()
	
	# HOOK: Permite classes filhas customizarem movimento
	on_movimento_customizado(delta, direction)

# HOOK: Sobrescrever para adicionar lógica de movimento customizada
func on_movimento_customizado(delta: float, direction: Vector3):
	pass

# ===== NAVEGAÇÃO =====
func update_target_location(target_location: Vector3):
	"""Atualiza o alvo que o inimigo está perseguindo"""
	if not is_dead and not is_stunned:
		nav_agent.target_position = target_location

# ===== COMBATE =====
func take_damage(damage: int):
	"""Recebe dano"""
	if is_dead:
		return
	
	health -= damage
	print(name, " recebeu ", damage, " de dano! Vida: ", health, "/", max_health)
	
	# Efeito visual de dano
	await aplicar_efeito_dano()
	
	# Verificar morte
	if health <= 0:
		die()
	else:
		# HOOK: Permite classes filhas reagirem ao dano
		on_dano_recebido(damage)

func aplicar_efeito_dano():
	"""Efeito visual ao receber dano (piscar vermelho)"""
	if anim_sprite:
		anim_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		
		# Voltar cor apropriada
		if is_stunned:
			anim_sprite.modulate = Color(0.5, 0.7, 1.0)  # Azul se atordoado
		else:
			anim_sprite.modulate = Color.WHITE

# HOOK: Sobrescrever para reagir ao dano
func on_dano_recebido(damage: int):
	pass

# ===== EFEITOS DE STATUS =====
func aplicar_atordoamento(duracao: float = 2.0):
	"""Aplica efeito de atordoamento (zonzo)"""
	if is_dead:
		return
	
	print(name, " ficou ZONZO por ", duracao, " segundos!")
	
	is_stunned = true
	stun_timer = duracao
	wobble_time = 0.0
	
	# Cor azulada
	if anim_sprite:
		anim_sprite.modulate = Color(0.5, 0.7, 1.0)
	
	# Efeitos visuais extras
	spawn_efeito_atordoamento()
	
	# HOOK: Permite classes filhas customizarem atordoamento
	on_atordoado(duracao)

func spawn_efeito_atordoamento():
	"""Spawna efeitos visuais de atordoamento (estrelinhas, etc)"""
	print("  ✨ Estrelinhas de zonzo!")
	# TODO: Implementar spawn de estrelinhas

# HOOK: Sobrescrever para customizar atordoamento
func on_atordoado(duracao: float):
	pass

func empurrar(direcao: Vector3, forca: float = 3.0):
	"""Empurra o inimigo para trás"""
	if is_dead:
		return
	
	print(name, " empurrado com força ", forca)
	
	# Aplicar velocidade de empurrão
	velocity = direcao.normalized() * forca
	velocity.y = 0
	
	# Empurrão causa mini-atordoamento
	aplicar_atordoamento(1.0)
	
	# HOOK
	on_empurrado(direcao, forca)

# HOOK: Sobrescrever para reagir a empurrões
func on_empurrado(direcao: Vector3, forca: float):
	pass

# ===== MORTE =====
func die():
	"""Lógica de morte do inimigo"""
	if is_dead:
		return
	
	is_dead = true
	is_stunned = false
	
	print(name, " morreu!")
	
	# Parar movimento
	velocity = Vector3.ZERO
	
	# Resetar visual
	if anim_sprite:
		anim_sprite.rotation.z = original_rotation
		anim_sprite.play(anim_die)
	
	# HOOK: Permite classes filhas customizarem morte
	on_morte()
	
	# Aguardar animação e destruir
	await get_tree().create_timer(duracao_morte).timeout
	
	# HOOK antes de destruir
	on_antes_destruir()
	
	queue_free()

# HOOK: Sobrescrever para adicionar lógica de morte
func on_morte():
	pass

# HOOK: Última chance antes de destruir (spawnar loot, etc)
func on_antes_destruir():
	pass
