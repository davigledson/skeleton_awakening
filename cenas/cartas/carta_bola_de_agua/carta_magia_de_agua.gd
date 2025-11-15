# carta_magia_agua.gd
extends Card

func _ready():
	carta_nome = "Magia de Água"
	carta_tipo = 0
	carta_valor = 15
	carta_descricao = "Lança 3 bolas de água que perseguem inimigos diferentes"
	super._ready()

func ativar_efeito():
	print("[CARTA] Ativando Magia de Agua!")
	
	if not Game.personagem_principal:
		print("[ERRO] Personagem nao encontrado!")
		return
	
	var personagem = Game.personagem_principal
	
	# BUSCAR 3 INIMIGOS DIFERENTES
	var alvos = buscar_tres_inimigos_proximos(personagem)
	
	if alvos.size() == 0:
		print("[AVISO] Nenhum inimigo encontrado!")
		return
	
	print("🎯 Encontrados ", alvos.size(), " alvos:")
	for i in range(alvos.size()):
		print("  Alvo ", i + 1, ": ", alvos[i].name)
	
	# Spawnar bolas para cada alvo
	await spawnar_bolas_sequencial(personagem, alvos)
	print("[CARTA] Todas as bolas foram spawnadas!")

func buscar_tres_inimigos_proximos(personagem: Node3D) -> Array:
	"""Retorna até 3 inimigos mais próximos (não repetidos)"""
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	
	if inimigos.size() == 0:
		return []
	
	# Calcular distâncias
	var inimigos_com_distancia = []
	for inimigo in inimigos:
		var dist = personagem.global_position.distance_to(inimigo.global_position)
		inimigos_com_distancia.append({
			"inimigo": inimigo,
			"distancia": dist
		})
	
	# Ordenar por distância (mais próximo primeiro)
	inimigos_com_distancia.sort_custom(func(a, b): return a.distancia < b.distancia)
	
	# Pegar até 3 inimigos
	var alvos = []
	var max_alvos = min(3, inimigos_com_distancia.size())
	
	for i in range(max_alvos):
		alvos.append(inimigos_com_distancia[i].inimigo)
	
	return alvos

func spawnar_bolas_sequencial(personagem: Node3D, alvos: Array):
	"""Spawna bolas uma por vez, cada uma para um alvo diferente"""
	print("=== INICIANDO SEQUENCIA DE ", alvos.size(), " BOLAS ===")
	
	for i in range(alvos.size()):
		var alvo = alvos[i]
		
		print("\n[BOLA ", i + 1, "/", alvos.size(), "] - Iniciando spawn...")
		print("  Posicao do personagem AGORA: ", personagem.global_position)
		print("  Alvo: ", alvo.name, " em ", alvo.global_position)
		
		await spawnar_bola_unica(personagem, alvo, i)
		
		print("[BOLA ", i + 1, "/", alvos.size(), "] - Spawn completo, aguardando...")
		await get_tree().create_timer(0.5).timeout
	
	print("\n=== SEQUENCIA COMPLETA - ", alvos.size(), " bolas spawnadas ===")

func spawnar_bola_unica(personagem: Node3D, alvo: Node3D, indice: int):
	"""Spawna uma única bola em posições diferentes ao redor do personagem"""
	print("  [SPAWN] Iniciando bola ", indice + 1)
	
	# Verificar se personagem tem marcador de posição
	var tem_marcador = personagem.has_node("posicao_magia")
	var posicao_base: Vector3
	
	if tem_marcador:
		# Usar posição do marcador
		var marcador = personagem.get_node("posicao_magia")
		posicao_base = marcador.global_position
		print("  [SPAWN] Usando marcador de magia em: ", posicao_base)
	else:
		# Fallback: calcular posição manualmente
		var pos_personagem_atual = personagem.global_position
		var direcao_frente = -personagem.transform.basis.z
		direcao_frente.y = 0
		direcao_frente = direcao_frente.normalized()
		
		posicao_base = pos_personagem_atual
		posicao_base += direcao_frente * 1.5
		posicao_base.y = pos_personagem_atual.y + 1.2
		print("  [SPAWN] Sem marcador, calculando posicao em: ", posicao_base)
	
	var efeito = preload("res://cenas/cartas/carta_bola_de_agua/efeito_agua.tscn")
	var bola = efeito.instantiate()
	
	# Adicionar ao mundo
	var mundo = get_tree().current_scene
	mundo.add_child(bola)
	
	# Calcular offset lateral para cada bola
	var direcao_direita = personagem.transform.basis.x.normalized()
	var offset_lateral = 0.0
	
	match indice:
		0:  # ESQUERDA
			offset_lateral = -0.8
		1:  # CENTRO
			offset_lateral = 0.0
		2:  # DIREITA
			offset_lateral = 0.8
	
	# Posição final: posição base + offset lateral
	var pos = posicao_base + (direcao_direita * offset_lateral)
	
	bola.global_position = pos
	
	print("  [SPAWN] Bola ", indice + 1, " posicionada em: ", pos)
	print("  [SPAWN] Offset lateral: ", offset_lateral)
	
	# Aguardar 2 frames para garantir que está pronto
	await get_tree().process_frame
	await get_tree().process_frame
	
	if is_instance_valid(bola) and bola.has_method("configurar"):
		bola.configurar(alvo, carta_valor)
		print("  [SPAWN] Bola ", indice + 1, " configurada para alvo: ", alvo.name)
	else:
		print("  [ERRO] Bola ", indice + 1, " invalida ou sem metodo configurar")
