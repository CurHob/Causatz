extends Camera2D

@export var mouseSens := 1.0
@export_range(1.01, 2) var zoomSens := 1.3
@export var invZoom := false
var lastMouse : Vector2
var actualZoom : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	actualZoom = zoomSens if invZoom else (1.0 / zoomSens)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("WheelDown"):
		zoom *= actualZoom
	if Input.is_action_just_pressed("WheelUp"):
		zoom /= actualZoom
	if sign(position.x) > 10000 or sign(position.y) > 10000:
		position = Vector2.ZERO
	
	var mouse = get_local_mouse_position()
	#print(mouse)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		position += (lastMouse - mouse)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		position += (mouse - lastMouse) * 0.1
		return
	
	lastMouse = mouse
