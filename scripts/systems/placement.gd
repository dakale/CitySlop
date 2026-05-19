extends Node2D
## Handles mouse-click placement of entities onto the world grid.

const CELL_SIZE: int = 64

@onready var _camera: Camera2D = get_viewport().get_camera_2d()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("place_entity") and PlacementState.placement_mode != "":
		var mouse_pos := get_global_mouse_position()
		var cell := Vector2i(
			floori(mouse_pos.x / CELL_SIZE),
			floori(mouse_pos.y / CELL_SIZE)
		)
		PlacementState.place_entity(cell, PlacementState.placement_mode)
	elif event.is_action_pressed("toggle_simulation"):
		SimulationClock.toggle_simulation()
