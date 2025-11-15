# slime_inimigo.gd
# Inimigo Slime - Estende a classe base
extends BaseInimigo

# ===== CONFIGURAÇÃO NO _ready() =====
func _ready():
	# Configurar estatísticas específicas do Slime
	max_health = 30
	move_speed = 1.0
	attack_damage = 5
	attack_range = 1.5
	
	# Configurar nomes das animações do Slime
	anim_idle = "parado"
	anim_walk = "andando"
	anim_attack = "atacando"
	anim_die = "morrendo"
	anim_stunned = "parado"  # Slime usa mesma animação de parado quando zonzo
	
	# Slime NÃO tem animação específica de atordoamento
	tem_animacao_atordoamento = false
	
	# Tempo da animação de morte do Slime
	duracao_morte = 1.0
	
	# Chamar _ready() da classe base (IMPORTANTE!)
	super._ready()

# ===== HOOKS CUSTOMIZADOS (OPCIONAL) =====

# Chamado quando o inimigo termina de inicializar
func on_inimigo_ready():
	print("🟢 Slime pronto para atacar!")

# Permite adicionar lógica extra ao movimento
func on_movimento_customizado(delta: float, direction: Vector3):
	# Slime poderia ter um movimento "pulante", por exemplo
	# Por enquanto, usa o movimento padrão
	pass

# Reage ao receber dano
func on_dano_recebido(damage: int):
	# Slime poderia fazer um som ou efeito especial ao ser atingido
	print("  🟢 *squish* (som de slime)")

# Customiza o atordoamento
func on_atordoado(duracao: float):
	# Slime poderia ficar "derretido" quando atordoado
	print("  🟢 Slime ficou gelatinoso!")

# Reage a empurrões
func on_empurrado(direcao: Vector3, forca: float):
	# Slime poderia esticar na direção do empurrão
	print("  🟢 Slime esticou!")

# Lógica especial ao morrer
func on_morte():
	print("  🟢 Slime dissolveu!")
	# Poderia spawnar partículas de gosma, por exemplo

# Última chance antes de destruir (spawnar loot)
func on_antes_destruir():
	# Slime poderia dropar itens aqui
	print("  🟢 Slime dropou... nada por enquanto!")
	# TODO: spawnar_loot()
