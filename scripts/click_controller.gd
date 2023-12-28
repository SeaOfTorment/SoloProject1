extends CharacterBody3D

@onready var navigation_agent = $NavigationAgent3D
@onready var camera = $Camera3D
@export var speed = 5

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	camera.current = true

func _process(delta):
	if not is_multiplayer_authority(): return
	move_to_mouse(delta)
	
func move_to_mouse(delta):
	var direction = global_position.direction_to(navigation_agent.get_next_path_position()).normalized()
	velocity = direction * speed
	move_and_slide()

func _input(event):
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("right_click"):
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_length = 100
		var ray_query = PhysicsRayQueryParameters3D.new()
		ray_query.from = camera.project_ray_origin(mouse_pos)
		ray_query.to = camera.project_ray_normal(mouse_pos) * ray_length
		var result = get_world_3d().direct_space_state.intersect_ray(ray_query)
		navigation_agent.target_position = result.position
