extends Node2D
## Main scene entry point. Orchestrates game systems.


func _ready() -> void:
	# Start with building placement mode active so the player can place immediately
	GameState.placement_mode = "building"
