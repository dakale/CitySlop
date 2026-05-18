extends Node
## Autoload singleton for managing game state.

signal resources_changed(new_amount: int)
signal tick_processed(tick: int)
signal entity_placed(cell: Vector2i, entity_type: String)
signal simulation_toggled(running: bool)

var resources: int = 100:
	set(value):
		resources = value
		resources_changed.emit(resources)

var population: int = 0
var buildings: Array[Dictionary] = []
var tick_count: int = 0
var entities: Dictionary = {}  # Vector2i -> Dictionary
var simulation_running: bool = false
var placement_mode: String = ""  # Empty = no placement active


func _ready() -> void:
	pass


func advance_tick() -> void:
	tick_count += 1
	tick_processed.emit(tick_count)


func place_entity(cell: Vector2i, entity_type: String) -> void:
	if entities.has(cell):
		return
	var entity_data := {"type": entity_type, "age": 0}
	entities[cell] = entity_data
	entity_placed.emit(cell, entity_type)


func toggle_simulation() -> void:
	simulation_running = not simulation_running
	simulation_toggled.emit(simulation_running)


func add_building(building_data: Dictionary) -> void:
	buildings.append(building_data)


func remove_building(index: int) -> void:
	if index >= 0 and index < buildings.size():
		buildings.remove_at(index)
