# carta_drop.gd
extends Node3D

@onready var sprite = $Sprite3D
@onready var area = $Area3D
@onready var som_pegar = $som_pegar

var tempo_flutuacao: float = 0.0
var posicao_inicial: Vector3
var esta_coletada: bool = false
var velocidade_flutuacao: float = 2.0
var altura_flutuacao: float = 0.3
var velocidade_rotacao: float = 2.0

# ===== NOVAS VARIÁVEIS PARA MOVIMENTO =====
var velocidade_aproximacao: float = 1.5  # Velocidade de aproximação do jogador
var distancia_minima: float = 2.0  # Distância mínima antes de coletar automaticamente
var player_ref: Node3D = null

# ===== VARIÁVEL CONFIGURADA PELO SPAWNER =====
var eh_ultima_onda: bool = false

func _ready():
	add_to_group("cartas")
	
	print("[CARTA_DROP] Carta criada. É última onda: ", eh_ultima_onda)
	
	# Buscar referência do jogador
	var jogador = get_tree().get_first_node_in_group("player")
	if jogador:
		player_ref = jogador
	
	# Ajustar altura inicial se estiver muito baixa
	if global_position.y < 0.5:
		global_position.y = 1.0
	
	posicao_inicial = global_position
	
	if area:
		area.process_mode = Node.PROCESS_MODE_ALWAYS
		area.body_entered.connect(_on_body_entered)
	else:
		push_error("[CARTA_DROP] Area3D nao encontrada!")
	
	if sprite:
		sprite.scale = Vector3.ZERO
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector3.ONE, 0.5)\
			.set_trans(Tween.TRANS_ELASTIC)\
			.set_ease(Tween.EASE_OUT)

func _process(delta: float):
	if esta_coletada:
		return
	
	# ===== MOVIMENTO EM DIREÇÃO AO JOGADOR =====
	if player_ref and is_instance_valid(player_ref):
		var direcao_para_jogador = player_ref.global_position - global_position
		var distancia = direcao_para_jogador.length()
		
		# Manter a carta acima do chão
		var altura_desejada = max(player_ref.global_position.y + 1.0, 1.0)
		
		# Se estiver longe, aproximar
		if distancia > distancia_minima:
			# Movimento horizontal em direção ao jogador
			var direcao_horizontal = Vector3(direcao_para_jogador.x, 0, direcao_para_jogador.z).normalized()
			posicao_inicial += direcao_horizontal * velocidade_aproximacao * delta
			
			# Ajustar altura gradualmente
			posicao_inicial.y = lerp(posicao_inicial.y, altura_desejada, delta * 2.0)
		else:
			# Se estiver perto o suficiente, coletar automaticamente
			if not esta_coletada:
				coletar_carta(player_ref)
				return
	
	# ===== FLUTUAÇÃO =====
	tempo_flutuacao += delta * velocidade_flutuacao
	var offset_y = sin(tempo_flutuacao) * altura_flutuacao
	global_position.y = posicao_inicial.y + offset_y
	global_position.x = posicao_inicial.x
	global_position.z = posicao_inicial.z
	
	# ===== ROTAÇÃO =====
	if sprite:
		sprite.rotation.y += delta * velocidade_rotacao

func _on_body_entered(body: Node3D):
	if esta_coletada:
		return
	
	if body.is_in_group("player"):
		coletar_carta(body)

func coletar_carta(player: Node3D):
	esta_coletada = true
	
	print("[CARTA_DROP] ========== CARTA COLETADA ==========")
	print("[CARTA_DROP] É última onda: ", eh_ultima_onda)
	
	if som_pegar:
		som_pegar.play()
	
	var tween_animacao = null
	if sprite:
		tween_animacao = create_tween()
		tween_animacao.set_parallel(true)
		tween_animacao.tween_property(sprite, "scale", Vector3.ZERO, 0.3)
		tween_animacao.tween_property(self, "global_position", player.global_position + Vector3(0, 1.5, 0), 0.3)
		tween_animacao.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	get_tree().paused = true
	abrir_selecao_cartas(player)
	
	if tween_animacao:
		await tween_animacao.finished
	
	queue_free()

func abrir_selecao_cartas(player: Node3D):
	var selecao_scene = load("res://cenas/gui/selecao_cartas.tscn")
	
	if not selecao_scene:
		push_error("[CARTA_DROP] Cena selecao_cartas.tscn nao encontrada!")
		get_tree().paused = false
		return
	
	var selecao = selecao_scene.instantiate()
	selecao.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ===== IMPORTANTE: PASSAR SE É ÚLTIMA ONDA =====
	if "eh_ultima_onda" in selecao:
		selecao.eh_ultima_onda = eh_ultima_onda
		print("[CARTA_DROP] ✅ Configurado eh_ultima_onda na interface: ", eh_ultima_onda)
	else:
		print("[CARTA_DROP] ❌ ERRO: Interface não tem propriedade 'eh_ultima_onda'!")
	
	get_tree().root.add_child(selecao)
	print("[CARTA_DROP] Interface de seleção aberta!")

# ===== FUNÇÃO ESTÁTICA (NÃO USADA MAIS) =====
static func spawnar_carta_na_frente_do_player(cena_carta: PackedScene, player: Node3D, nivel_destino: String = "") -> Node3D:
	"""Esta função não é mais usada. O spawner cria a carta diretamente."""
	if not cena_carta or not player:
		return null
	
	var carta = cena_carta.instantiate()
	
	var direcao_frente = -player.transform.basis.z
	direcao_frente.y = 0
	direcao_frente = direcao_frente.normalized()
	
	var pos = player.global_position
	pos += direcao_frente * 3.0
	pos.y = max(player.global_position.y + 1.0, 1.0)
	
	player.get_tree().current_scene.add_child(carta)
	carta.global_position = pos
	
	return carta
