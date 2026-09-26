## A [Cable] carrying [float] values, with an [member initial_value] set in the Inspector.
##
## Until something is emitted, [member Cable.current_value] is [member initial_value],
## and it's replayed to newly linked callables when [member Cable.replay_on_link] is on.
## Changes made while the game runs are never saved back to the resource.
@icon("res://addons/cables/icons/cable-icon.svg")
class_name FloatCable extends Cable

## The value this Cable holds before anything is emitted on it, and after [method Cable.reset].
@export var initial_value: float = 0.0

func _has_initial_value() -> bool:
	return true

func _get_initial_value() -> Variant:
	return initial_value
