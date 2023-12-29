extends Area3D
var speed = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#global_position += transform.basis.z * 40 * delta
	if speed > 0:
		global_position += -transform.basis.z * 150 * delta
		speed += 30
	
	

func _on_timer_timeout():
	set_deferred("monitoring", false)
	$bullet.visible = false
	$GPUParticles3D.restart()
	$GPUParticles3D.emitting = true

func _on_body_entered(body):
	if body.health and body.name != str(multiplayer.get_unique_id()):
		print("hit")
		body.health -= 25
		body.update_hp_bar.rpc()
		set_deferred("monitoring", false)
		$bullet.visible = false
		$GPUParticles3D.restart()
		$GPUParticles3D.emitting = true
		speed = 0
		


func _on_gpu_particles_3d_finished():
	queue_free()
