extends Node3D

@onready var obj = $"../Marker3D/MeshInstance3D"

func _ready():
	look_at(obj.global_position)

func _process(_delta):
	look_at(obj.global_position, Vector3.UP, false)
