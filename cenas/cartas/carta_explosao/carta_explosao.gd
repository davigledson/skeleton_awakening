# carta_explosao.gd
extends Card

func _ready():
	carta_nome = "Explosão Flamejante"
	carta_tipo = 3
	carta_valor = 25
	carta_descricao = "Causa 25 de dano em área ao redor do personagem"
	super._ready()

func ativar_efeito():
	print("💥 [CARTA] Ativando Explosão! ", carta_valor, " de dano em área!")
	print("💥 [CARTA] Personagem está se movendo? Velocidade: ", Game.personagem_principal.velocity if Game.personagem_principal else "N/A")
	
	# Verificar se personagem existe
	if not Game.personagem_principal:
		print("❌ Personagem não encontrado!")
		return
	
	var personagem = Game.personagem_principal
	
	# Em jogos 2.5D, usar a direção baseada na rotação Y do personagem
	var rotacao_y = personagem.rotation.y
	
	# Calcular vetor de direção usando transform.basis (mais preciso)
	var direcao_frente = -personagem.transform.basis.z
	direcao_frente.y = 0  # Manter no plano horizontal
	direcao_frente = direcao_frente.normalized()
	
	# Posição da explosão
	var distancia_frente = 2
	var posicao_explosao = personagem.global_position + (direcao_frente * distancia_frente)
	
	# Manter a explosão no chão (mesma altura do personagem)
	posicao_explosao.y = personagem.global_position.y + 0.5
	
	print(" Personagem em: ", personagem.global_position)
	print(" Rotação Y: ", rad_to_deg(rotacao_y), "°")
	print(" Direção frente: ", direcao_frente)
	print(" Explosão vai spawnar em: ", posicao_explosao)
	
	# Spawnar explosão (não esperar)
	spawnar_explosao(posicao_explosao)
	
	# Ativar dano em área IMEDIATAMENTE (não precisa esperar efeito visual)
	if personagem.has_method("dano_em_area_posicao"):
		personagem.dano_em_area_posicao(carta_valor, posicao_explosao)
		print("✅ Dano em área aplicado!")

func spawnar_explosao(posicao: Vector3):
	"""Spawna o efeito visual da explosão"""
	print(" Iniciando spawn da explosão...")
	
	var efeito_explosao = preload("res://cenas/cartas/carta_explosao/explosion.tscn")
	var explosao = efeito_explosao.instantiate()
	
	# Adicionar ao mundo principal (root da cena)
	var mundo = get_tree().current_scene
	
	if not mundo:
		print("❌ ERRO: Mundo não encontrado!")
		return
	
	mundo.add_child(explosao)
	print(" Explosão adicionada ao mundo")
	
	# Posicionar IMEDIATAMENTE
	explosao.global_position = posicao
	print(" Explosão posicionada em: ", explosao.global_position)
	
	# Aguardar processo físico completar
	await get_tree().process_frame
	await get_tree().process_frame  # Esperar 2 frames para garantir
	
	# Verificar se ainda existe antes de explodir
	if not is_instance_valid(explosao):
		print(" Explosão foi destruída antes de explodir!")
		return
	
	# Ativar a explosão
	if explosao.has_method("explode"):
		explosao.explode()
		print(" Explosão ativada com sucesso!")
	else:
		print(" Explosão não tem método explode()!")
