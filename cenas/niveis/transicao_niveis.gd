# transicao_nivel.gd
# Adicionar este nó em cada cenário/mapa
extends CanvasLayer

@onready var fade_rect = $ColorRect

# ===== CONFIGURAÇÃO DO PRÓXIMO NÍVEL =====
@export_file("*.tscn") var proximo_nivel: String = ""

var esta_em_transicao: bool = false

func _ready():
	add_to_group("transicao_nivel")
	
	# Começar invisível
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("[TRANSICAO] Sistema pronto. Próximo nível: ", proximo_nivel if not proximo_nivel.is_empty() else "NÃO CONFIGURADO")

func iniciar_transicao_ultima_onda():
	"""Chamado automaticamente quando jogador escolhe carta da última onda"""
	if esta_em_transicao:
		print("[TRANSICAO] Já está em transição!")
		return
	
	if proximo_nivel.is_empty():
		print("[TRANSICAO] [ERRO] Próximo nível não configurado no Inspector!")
		return
	
	print("[TRANSICAO] ========== INICIANDO TRANSICAO ==========")
	print("[TRANSICAO] Destino: ", proximo_nivel)
	
	# Buscar personagem
	var player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print("[TRANSICAO] [AVISO] Personagem não encontrado! Fazendo transição direta...")
		await fazer_transicao_direta()
		return
	
	# Iniciar transição com caminhada
	await iniciar_transicao_com_caminhada(player)

func iniciar_transicao_com_caminhada(player: Node3D):
	"""Faz o jogador andar sozinho enquanto a tela escurece e carrega novo nível"""
	esta_em_transicao = true
	
	# Desabilitar controle do jogador
	if player.has_method("desabilitar_controles"):
		player.desabilitar_controles()
		print("[TRANSICAO] Controles do jogador desabilitados")
	
	# Fazer jogador andar para frente
	iniciar_caminhada_automatica(player)
	
	# Escurecer tela
	await fazer_fade_out()
	
	# Carregar novo nível
	await carregar_nivel(proximo_nivel)

func iniciar_caminhada_automatica(player: Node3D):
	"""Faz o jogador andar automaticamente para frente"""
	print("[TRANSICAO] Jogador caminhando sozinho...")
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Calcular posição de destino (5 metros para frente)
	var direcao_frente = -player.transform.basis.z
	direcao_frente.y = 0
	direcao_frente = direcao_frente.normalized()
	
	var destino = player.global_position + (direcao_frente * 5.0)
	
	# Mover o jogador
	tween.tween_property(player, "global_position", destino, 2.0).set_trans(Tween.TRANS_LINEAR)
	
	# Tocar animação de andar (se existir)
	if player.has_node("AnimationPlayer"):
		var anim_player = player.get_node("AnimationPlayer")
		if anim_player.has_animation("andar"):
			anim_player.play("andar")
		elif anim_player.has_animation("walk"):
			anim_player.play("walk")

func fazer_fade_out(duracao: float = 2.0) -> void:
	"""Escurece a tela gradualmente"""
	print("[TRANSICAO] Escurecendo tela...")
	
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", 1.0, duracao)
	
	await tween.finished
	print("[TRANSICAO] Tela escurecida!")

func fazer_fade_in(duracao: float = 1.0) -> void:
	"""Clareia a tela gradualmente"""
	print("[TRANSICAO] Clareando tela...")
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", 0.0, duracao)
	
	await tween.finished
	
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("[TRANSICAO] Tela clareada!")

func carregar_nivel(nivel_path: String):
	"""Carrega o novo nível substituindo o cenário atual"""
	# Pequena pausa antes de carregar
	await Engine.get_main_loop().create_timer(0.5).timeout
	
	if not ResourceLoader.exists(nivel_path):
		push_error("[TRANSICAO] Nível não encontrado: ", nivel_path)
		esta_em_transicao = false
		await fazer_fade_in()
		return
	
	print("[TRANSICAO] Carregando novo cenário: ", nivel_path)
	
	# Buscar o nó cena_principal
	var cena_principal = get_tree().root.get_node_or_null("cena_principal")
	
	if not cena_principal:
		push_error("[TRANSICAO] cena_principal não encontrada! Usando método padrão...")
		var erro = get_tree().change_scene_to_file(nivel_path)
		if erro != OK:
			push_error("[TRANSICAO] Erro ao carregar nível: ", erro)
			esta_em_transicao = false
			return
		await Engine.get_main_loop().process_frame
		await fazer_fade_in()
		esta_em_transicao = false
		return
	
	# Buscar o cenário atual dentro de cena_principal/mapa
	var no_mapa = cena_principal.get_node_or_null("mapa")
	
	if not no_mapa:
		push_error("[TRANSICAO] Nó 'mapa' não encontrado dentro de cena_principal!")
		esta_em_transicao = false
		await fazer_fade_in()
		return
	
	# Buscar cenário atual (primeiro filho do mapa)
	var cenario_atual = null
	for child in no_mapa.get_children():
		if child is Node3D:
			cenario_atual = child
			break
	
	if cenario_atual:
		print("[TRANSICAO] Removendo cenário atual: ", cenario_atual.name)
		cenario_atual.queue_free()
	
	# Carregar novo cenário
	var novo_cenario_scene = load(nivel_path)
	
	if not novo_cenario_scene:
		push_error("[TRANSICAO] Não foi possível carregar: ", nivel_path)
		esta_em_transicao = false
		await fazer_fade_in()
		return
	
	var novo_cenario = novo_cenario_scene.instantiate()
	print("[TRANSICAO] Adicionando novo cenário: ", novo_cenario.name)
	
	# Adicionar novo cenário ao mapa
	no_mapa.add_child(novo_cenario)
	
	# ===== CORREÇÃO DO BUG: AGUARDAR FÍSICA CARREGAR =====
	# Aguardar vários frames de física para garantir colisões
	for i in range(5):
		await get_tree().physics_frame
	
	print("[TRANSICAO] Física do cenário carregada")
	
	# Reposicionar jogador DEPOIS da física estar pronta
	reposicionar_jogador(novo_cenario)
	
	# Mais alguns frames para estabilizar
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Fade in
	await fazer_fade_in()
	
	esta_em_transicao = false
	print("[TRANSICAO] ========== TRANSICAO COMPLETA ==========")

func fazer_transicao_direta():
	"""Transição sem animação de caminhada (fallback)"""
	esta_em_transicao = true
	
	await fazer_fade_out(1.0)
	await carregar_nivel(proximo_nivel)

func reposicionar_jogador(novo_cenario: Node):
	"""Reposiciona o jogador no spawn do novo cenário"""
	var player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print("[TRANSICAO] [AVISO] Jogador não encontrado para reposicionar")
		return
	
	# Buscar spawn point no novo cenário
	var spawn_point = novo_cenario.get_node_or_null("spawn_point")
	
	if spawn_point:
		player.global_position = spawn_point.global_position
		print("[TRANSICAO] Jogador reposicionado no spawn_point")
	else:
		# Se não tiver spawn_point, colocar na origem do cenário
		player.global_position = novo_cenario.global_position + Vector3(0, 1, 0)
		print("[TRANSICAO] Jogador reposicionado na origem do cenário")
	
	# Reabilitar controles
	if player.has_method("habilitar_controles"):
		player.habilitar_controles()
		print("[TRANSICAO] Controles do jogador habilitados")
