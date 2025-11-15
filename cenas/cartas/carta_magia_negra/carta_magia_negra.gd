# carta_magia_negra.gd
extends Card

func _ready():
	carta_nome = "Magia Negra"
	carta_tipo = 0
	carta_valor = 15
	carta_descricao = "Lança 1 orbe que atravessa múltiplos inimigos (5)"
	super._ready()

func ativar_efeito():
	print("[CARTA] Ativando Magia Negra!")
	
	if not Game.personagem_principal:
		print("[ERRO] Personagem não encontrado!")
		return
	
	var personagem = Game.personagem_principal
	
	# Spawnar apenas 1 orbe
	await spawnar_orbe(personagem)
	print("[CARTA] Orbe de magia negra lançado!")

func spawnar_orbe(personagem: Node3D):
	"""Spawna um único orbe que atravessa inimigos"""
	print("=== INVOCANDO ORBE DE MAGIA NEGRA ===")
	
	# Verificar se personagem tem marcador de posição
	var tem_marcador = personagem.has_node("posicao_magia")
	var posicao_spawn: Vector3
	
	if tem_marcador:
		# Usar posição do marcador
		var marcador = personagem.get_node("posicao_magia")
		posicao_spawn = marcador.global_position
		print("  Usando marcador de magia em: ", posicao_spawn)
	else:
		# Fallback: calcular posição manualmente (na frente do personagem)
		var pos_personagem = personagem.global_position
		var direcao_frente = -personagem.transform.basis.z
		direcao_frente.y = 0
		direcao_frente = direcao_frente.normalized()
		
		posicao_spawn = pos_personagem
		posicao_spawn += direcao_frente * 1.5
		posicao_spawn.y = pos_personagem.y + 1.0  # Altura do orbe
		print("  Calculando posição em: ", posicao_spawn)
	
	# Instanciar orbe
	var efeito = preload("res://cenas/cartas/carta_magia_negra/efeito_magia_negra.tscn")
	var orbe = efeito.instantiate()
	
	# Adicionar ao mundo
	var mundo = get_tree().current_scene
	mundo.add_child(orbe)
	
	# Posicionar
	orbe.global_position = posicao_spawn
	
	print("  Orbe posicionado em: ", posicao_spawn)
	
	# Aguardar 2 frames para garantir que está pronto
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Configurar orbe
	if is_instance_valid(orbe) and orbe.has_method("configurar"):
		orbe.configurar(personagem, carta_valor)
		print("  🌑 Orbe configurado!")
	else:
		print("  [ERRO] Orbe inválido ou sem método configurar")
