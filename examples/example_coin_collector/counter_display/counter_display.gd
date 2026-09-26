extends Node2D

# Not @onready: the consumer child is ready first, and a replayed score arrives before this node's _ready.
func _on_count_listener_next(value):
	$Label.text = str(value)
