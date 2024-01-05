extends CharacterBody3D

@onready var camera = $Camera3D
@onready var MAIN_SCENE = $"../"
@onready var default_stats = $default_stats
@onready var current_stats = $current_stats
const ENERGY_SHOT = preload("res://assets/components/fire_ball.tscn")
const SPEED = 10.0
const JUMP_VELOCITY = 10.0
var local_id

var abilities_cd = {
	"left_click_cd" : 1.0,
	"left_click_cd_left" : 0.0,
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0

func _enter_tree():
	#pass
	#if not is_multiplayer_authority(): return
	set_multiplayer_authority(str(name).to_int())

func _ready():
	camera.current = false
	local_id = MAIN_SCENE.local_id
	for member in MAIN_SCENE.members:
		if str(member["user_id"]) == name:
			$SubViewport/MarginContainer/Label.text = member["user_name"]
	if str(local_id) != name:
		$overhead_plate.visible = true
	if not is_multiplayer_authority(): return
	stats_setup.rpc()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	$CanvasLayer.visible = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		camera.rotate_x(-event.relative.y * 0.005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _input(_event):
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("left_click"):
		rpc("shoot", local_id)
	if Input.is_action_just_pressed("quit"):
		if $CanvasLayer/settings.visible:
			$CanvasLayer/settings.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			$CanvasLayer/settings.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

@rpc("any_peer", "call_local")
func damaged(dmg, id):#idk whats going on, sends to ALL not just your mirror, questions if others do similar?
	#if not is_multiplayer_authority(): return
	#print("[%s]: [%s] damaged" % [str(local_id), name])
	if not name == id: return
	print("deduced %s" % str(dmg))
	current_stats.data["current_health"] -= dmg
	$SubViewport/ProgressBar.value = current_stats.data["current_health"]
	$CanvasLayer/ProgressBar.value = current_stats.data["current_health"]
	if current_stats.data["current_health"] == 0:
		print("dead")

@rpc("call_local")
func stats_setup():
	#print("stat_setup ran in server %s" % local_id)
	current_stats.data["current_health"] = default_stats.data["health"]
	current_stats.data["current_mana"] = default_stats.data["mana"]

@rpc("call_local")
func shoot(id):
	if abilities_cd["left_click_cd_left"] <= 0.0:
		abilities_cd["left_click_cd_left"] = abilities_cd["left_click_cd"]
		#print("%s: left_click | from: %s" % [str(local_id), str(id)])
		var energy_shot = ENERGY_SHOT.instantiate()
		energy_shot.caster = id
		MAIN_SCENE.add_child(energy_shot)
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
		#print("fixing")
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
