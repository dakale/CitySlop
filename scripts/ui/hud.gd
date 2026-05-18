extends Control
## HUD controller. Displays resources, tick count, and simulation controls.

@onready var _resource_label: Label = $TopBar/ResourceLabel
@onready var _tick_label: Label = $TopBar/TickLabel
@onready var _sim_button: Button = $BottomBar/SimButton
@onready var _status_label: Label = $BottomBar/StatusLabel


func _ready() -> void:
	GameState.resources_changed.connect(_on_resources_changed)
	GameState.tick_processed.connect(_on_tick_processed)
	GameState.simulation_toggled.connect(_on_simulation_toggled)
	_sim_button.pressed.connect(_on_sim_button_pressed)
	_update_display()


func _update_display() -> void:
	_resource_label.text = "Resources: %d" % GameState.resources
	_tick_label.text = "Tick: %d" % GameState.tick_count
	_status_label.text = "RUNNING" if GameState.simulation_running else "PAUSED"
	_sim_button.text = "Pause" if GameState.simulation_running else "Start"


func _on_resources_changed(_amount: int) -> void:
	_update_display()


func _on_tick_processed(_tick: int) -> void:
	_update_display()


func _on_simulation_toggled(_running: bool) -> void:
	_update_display()


func _on_sim_button_pressed() -> void:
	GameState.toggle_simulation()
