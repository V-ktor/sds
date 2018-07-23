extends "res://scripts/enemies/base_enemy.gd"

var time = 0.0
var freq = 0.25
var delay_shoot = 3.0


func _process(delta):
	if disabled:
		return
	
	var move = Vector2(0.5*sin(freq*2*PI*time),0.4+0.25*abs(cos(freq*2*PI*time)))
	time += delta
	lv.x = lerp(lv.x,speed*move.x,0.1)
	lv.y = lerp(lv.y,speed*move.y,0.1)
	
	delay_shoot -= delta
	if delay_shoot<=0.0 && position.y<200:
		var bi = bomb.instance()
		bi.position = position
		bi.lv = 0.5*lv
		if get_parent().has_node("Player"):
			bi.lv += ($"../Player".position-position).normalized()*bomb_speed
		$"..".add_child(bi)
		$SoundShoot.play()
		delay_shoot = rand_range(4.0,6.0)

func _ready():
	enemy = true
