# carta_velocidade.gd
extends Card

func _ready():
	carta_nome = "Rajada de Vento"
	carta_tipo = 2  # 2 = Velocidade
	carta_valor = 3
	carta_descricao = "Aumenta velocidade de movimento em 3 unidades"
	super._ready()

func ativar_efeito():
	print("💨 Ativando Velocidade! +", carta_valor, " de velocidade")
	Game.ativar_efeito_carta(carta_tipo, carta_valor)
