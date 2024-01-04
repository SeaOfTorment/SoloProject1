extends Area3D
var speed = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	$GPUParticles3D.restart()
	$GPUParticles3D.emitting = true
	$cast.playing = true
	$travel.playing = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#global_position += transform.basis.z * 40 * delta
	if speed > 0:
		global_position += -transform.basis.z * 150 * delta
		speed += 30
	

func _on_timer_timeout():
	set_deferred("monitoring", false)
	$GPUParticles3D.emitting = false
	speed = 0

func _on_body_entered(body):
	if "current_stats" in body and body.name != str(multiplayer.get_unique_id()):
		$hit.playing = true
		print("hit")
		body.rpc("damaged", 25)
		set_deferred("monitoring", false)
		speed = 0

func _on_gpu_particles_3d_finished():
	print("Killed particles")
	queue_free()
