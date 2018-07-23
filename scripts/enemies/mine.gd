extends "res://scripts/enemies/base.gd"

var exploding = false


func explode():
	if disabled:
		return
	
	$AreaExplosion/AnimationPlayer.play("explode")
	for c in $AreaExplosion.get_overlapping_areas():
		if c.has_method("disrupt"):
			c.disrupt()
	_destroy()

func _explode(area):
	if disabled || exploding || !area.has_method("disrupt"):
		return
	
	$AnimationPlayer.play("armed")
	$SoundBeep.play()
	exploding = true
	yield($AnimationPlayer,"animation_finished")
	if disabled:
		return
	
	explode()

func _ready():
	$AreaExplosion.connect("area_entered",self,"_explode")
	enemy = true
