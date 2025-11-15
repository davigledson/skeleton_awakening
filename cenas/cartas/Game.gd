# Game.gd (Autoload)
extends Node

var cardSelected = false
var mouseOnPlacement = false
var personagem_principal = null

func _ready():
	print("Sistema de cartas inicializado")
	await get_tree().process_frame
	buscar_personagem()

func buscar_personagem():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		personagem_principal = players[0]
		print("Personagem principal encontrado em: ", personagem_principal.global_position)
	else:
		print("[AVISO] Personagem nao encontrado! Tentando novamente...")
		await get_tree().create_timer(0.5).timeout
		buscar_personagem()

func ativar_efeito_carta(tipo: int, valor: int):
	"""Apenas envia o efeito para o personagem - efeitos visuais são spawnados pelas cartas"""
	print("Game.gd recebeu carta - Tipo: ", tipo, " Valor: ", valor)
	
	if not personagem_principal:
		print("[ERRO] Personagem nao encontrado! Buscando...")
		buscar_personagem()
		await get_tree().create_timer(0.1).timeout
	
	if personagem_principal and personagem_principal.has_method("ativar_carta"):
		personagem_principal.ativar_carta(tipo, valor)
		print("Efeito enviado ao personagem!")
	else:
		print("[ERRO] Personagem nao tem o metodo ativar_carta()!")
