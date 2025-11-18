# transicao_nivel.gd
extends CanvasLayer

@onready var fade_rect = $ColorRect
@onready var label_transicao = $LabelTransicao

@export_file("*.tscn") var proximo_nivel: String = ""
@export var mensagem_transicao: String = "Carregando próximo nível..."

var esta_em_transicao: bool = false

func _ready():
	add_to_group("transicao_nivel")
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if label_transicao:
		label_transicao.modulate.a = 0.0

func iniciar_transicao_ultima_onda():
	if esta_em_transicao or proximo_nivel.is_empty():
		return
	
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		await iniciar_transicao_com_caminhada(player)
	else:
		await fazer_transicao_direta()

func iniciar_transicao_com_caminhada(player: Node3D):
	esta_em_transicao = true
	
	if player.has_method("desabilitar_controles"):
		player.desabilitar_controles()
	
	iniciar_caminhada_automatica(player)
	await fazer_fade_out()
	mostrar_mensagem()
	await carregar_nivel(proximo_nivel)
	esconder_mensagem()

func iniciar_caminhada_automatica(player: Node3D):
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	var direcao_frente = -player.transform.basis.z
	direcao_frente.y = 0
	direcao_frente = direcao_frente.normalized()
	var destino = player.global_position + (direcao_frente * 5.0)
	
	tween.tween_property(player, "global_position", destino, 2.0).set_trans(Tween.TRANS_LINEAR)
	
	# Tocar animação de andar
	var anim_sprite = player.get_node_or_null("AnimatedSprite3D")
	if anim_sprite and anim_sprite.sprite_frames.has_animation("andando"):
		anim_sprite.play("andando")

func mostrar_mensagem():
	if not label_transicao:
		return
	
	label_transicao.text = mensagem_transicao
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label_transicao, "modulate:a", 1.0, 0.5)

func esconder_mensagem():
	if not label_transicao:
		return
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label_transicao, "modulate:a", 0.0, 0.5)

func fazer_fade_out(duracao: float = 2.0) -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", 1.0, duracao)
	await tween.finished

func fazer_fade_in(duracao: float = 1.0) -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", 0.0, duracao)
	await tween.finished
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func carregar_nivel(nivel_path: String):
	await Engine.get_main_loop().create_timer(0.5).timeout
	
	if not ResourceLoader.exists(nivel_path):
		esta_em_transicao = false
		await fazer_fade_in()
		return
	
	var cena_principal = get_tree().root.get_node_or_null("cena_principal")
	
	if not cena_principal:
		var erro = get_tree().change_scene_to_file(nivel_path)
		if erro != OK:
			esta_em_transicao = false
			return
		await Engine.get_main_loop().process_frame
		await fazer_fade_in()
		esta_em_transicao = false
		return
	
	var no_mapa = cena_principal.get_node_or_null("mapa")
	
	if not no_mapa:
		esta_em_transicao = false
		await fazer_fade_in()
		return
	
	var cenario_atual = null
	for child in no_mapa.get_children():
		if child is Node3D:
			cenario_atual = child
			break
	
	if cenario_atual:
		cenario_atual.queue_free()
	
	var novo_cenario_scene = load(nivel_path)
	
	if not novo_cenario_scene:
		esta_em_transicao = false
		await fazer_fade_in()
		return
	
	var novo_cenario = novo_cenario_scene.instantiate()
	no_mapa.add_child(novo_cenario)
	
	for i in range(5):
		await get_tree().physics_frame
	
	reposicionar_jogador(novo_cenario)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await fazer_fade_in()
	
	esta_em_transicao = false

func fazer_transicao_direta():
	esta_em_transicao = true
	await fazer_fade_out(1.0)
	mostrar_mensagem()
	await carregar_nivel(proximo_nivel)
	esconder_mensagem()

func reposicionar_jogador(novo_cenario: Node):
	var player = get_tree().get_first_node_in_group("player")
	
	if not player:
		return
	
	var spawn_point = novo_cenario.get_node_or_null("spawn_point")
	
	if spawn_point:
		player.global_position = spawn_point.global_position
	else:
		player.global_position = novo_cenario.global_position + Vector3(0, 1, 0)
	
	if player.has_method("habilitar_controles"):
		player.habilitar_controles()
