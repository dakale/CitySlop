extends Node
## Autoload singleton for managing game state.

signal resources_changed(new_amount: int)

var resources: int = 100:
	set(value):
		resources = value
		resources_changed.emit(resources)

var population: int = 0
var buildings: Array[Dictionary] = []


func _ready() -> void:
	pass


func add_building(building_data: Dictionary) -> void:
	buildings.append(building_data)


func remove_building(index: int) -> void:
	if index >= 0 and index < buildings.size():
		buildings.remove_at(index)
