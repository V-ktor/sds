extends "res://scripts/enemies/base.gd"

var av = rand_range(-0.1,0.1)


func _process(delta):
	rotate(delta*av)

func _ready():
	var speed = 1.0
	if randf()<0.5:
		speed = -1.0
	$AnimationRotate.play("rotate",-1,speed)
	rotation = 2*PI*randf()
