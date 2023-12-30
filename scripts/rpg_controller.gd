extends CharacterBody3D

@onready var camera = $Camera3D
const ENERGY_SHOT = preload("res://assets/components/energy_shot.tscn")
const SPEED = 10.0
const JUMP_VELOCITY = 10.0
var health = 100

var abilities_cd = {
	"left_click_cd" : 1.0,
	"left_click_cd_left" : 0.0,
	}


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0

func _enter_tree():
	if not is_multiplayer_authority(): return
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		camera.rotate_x(-event.relative.y * 0.005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _input(_event):
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("left_click"):
		shoot.rpc()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

@rpc("call_local")
func update_hp_bar():
	$SubViewport/ProgressBar.value = health
	$CanvasLayer/ProgressBar.value = health
	if health == 0:
		print("dead")
		
@rpc("call_local")
func shoot():
	if abilities_cd["left_click_cd_left"] <= 0.0:
		abilities_cd["left_click_cd_left"] = abilities_cd["left_click_cd"]
		print(name + ": left_click")
		var energy_shot = ENERGY_SHOT.instantiate()
		$"../".add_child(energy_shot)
		energy_shot.global_position = global_position
		energy_shot.rotation_degrees = camera.global_rotation_degrees
		
@rpc("call_local")
func share_cds():
	abilities_cd["left_click_cd_left"] = int(0)

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	#cds
	if abilities_cd["left_click_cd_left"] > 0.0:
		abilities_cd["left_click_cd_left"] -= delta
	elif abilities_cd["left_click_cd_left"] < 0.0:
		print("fixing")
		abilities_cd["left_click_cd_left"] = int(0)
		share_cds.rpc()
		
		#print("fixed - " abilities_cd["left_click_cd_left"] - 0.0)
		#$arrow.scale = Vector3(0.1, 0.1, 0.1)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
