# carta_explosao.gd
extends Card

func _ready():
	carta_nome = "Explosão Flamejante"
	carta_tipo = 3  # 3 = Dano em Área
	carta_valor = 25
	carta_descricao = "Causa 25 de dano em área ao redor do personagem"
	super._ready()

func ativar_efeito():
	print(" Ativando Explosão! ", carta_valor, " de dano em área!")
	Game.ativar_efeito_carta(carta_tipo, carta_valor)
