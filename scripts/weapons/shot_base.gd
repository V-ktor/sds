extends Node2D

export (int) var dmg = 2
export (float) var lifetime = 0.25
export (bool) var enemy = false
var lv = Vector2(0,0)
var disabled = false

onready var raycast = $RayCast


func _destroy(impact=false):
	if disabled:
		return

	disabled = true
	raycast.enabled = false
	if impact:
		$AnimationPlayer.play("impact")
	else:
		$AnimationPlayer.play("fade_out")

func _physics_process(delta):
	var pos = position
	var _lv = lv
	if $"..".has_meta("lv"):
		_lv += $"..".lv
	translate(delta*_lv)
	raycast.set_cast_to(pos-position)
	
	if raycast.is_colliding() && raycast.get_collider()!=null:
		position = raycast.get_collision_point()
		if raycast.get_collider().has_method("damaged"):
			raycast.get_collider().damaged(dmg)
			if !enemy && raycast.get_collider().disabled:
				$"..".score += raycast.get_collider().score
		lv = raycast.get_collider().lv
		_destroy(true)

func _ready():
	var timer = Timer.new()
	timer.set_one_shot(true)
	timer.set_wait_time(lifetime)
	add_child(timer)
	timer.connect("timeout",self,"_destroy",[false])
	timer.start()
