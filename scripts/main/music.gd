extends Node

var current = ""

onready var player = $AudioStreamPlayer
onready var animation = $AnimationPlayer


func change_to(new,fade_out=true):
	if (new==current):
		return
	
	if (fade_out):
		if (!animation.is_playing() || animation.get_current_animation()!="fade_out"):
			animation.play("fade_out")
		yield(animation,"animation_finished")
		animation.play("fade_in")
	else:
		animation.stop()
		player.set_volume_db(0)
	
	print("Change music to "+new+".")
	player.set_stream(load("res://music/"+new+".ogg"))
	player.play()
	current = new

func fade_out(time=1.0):
	current = ""
	animation.play("fade_out",-1,0.5/time)
	yield(animation,"animation_finished")
	player.stop()
