# carta_cura.gd
extends Card

func _ready():
	carta_nome = "Cura Vida"
	carta_tipo = 1  # Cura
	carta_valor = 30
	carta_descricao = "Restaura 30 pontos de vida"
	
	super._ready()

func ativar_efeito():
	print(" Ativando Cura!")
	Game.ativar_efeito_carta(carta_tipo, carta_valor)
