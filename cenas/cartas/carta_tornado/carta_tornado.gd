# carta_tornado.gd
extends Card

func _ready():
	carta_nome = "Tornado"
	carta_tipo = 3
	carta_valor = 20
	carta_descricao = "Invoca um tornado que se move em zig-zag causando dano em área"
	super._ready()

func ativar_efeito():
	print("[CARTA] Ativando Tornado!")
	
	if not Game.personagem_principal:
		print("[ERRO] Personagem não encontrado!")
		return
	
	var personagem = Game.personagem_principal
	
	# Spawnar tornado na frente do personagem
	await spawnar_tornado(personagem)
	print("[CARTA] Tornado invocado!")

func spawnar_tornado(personagem: Node3D):
	"""Spawna o tornado na frente do personagem"""
	print("=== INVOCANDO TORNADO ===")
	
	# Verificar se personagem tem marcador de posição
	var tem_marcador = personagem.has_node("posicao_magia")
	var posicao_spawn: Vector3
	
	if tem_marcador:
		# Usar posição do marcador
		var marcador = personagem.get_node("posicao_magia")
		posicao_spawn = marcador.global_position
		print("  Usando marcador de magia em: ", posicao_spawn)
	else:
		# Fallback: calcular posição manualmente (1.5m na frente)
		var pos_personagem = personagem.global_position
		var direcao_frente = -personagem.transform.basis.z
		direcao_frente.y = 0
		direcao_frente = direcao_frente.normalized()
		
		posicao_spawn = pos_personagem
		posicao_spawn += direcao_frente * 2.0  # 2 metros na frente
		posicao_spawn.y = pos_personagem.y  # No chão
		print("  Calculando posição em: ", posicao_spawn)
	
	# Instanciar tornado
	var efeito = preload("res://cenas/cartas/carta_tornado/efeito_tornado.tscn")
	var tornado = efeito.instantiate()
	
	# Adicionar ao mundo
	var mundo = get_tree().current_scene
	mundo.add_child(tornado)
	
	# Posicionar
	tornado.global_position = posicao_spawn
	
	print("  Tornado posicionado em: ", posicao_spawn)
	
	# Aguardar 2 frames para garantir que está pronto
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Configurar tornado
	if is_instance_valid(tornado) and tornado.has_method("configurar"):
		tornado.configurar(personagem, carta_valor)
		print("  🌪️ Tornado configurado!")
	else:
		print("  [ERRO] Tornado inválido ou sem método configurar")
