extends Node
## Manages entity placement mode and placed entity storage.

signal entity_placed(cell: Vector2i, entity_type: String)

var placement_mode: String = ""  # Empty = no placement active
var entities: Dictionary = {}  # Vector2i -> Dictionary


func _ready() -> void:
	pass


func place_entity(cell: Vector2i, entity_type: String) -> void:
	if entities.has(cell):
		return
	var entity_data := {"type": entity_type, "age": 0}
	entities[cell] = entity_data
	entity_placed.emit(cell, entity_type)
