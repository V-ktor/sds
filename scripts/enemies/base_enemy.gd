extends "res://scripts/enemies/base.gd"

export (float) var speed = 100.0
export (float) var bomb_speed = 150.0

onready var frames = $Sprite.hframes*$Sprite.vframes
onready var center_frame = int(frames/2)
onready var frame = $Sprite.frame

var bomb = preload("res://scenes/weapons/bomb1.tscn")


func _process(delta):
	translate(delta*lv)
	if disabled:
		return
	
	frame += delta*7.5*sign(center_frame-frame)
	frame -= delta*10.0*center_frame*lv.x/speed
	frame = clamp(frame,0,frames-1)
	
	$Sprite.frame = round(frame)
	$SteeringLeft.modulate.a = clamp(-lv.x/speed,0.0,1.0)
	$SteeringRight.modulate.a = clamp(lv.x/speed,0.0,1.0)
	$Thrust.modulate.a = clamp(0.25+lv.y/speed,0.0,1.0)
	$ReverseThrust.modulate.a = clamp(-lv.y/speed,0.0,1.0)
