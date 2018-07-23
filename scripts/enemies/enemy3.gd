extends "res://scripts/enemies/base_enemy.gd"

var time = 0.0
var freq = 0.25
var delay_shoot = 2.75
var delta_ang = 0.05
var ammo = 4
var num_rays = 3

onready var ang = PI*randf()


func _process(delta):
	if disabled:
		return
	
	var move = Vector2(0.5*sin(freq*PI*time)*cos(freq*PI*time),0.4+0.3*abs(cos(freq*2*PI*time)))
	time += delta
	lv.x = lerp(lv.x,speed*move.x,0.1)
	lv.y = lerp(lv.y,speed*move.y,0.1)
	
	delay_shoot -= delta
	if delay_shoot<=0.0 && position.y<200:
		for i in range(num_rays):
			for j in range(ammo):
				var bi = bomb.instance()
				bi.position = position
				bi.lv = 0.2*lv
				bi.lv += Vector2(1,0).rotated(ang+2.0*PI*i/num_rays)*bomb_speed*(1.2-1.0*j/ammo)
				bi.lifetime = rand_range(8.0,9.0)+0.5*j
				$"..".add_child(bi)
			ang += delta_ang
		$SoundShoot.play()
		delay_shoot = 20.0

func _ready():
	enemy = true
