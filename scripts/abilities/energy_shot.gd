extends Area3D

const EXPLOSION = preload("res://assets/post_components/impact_explosion.tscn")
var speed = 90
var caster
var has_exploded = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$GPUParticles3D.restart()
	$GPUParticles3D.emitting = true
	#$cast.playing = true
	$travel.playing = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#global_position += transform.basis.z * 40 * delta
	if speed > 0:
		global_position += -transform.basis.z * speed * delta
	

func _on_travel_timer_timeout():
	if not has_exploded:
		has_exploded = true
		explode()
	set_deferred("monitoring", false)
	$GPUParticles3D.emitting = false
	speed = 0
	$delete_timer.start()

func _on_delete_timer_timeout():
	#print("deleting fireball")
	queue_free()

func _on_body_entered(body):
	if "current_stats" in body and body.name != str(caster):
		set_deferred("monitoring", false)
		print("hit")
		speed = 0
		$hit.playing = true
		if multiplayer.get_unique_id() == 1:
			body.rpc("damaged", 10, body.name)
		if not has_exploded:
			has_exploded = true
			explode()
	elif not "current_stats" in body:
		set_deferred("monitoring", false)
		print("crash")
		speed = 0
		if not has_exploded:
			has_exploded = true
			explode()
		
func explode():
	var explosion = EXPLOSION.instantiate()
	explosion.caster = caster
	add_child(explosion)
	$GPUParticles3D.emitting = false
	$explosion.playing = true
	#$hit.playing = true

func _on_gpu_particles_3d_finished():
	print("Killed particles")
	queue_free()

