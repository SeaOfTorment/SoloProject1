extends Area3D

@onready var explo = $Explosion
@onready var sho = $Explosion/shockwave
var caster

# Called when the node enters the scene tree for the first time.
func _ready():
	explo.restart()
	explo.emitting = true
	sho.restart()
	sho.emitting = true

func _on_finished():
	queue_free()



func _on_body_entered(body):
	if "current_stats" in body and body.name != str(caster):
		set_deferred("monitoring", false)
		print("explosion hit %s", body.name)
