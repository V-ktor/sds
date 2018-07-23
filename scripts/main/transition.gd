extends CanvasLayer

onready var animation = $AnimationPlayer

signal finished()


func fade_out(speed=1.0):
	animation.play("fade_out",-1,speed)
	yield(animation,"animation_finished")
	emit_signal("finished")

func fade_in(speed=1.0):
	animation.play("fade_in",-1,speed)
	yield(animation,"animation_finished")
	emit_signal("finished")
