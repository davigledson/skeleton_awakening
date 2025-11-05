# carta_data.gd (crie um novo script)
extends Resource
class_name CartaData

enum TipoCarta {
	ATAQUE_BASICO,
	CURA,
	VELOCIDADE,
	DANO_AREA
}

@export var nome: String = "Carta"
@export var tipo: TipoCarta = TipoCarta.ATAQUE_BASICO
@export var custo_mana: int = 1
@export var valor: int = 10  # Dano, cura, etc
@export var textura: Texture2D
