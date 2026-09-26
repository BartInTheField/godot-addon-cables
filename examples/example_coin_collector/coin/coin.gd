class_name Coin extends Node2D

@export var count_cable: IntCable

var _clicked := false

func _ready():
	$Body/Sprite.play("default")

func _on_character_body_2d_input_event(_viewport, event, _shape_idx):
	if not _clicked and event.is_action_pressed("left_click"):
		notify_click()

func notify_click():
	_clicked = true
	count_cable.notify(count_cable.current_value + 1)
	queue_free()
