extends Node2D
## World manager. Draws grid and renders placed entities.

const CELL_SIZE: int = 64
const GRID_EXTENT: int = 50  # Cells in each direction from origin
const BG_COLOR := Color(0.1, 0.1, 0.12)
const GRID_COLOR := Color(0.35, 0.35, 0.4)
const ENTITY_COLOR := Color(0.2, 0.8, 0.3)
const ENTITY_AGED_COLOR := Color(0.8, 0.5, 0.1)

var _entity_nodes: Dictionary = {}  # Vector2i -> ColorRect


func _ready() -> void:
	GameState.entity_placed.connect(_on_entity_placed)
	GameState.tick_processed.connect(_on_tick_processed)


func _draw() -> void:
	var extent_px := GRID_EXTENT * CELL_SIZE
	# Dark background so grid lines are visible
	draw_rect(Rect2(-extent_px, -extent_px, extent_px * 2, extent_px * 2), BG_COLOR)
	# Grid lines
	for i: int in range(-GRID_EXTENT, GRID_EXTENT + 1):
		var offset := i * CELL_SIZE
		draw_line(Vector2(offset, -extent_px), Vector2(offset, extent_px), GRID_COLOR)
		draw_line(Vector2(-extent_px, offset), Vector2(extent_px, offset), GRID_COLOR)


func _on_entity_placed(cell: Vector2i, _entity_type: String) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
	rect.position = Vector2(cell.x * CELL_SIZE + 2, cell.y * CELL_SIZE + 2)
	rect.color = ENTITY_COLOR
	add_child(rect)
	_entity_nodes[cell] = rect


func _on_tick_processed(_tick: int) -> void:
	# Pulse entities based on age
	for cell: Vector2i in _entity_nodes:
		var rect: ColorRect = _entity_nodes[cell]
		var age: int = GameState.entities[cell]["age"]
		var t := clampf(float(age) / 20.0, 0.0, 1.0)
		rect.color = ENTITY_COLOR.lerp(ENTITY_AGED_COLOR, t)
