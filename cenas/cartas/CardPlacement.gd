# CardPlacement.gd
extends Control

@onready var card = preload("res://cenas/cartas/cardonBoard.tscn")

func _ready():
	print(" CardPlacement pronto")
	# IMPORTANTE: Garantir que pode receber eventos de mouse
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_mouse_entered():
	Game.mouseOnPlacement = true
	print(" Mouse ENTROU na área de placement")

func _on_mouse_exited():
	Game.mouseOnPlacement = false
	print(" Mouse SAIU da área de placement")

func placeCard():
	print(" Carta colocada na área!")
	
	# Instanciar a carta visual no tabuleiro
	var cardTemp = card.instantiate()
	var projectResolution = ProjectSettings.get_setting("display/window/size/viewport_width")
	var projectResolutionHeight = ProjectSettings.get_setting("display/window/size/viewport_height")
	cardTemp.global_position = Vector2(projectResolution/2, projectResolutionHeight/2) - self.position
	add_child(cardTemp)
	
	# Efeito visual de feedback
	feedback_visual()

func feedback_visual():
	"""Efeito visual quando carta é colocada"""
	var cor_original = modulate
	modulate = Color(0.8, 1, 0.8, 1)  # Verde claro
	await get_tree().create_timer(0.2).timeout
	modulate = cor_original
