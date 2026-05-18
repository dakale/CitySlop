extends Camera2D
## Top-down camera with WASD panning and scroll zoom.

@export var pan_speed: float = 600.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0


func _process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("camera_pan_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("camera_pan_down"):
		input_dir.y += 1
	if Input.is_action_pressed("camera_pan_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("camera_pan_right"):
		input_dir.x += 1

	position += input_dir.normalized() * pan_speed * delta / zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in"):
		zoom *= 1.0 + zoom_speed
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	elif event.is_action_pressed("camera_zoom_out"):
		zoom *= 1.0 - zoom_speed
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
