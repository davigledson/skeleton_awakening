# Game.gd (Autoload)
extends Node

# Variáveis globais do sistema de cartas
var cardSelected = false
var mouseOnPlacement = false
var personagem_principal = null

func _ready():
	print("🎮 Sistema de cartas inicializado")
	# Aguardar a cena carregar
	await get_tree().process_frame
	buscar_personagem()

func buscar_personagem():
	"""Busca o personagem principal no grupo 'player'"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		personagem_principal = players[0]
		print("✅ Personagem principal encontrado!")
	else:
		print("⚠️ Personagem não encontrado! Tentando novamente...")
		await get_tree().create_timer(0.5).timeout
		buscar_personagem()

func ativar_efeito_carta(tipo: int, valor: int):
	"""Envia o efeito da carta para o personagem"""
	print("🎯 Game.gd recebeu carta - Tipo: ", tipo, " Valor: ", valor)
	
	if not personagem_principal:
		print("❌ Personagem não encontrado! Buscando...")
		buscar_personagem()
		await get_tree().create_timer(0.1).timeout
	
	if personagem_principal and personagem_principal.has_method("ativar_carta"):
		personagem_principal.ativar_carta(tipo, valor)
		print("✅ Efeito enviado ao personagem!")
	else:
		print("❌ Erro: Personagem não tem o método ativar_carta()!")
