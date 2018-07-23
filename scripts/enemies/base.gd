extends Area2D

export (int) var hp = 10
export (int) var score = 10
var lv = Vector2()
var enemy = false

var disabled = false


func _destroy():
	if disabled:
		return
	
	disabled = true
	collision_layer = 0
	collision_mask = 0
	$"..".enemies.erase(self)
	$AnimationPlayer.play("explode")

func damaged(dmg=1,en=false):
	if en && enemy:
		return false
	hp -= dmg
	if hp<=0:
		_destroy()
	return true

func _collide(collider):
	if collider.has_method("damaged"):
		if collider.damaged(1,enemy):
			_destroy()

func _process(delta):
	translate(delta*lv)

func _ready():
	connect("area_entered",self,"_collide")
	$"..".enemies.push_back(self)
