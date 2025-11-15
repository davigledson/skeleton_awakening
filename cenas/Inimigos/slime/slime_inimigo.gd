# slime_inimigo.gd - VERSÃO SIMPLES
# Movimento pulante mais simples e direto
extends BaseInimigo

# ===== VARIÁVEIS DE MOVIMENTO PULANTE =====
var tempo_entre_pulos = 0.8  # Pula a cada 0.8 segundos
var altura_pulo = 2.0  # Altura do pulo (quanto mais alto, maior o pulo)
var distancia_pulo = 3.0  # Distância horizontal do pulo
var timer_pulo = 0.0
var esta_no_ar = false

func _ready():
	# Configurar estatísticas do Slime
	max_health = 30
	move_speed = 0.0  # Não usa velocidade contínua, só pulos!
	attack_damage = 5
	
	# Animações
	anim_idle = "parado"
	anim_walk = "andando"
	anim_die = "morrendo"
	tem_animacao_atordoamento = false
	duracao_morte = 1.0
	
	super._ready()

func on_inimigo_ready():
	print("🟢 Slime pulante pronto!")

# Sobrescrever movimento completamente
func processar_movimento(delta: float):
	"""Movimento por PULOS em vez de deslizar"""
	timer_pulo -= delta
	
	# Calcular direção do alvo
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	
	# Virar sprite
	if anim_sprite and direction.x != 0:
		anim_sprite.flip_h = direction.x < 0
	
	# Verificar se está no chão
	if is_on_floor():
		esta_no_ar = false
		
		# Hora de pular?
		if timer_pulo <= 0.0:
			pular(direction)
			timer_pulo = tempo_entre_pulos
		else:
			# Esperando para pular
			if anim_sprite:
				anim_sprite.play(anim_idle)
			velocity = Vector3.ZERO
	else:
		# Está no ar
		esta_no_ar = true
		if anim_sprite:
			anim_sprite.play(anim_walk)
		
		# Aplicar gravidade
		velocity.y -= 9.8 * delta
	
	move_and_slide()

func pular(direction: Vector3):
	"""Faz o slime pular na direção do alvo"""
	print("  🟢 *BOING!*")
	
	# Velocidade vertical (altura do pulo)
	velocity.y = altura_pulo
	
	# Velocidade horizontal (distância do pulo)
	velocity.x = direction.x * distancia_pulo
	velocity.z = direction.z * distancia_pulo
	
	# Efeito visual: comprimir antes de pular
	if anim_sprite:
		# Squash (comprimir)
		anim_sprite.scale = Vector3(1.3, 0.7, 1.0)
		
		# Voltar ao normal após 0.1s
		await get_tree().create_timer(0.1).timeout
		if anim_sprite:
			anim_sprite.scale = Vector3.ONE

# Movimento customizado (não usado nesta versão)
func on_movimento_customizado(delta: float, direction: Vector3):
	pass

func on_dano_recebido(damage: int):
	print("  🟢 *squish* (som de slime)")

func on_atordoado(duracao: float):
	print("  🟢 Slime ficou gelatinoso!")
	# Quando atordoado, não pula
	timer_pulo = duracao

func on_queimando(duracao: float, dano_por_tick: int):
	print("  🟢 Slime está DERRETENDO!")

func on_empurrado(direcao: Vector3, forca: float):
	print("  🟢 Slime esticou!")

func on_morte():
	print("  🟢 Slime dissolveu!")

func on_antes_destruir():
	print("  🟢 Slime dropou gosma!")
