extends Control



@onready var card = preload("res://cenas/cartas/cardonBoard.tscn")
@onready var Game = preload("res://cenas/cartas/Game.gd").new()

func _on_mouse_entered():
	Game.mouseOnPlacement = true


func _on_mouse_exited():
	Game.mouseOnPlacement = false



func placeCard():
	var cardTemp = card.instantiate()
	var projectResolution = ProjectSettings.get_setting("display/window/size/viewport_width")
	var projectResolutionHeight = ProjectSettings.get_setting("display/window/size/viewport_height")
	cardTemp.global_position = Vector2(projectResolution/2, projectResolutionHeight/2) - self.position
	add_child(cardTemp)
