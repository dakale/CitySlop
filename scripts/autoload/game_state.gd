extends Node
## Autoload singleton for managing economy and game counters.

signal resources_changed(new_amount: int)
signal tick_processed(tick: int)

var resources: int = 100:
	set(value):
		resources = value
		resources_changed.emit(resources)

var population: int = 0
var buildings: Array[Dictionary] = []
var tick_count: int = 0


func _ready() -> void:
	pass


func advance_tick() -> void:
	tick_count += 1
	tick_processed.emit(tick_count)


func add_building(building_data: Dictionary) -> void:
	buildings.append(building_data)


func remove_building(index: int) -> void:
	if index >= 0 and index < buildings.size():
		buildings.remove_at(index)
