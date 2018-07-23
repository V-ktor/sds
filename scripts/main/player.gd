extends Area2D

var hp = 2
var max_hp = 2
var sp = 1
var max_sp = 1
var energy = 0
var weapon_energy = 1
var engine_energy = 1
var shield_energy = 0
var max_weapon_energy = 1
var max_engine_energy = 1
var max_shield_energy = 1
var x_min = -275
var x_max = 275
var y_min = -50
var y_max = 225

var base_fire_rate = 1.5
var base_speed = 275.0
var base_reload = 0.1

var lv = Vector2()
var delay_shoot = 0.0
var disabled = false

onready var frames = $Sprite.hframes*$Sprite.vframes
onready var center_frame = int(frames/2)
onready var frame = $Sprite.frame

var shot = preload("res://scenes/weapons/shot1.tscn")


func _destroy():
	if disabled:
		return
	
	disabled = true
	collision_layer = 0
	collision_mask = 0
	set_process(false)
	$AnimationPlayer.play("explode")
	$"../UI/Right/VBoxContainer/HP".value = 0
	yield($AnimationPlayer,"animation_finished")
	$"/root/Menu".failed()

func damaged(dmg=1,en=false):
	if sp>=1:
		sp = floor(sp-dmg)
		if sp<0:
			dmg = -ceil(sp)
		else:
			return true
	else:
		sp = 0
	hp -= dmg
	if hp<=0:
		_destroy()
	$SoundImpact.play()
	return true

func disrupt(dmg=1):
	var delta_en = 0
	var timer = Timer.new()
	timer.set_one_shot(true)
	timer.set_wait_time(10.0)
	add_child(timer)
	if sp>=1:
		sp = floor(sp-dmg)
	else:
		sp = 0
	for i in range(dmg):
		delta_en += 1
		if energy>0:
			energy -= 1
		elif shield_energy>0:
			shield_energy -= 1
		elif engine_energy>1:
			engine_energy -= 1
		elif weapon_energy>0:
			weapon_energy -= 1
		elif engine_energy>0:
			engine_energy -= 1
		else:
			delta_en -= 1
			break
	
	update_energy_usage()
	timer.start()
	yield(timer,"timeout")
	energy += delta_en
	update_energy_usage()

func change_dist(type,inc):
	var current = get(type+"_energy")
	if (current==0 && inc<0) || (current+inc>get("max_"+type+"_energy") && inc>0):
		return false
	
	while energy<inc:
		if shield_energy>0 && type!="shield" && shield_energy>=weapon_energy && shield_energy>=engine_energy:
			shield_energy -= 1
			energy += 1
		elif weapon_energy>0 && type!="weapon" && weapon_energy>=shield_energy && weapon_energy>=engine_energy:
			weapon_energy -= 1
			energy += 1
		elif engine_energy>0 && type!="engine":
			engine_energy -= 1
			energy += 1
		else:
			return false
	
	set(type+"_energy",current+inc)
	energy -= inc
	update_energy_usage()
	return true

func update_energy_usage():
	for i in range(1,min(weapon_energy+1,5)):
		get_node("../UI/Right/Energy/HBoxContainer/Weapon/Arrow"+str(i)).show()
	for i in range(weapon_energy+1,5):
		get_node("../UI/Right/Energy/HBoxContainer/Weapon/Arrow"+str(i)).hide()
	for i in range(1,min(shield_energy+1,5)):
		get_node("../UI/Right/Energy/HBoxContainer/Shield/Arrow"+str(i)).show()
	for i in range(shield_energy+1,5):
		get_node("../UI/Right/Energy/HBoxContainer/Shield/Arrow"+str(i)).hide()
	for i in range(1,min(engine_energy+1,5)):
		get_node("../UI/Right/Energy/HBoxContainer/Engine/Arrow"+str(i)).show()
	for i in range(engine_energy+1,5):
		get_node("../UI/Right/Energy/HBoxContainer/Engine/Arrow"+str(i)).hide()
	$"../UI/Right/Energy/Energy".value = energy
	$"../UI/Right/Energy/Energy".max_value = energy+weapon_energy+shield_energy+engine_energy

func shoot():
	delay_shoot += 1.0
	for i in range(1,3):
		var si = shot.instance()
		si.lv = Vector2(0,-2000)
		si.global_position = get_node("Gun"+str(i)).global_position
		$"..".add_child(si)
	$SoundShoot.play()

func _process(delta):
	var move = Vector2(float(Input.is_action_pressed("move_right"))-float(Input.is_action_pressed("move_left")),float(Input.is_action_pressed("move_down"))-float(Input.is_action_pressed("move_up"))).normalized()
	var speed = base_speed*(0.2+0.5*engine_energy)
	var reload_rate = base_fire_rate*(0.2+1.0*weapon_energy)
	var sr = base_reload*shield_energy
	var msp = max_sp+shield_energy
	
	lv.x = lerp(lv.x,speed*move.x,0.1)
	lv.y = lerp(lv.y,speed*move.y,0.1)
	translate(delta*lv)
	if position.x<x_min:
		position.x = x_min
	elif position.x>x_max:
		position.x = x_max
	if position.y<y_min:
		position.y = y_min
	elif position.y>y_max:
		position.y = y_max
	
	sp = sp+delta*sr
	if sp>=msp:
		sp = msp
	if delay_shoot>0.0:
		delay_shoot -= delta*reload_rate
	if delay_shoot<=0 && Input.is_action_pressed("shoot"):
		shoot()
	
	frame += delta*7.5*sign(center_frame-frame)
	frame -= delta*10.0*center_frame*lv.x/speed
	frame = clamp(frame,0,frames-1)
	
	$Sprite.frame = round(frame)
	$SteeringLeft.modulate.a = clamp(-lv.x/speed,0.0,1.0)
	$SteeringRight.modulate.a = clamp(lv.x/speed,0.0,1.0)
	$Thrust.modulate.a = clamp(0.25-lv.y/speed,0.0,1.0)
	$ReverseThrust.modulate.a = clamp(lv.y/speed,0.0,1.0)
	
	$"../UI/Right/VBoxContainer/HP".value = hp
	$"../UI/Right/VBoxContainer/HP".max_value = max_hp
	$"../UI/Right/VBoxContainer/SP".value = floor(sp)
	$"../UI/Right/VBoxContainer/SP".max_value = msp
	$"../UI/Right/VBoxContainer/Delay".value = 1.0-delay_shoot

func _input(event):
	if event.is_action_pressed("inc_weapon"):
		change_dist("weapon",1)
	elif event.is_action_pressed("dec_weapon"):
		change_dist("weapon",-1)
	elif event.is_action_pressed("inc_shield"):
		change_dist("shield",1)
	elif event.is_action_pressed("dec_shield"):
		change_dist("shield",-1)
	elif event.is_action_pressed("inc_engine"):
		change_dist("engine",1)
	elif event.is_action_pressed("dec_engine"):
		change_dist("engine",-1)
	

func _ready():
	set_process_input(true)
	change_dist("weapon",0)
