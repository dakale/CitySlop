extends Node
## Global simulation state and control.

signal simulation_toggled(running: bool)

var simulation_running: bool = false


func _ready() -> void:
	pass


func toggle_simulation() -> void:
	simulation_running = not simulation_running
	simulation_toggled.emit(simulation_running)
