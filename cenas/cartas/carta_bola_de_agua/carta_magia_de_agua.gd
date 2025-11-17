# carta_magia_agua.gd
extends Card

func _ready():
	carta_nome = "Magia de Água"
	carta_tipo = 0
	carta_valor = 15
	carta_descricao = "Lança 3 bolas de água que perseguem inimigos diferentes"
	super._ready()

func ativar_efeito():
	if not Game.personagem_principal:
		return
	
	var personagem = Game.personagem_principal
	var alvos = buscar_tres_inimigos_proximos(personagem)
	
	if alvos.size() == 0:
		return
	
	await spawnar_bolas_sequencial(personagem, alvos)

func buscar_tres_inimigos_proximos(personagem: Node3D) -> Array:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	
	if inimigos.is_empty():
		return []
	
	var inimigos_com_distancia = []
	for inimigo in inimigos:
		var dist = personagem.global_position.distance_to(inimigo.global_position)
		inimigos_com_distancia.append({"inimigo": inimigo, "distancia": dist})
	
	inimigos_com_distancia.sort_custom(func(a, b): return a.distancia < b.distancia)
	
	var alvos = []
	var max_alvos = min(3, inimigos_com_distancia.size())
	
	for i in range(max_alvos):
		alvos.append(inimigos_com_distancia[i].inimigo)
	
	return alvos

func spawnar_bolas_sequencial(personagem: Node3D, alvos: Array):
	for i in range(alvos.size()):
		var alvo = alvos[i]
		
		# Verificar se alvo ainda existe antes de spawnar
		if not is_instance_valid(alvo):
			continue
		
		await spawnar_bola_unica(personagem, alvo, i)
		await get_tree().create_timer(0.5).timeout

func spawnar_bola_unica(personagem: Node3D, alvo: Node3D, indice: int):
	# Verificar novamente se alvo existe
	if not is_instance_valid(alvo):
		return
	
	var posicao_base: Vector3
	
	if personagem.has_node("posicao_magia"):
		posicao_base = personagem.get_node("posicao_magia").global_position
	else:
		var direcao_frente = -personagem.transform.basis.z
		direcao_frente.y = 0
		direcao_frente = direcao_frente.normalized()
		
		posicao_base = personagem.global_position + direcao_frente * 1.5
		posicao_base.y = personagem.global_position.y + 1.2
	
	var efeito = preload("res://cenas/cartas/carta_bola_de_agua/efeito_agua.tscn")
	var bola = efeito.instantiate()
	
	get_tree().current_scene.add_child(bola)
	
	var direcao_direita = personagem.transform.basis.x.normalized()
	var offset_lateral = 0.0
	
	match indice:
		0: offset_lateral = -0.8
		1: offset_lateral = 0.0
		2: offset_lateral = 0.8
	
	bola.global_position = posicao_base + (direcao_direita * offset_lateral)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verificar mais uma vez antes de configurar
	if is_instance_valid(bola) and bola.has_method("configurar") and is_instance_valid(alvo):
		bola.configurar(alvo, carta_valor)
