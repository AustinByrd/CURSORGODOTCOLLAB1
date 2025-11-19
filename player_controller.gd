extends CharacterBody3D
class_name PlayerController

# 3D Platformer character controller
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var acceleration: float = 10.0
@export var friction: float = 15.0
@export var air_control: float = 0.3
@export var mouse_sensitivity: float = 0.003

# Camera settings
@export var camera_pitch_limit: float = 1.4  # ~80 degrees

var camera: Camera3D
var camera_pivot: Node3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Setup camera
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	
	camera = Camera3D.new()
	camera.name = "Camera"
	camera_pivot.add_child(camera)
	camera.position = Vector3(0, 1.5, 0)  # Eye height
	
	# Lock mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate player horizontally
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera pivot vertically (pitch)
		var pitch_delta = -event.relative.y * mouse_sensitivity
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x + pitch_delta,
			-camera_pitch_limit,
			camera_pitch_limit
		)
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply movement
	if direction:
		var control = acceleration if is_on_floor() else acceleration * air_control
		velocity.x = move_toward(velocity.x, direction.x * speed, control * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, control * delta)
	else:
		var control = friction if is_on_floor() else friction * air_control
		velocity.x = move_toward(velocity.x, 0, control * delta)
		velocity.z = move_toward(velocity.z, 0, control * delta)
	
	move_and_slide()

