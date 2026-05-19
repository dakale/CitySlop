extends Node
## Drives the simulation forward on a timer. Each tick ages entities and advances GameState.

@export var tick_interval: float = 0.5

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = tick_interval
	_timer.one_shot = false
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	SimulationClock.simulation_toggled.connect(_on_simulation_toggled)


func _on_simulation_toggled(running: bool) -> void:
	if running:
		_timer.start()
	else:
		_timer.stop()


func _on_tick() -> void:
	# Age all placed entities
	for cell: Vector2i in PlacementState.entities:
		PlacementState.entities[cell]["age"] += 1
	GameState.advance_tick()
