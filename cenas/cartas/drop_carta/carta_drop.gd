# carta_drop.gd
extends Node3D

@onready var sprite = $Sprite3D
@onready var area = $Area3D
@onready var som_pegar = $som_pegar

var tempo_flutuacao: float = 0.0
var posicao_inicial: Vector3
var esta_coletada: bool = false

var velocidade_flutuacao: float = 2.0
var altura_flutuacao: float = 0.3
var velocidade_rotacao: float = 2.0

func _ready():
	add_to_group("cartas")
	
	if global_position.y < 0.5:
		global_position.y = 1.0
	
	posicao_inicial = global_position
	
	if area:
		area.process_mode = Node.PROCESS_MODE_ALWAYS
		area.body_entered.connect(_on_body_entered)
	else:
		push_error("[CARTA_DROP] Area3D nao encontrada!")
	
	if sprite:
		sprite.scale = Vector3.ZERO
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector3.ONE, 0.5)\
			.set_trans(Tween.TRANS_ELASTIC)\
			.set_ease(Tween.EASE_OUT)

func _process(delta: float):
	if esta_coletada:
		return
	
	tempo_flutuacao += delta * velocidade_flutuacao
	var offset_y = sin(tempo_flutuacao) * altura_flutuacao
	global_position.y = posicao_inicial.y + offset_y
	
	if sprite:
		sprite.rotation.y += delta * velocidade_rotacao

func _on_body_entered(body: Node3D):
	if esta_coletada:
		return
	
	if body.is_in_group("player"):
		coletar_carta(body)

func coletar_carta(player: Node3D):
	esta_coletada = true
	
	if som_pegar:
		som_pegar.play()
	
	var tween_animacao = null
	if sprite:
		tween_animacao = create_tween()
		tween_animacao.set_parallel(true)
		tween_animacao.tween_property(sprite, "scale", Vector3.ZERO, 0.3)
		tween_animacao.tween_property(self, "global_position", player.global_position + Vector3(0, 1.5, 0), 0.3)
		tween_animacao.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	get_tree().paused = true
	abrir_selecao_cartas()
	
	if tween_animacao:
		await tween_animacao.finished
	
	queue_free()

func abrir_selecao_cartas():
	# CORRIGIDO: Caminho correto da cena de seleção
	var selecao_scene = load("res://cenas/gui/selecao_cartas.tscn")
	
	if not selecao_scene:
		push_error("[CARTA_DROP] Cena selecao_cartas.tscn nao encontrada!")
		get_tree().paused = false
		return
	
	var selecao = selecao_scene.instantiate()
	get_tree().root.add_child(selecao)

static func spawnar_carta_na_frente_do_player(cena_carta: PackedScene, player: Node3D) -> Node3D:
	if not cena_carta or not player:
		return null
	
	var carta = cena_carta.instantiate()
	
	var direcao_frente = -player.transform.basis.z
	direcao_frente.y = 0
	direcao_frente = direcao_frente.normalized()
	
	var pos = player.global_position
	pos += direcao_frente * 3.0
	pos.y = max(player.global_position.y + 1.0, 1.0)
	
	player.get_tree().current_scene.add_child(carta)
	carta.global_position = pos
	
	return carta
