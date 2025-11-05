# carta_atk_basico.gd
# Herda toda a lógica de card.gd e só define o efeito específico
extends Card

func _ready():
	# Configurar propriedades da carta
	carta_nome = "Ataque Básico"
	carta_tipo = 0  # Ataque
	carta_valor = 15
	carta_descricao = "Aumenta o dano base em 15 pontos"
	
	super._ready()  # Chamar _ready() do Card base

# Sobrescrever o método de efeito
func ativar_efeito():
	print(" Ativando Ataque Básico!")
	Game.ativar_efeito_carta(carta_tipo, carta_valor)
