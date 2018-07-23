extends Node

const NEBULAS = ["nebula01.png","nebula02.png","nebula03.png","nebula04.png"]
const PLANETS = ["planet01.png","planet02.png","planet03.png","planet04.png"]

var pos = 0.0
var speed = 100.0
var dist = 5000.0
var break_dist = 2000.0
var difficulty = 0
var score = 0
var spawn_time = 2.0
var enemies = []
var scale = 1.0
var half_way = false
var pirate_raid = false
var spawn_time_multiplier = 1.0
var cargo = ""
var finished = false

onready var camera = $Camera
onready var player = $Player

var asteroid = preload("res://scenes/enemies/asteroid.tscn")
var mine = preload("res://scenes/enemies/mine.tscn")
var enemy1 = preload("res://scenes/enemies/enemy1.tscn")
var enemy2 = preload("res://scenes/enemies/enemy2.tscn")
var enemy3 = preload("res://scenes/enemies/enemy3.tscn")


func _half_way():
	if !has_node("Player"):
		return
	if randf()<0.2+0.2*difficulty-0.5*float(pirate_raid):
		pirate_raid = true
		spawn_time_multiplier = 0.5*min((dist-pos)/6000.0,1.0)
		spawn_time += 5.0
		Music.change_to("battle")
		if randf()<0.5:
			$UI.add_text("ENEMIES_INCOMMING_"+str(randi()%6+1),true,true,20.0,2.0)
		if randf()<0.85:
			$UI.add_text("PIRATE_TAUNT_"+str(randi()%5+1),false,true,20.0,1.5)
			if cargo=="AIR" || cargo=="EMPTY_CARGO_CONTAINERS":
				$UI.add_text("RESPOND_PIRATE_"+str(randi()%4+1),true,true,20.0,2.0)
				$UI.add_text("RESPOND_CARRY_WORTHLESS_1",true,true,20.0,3.0)
				$UI.add_text(tr("RESPOND_CARRY_WORTHLESS_2")%tr(cargo))
			elif randf()<0.3:
				$UI.add_text("RESPOND_PIRATE_"+str(randi()%4+1),true,true,20.0,2.0)
				$UI.add_text("PIRATE_TAUNT_"+str(randi()%2+8),false)
			else:
				$UI.add_text("RESPOND_PIRATE_"+str(randi()%4+1))
		else:
			$UI.add_text("PIRATE_TAUNT_"+str(randi()%2+6),false,true,20.0,1.5)
			$UI.add_text("RESPOND_PIRATE_"+str(randi()%3+5))
	elif difficulty>0 && randf()<0.5:
		var rnd = randf()
		pirate_raid = false
		if $Player.hp<$Player.hp/2 && randf()<0.6:
			if rnd<0.25:
				$UI.add_text("SWISS_CHEESED_ARMOR")
			elif rnd<0.5:
				$UI.add_text("SHIP_DAMAGED")
			elif rnd<0.75:
				$UI.add_text("THAT_WAS_CLOSE")
			else:
				$UI.add_text("MORE_CAREFULL")
		else:
			if randf()<0.75:
				Music.change_to("exploration")
			if rnd<0.25:
				$UI.add_text("EXPLODING_ENEMIES_1")
				$UI.add_text("EXPLODING_ENEMIES_2")
			elif rnd<0.5:
				$UI.add_text("SHOOTING_AT_ME")
			elif rnd<0.75:
				$UI.add_text("TROUBLE_WITH_PIRATES")
			else:
				$UI.add_text("PIRATES_1",true,true,20.0,3.0)
				$UI.add_text("PIRATES_"+str(randi()%3+2))
	else:
		var rnd = randf()
		pirate_raid = false
		Music.change_to("exploration")
		if rnd<0.2:
			$UI.add_text("COURIER_PIRATES_1",true,true,20.0,3.0)
			$UI.add_text("COURIER_PIRATES_"+str(randi()%3+2))
		elif rnd<0.15 && pos/dist>0.4 && pos/dist<0.6:
			$UI.add_text("SHRINK_GALAXY_1",true,true,20.0,3.0)
			$UI.add_text("SHRINK_GALAXY_"+str(randi()%3+2))
		else:
			$UI.add_text("HALF_WAY_"+str(randi()%6+1))
	
	if break_dist<0.35*dist:
		break_dist = max(rand_range(0.625,0.7)*dist-1000,rand_range(1250,1750))
		if pirate_raid && break_dist-pos>rand_range(4000,6000):
			break_dist = min(rand_range(4000,6000)+pos,break_dist)
		half_way = false
		printt(pos,dist,break_dist)

func _process(delta):
	pos += delta*speed
	$UI/Left/Progress.value = pos
	$UI/Left/Progress.max_value = dist
	for c in $Background.get_children():
		c.region_rect = Rect2(Vector2(0,-0.3*pos),OS.window_size)
	$Background/Planet.position.y += 0.4*delta*speed
	$Background/Sun.position.y += 0.4*delta*speed
	$UI/Left/Score.text = tr("SCORE")+": "+str(score)
	
	if pos>=dist:
		if !finished:
			if enemies.size()>0:
				for e in enemies:
					if e.position.y>384 || e.disabled:
						e.queue_free()
						enemies.erase(e)
			elif has_node("Player") && !$Player.disabled:
				$"/root/Menu".finished(score)
				finished = true
		return
	
	spawn_time -= delta
	if spawn_time<=0.0 && dist-pos>500.0:
		var rnd = randf()*(0.7+0.5*difficulty+0.6*float(pirate_raid))+0.3*float(pirate_raid)
		for e in enemies:
			if e.position.y>512:
				e.queue_free()
				enemies.erase(e)
		if rnd<0.1:
			for i in range(int(rand_range(1,6.5))):
				var mi = mine.instance()
				mi.position = Vector2(rand_range(-256,256),rand_range(-512,-640))
				mi.lv = Vector2(rand_range(-8,8),rand_range(96,32))*rand_range(0.8,1.1)
				mi.hp += floor(0.75*difficulty)
				add_child(mi)
		elif rnd<0.6:
			var ai = asteroid.instance()
			ai.position = Vector2(rand_range(-320,320),rand_range(-512,-640))
			ai.lv = Vector2(rand_range(-48,48),rand_range(192,64))*rand_range(0.8,1.1)
			ai.hp += difficulty
			add_child(ai)
		elif rnd<1.3:
			var ei = enemy1.instance()
			ei.position = Vector2(rand_range(-192,192),rand_range(-512,-640))
			ei.lv = Vector2(rand_range(-48,48),rand_range(192,-64))*rand_range(0.8,1.1)
			ei.freq = rand_range(0.1,0.4)
			ei.time = randf()*2.0*PI/ei.freq
			ei.delay_shoot *= rand_range(0.75,2.0)
			ei.hp += floor(1.5*(difficulty-1))
			add_child(ei)
		elif rnd<1.6:
			var ei = enemy2.instance()
			ei.position = Vector2(rand_range(-256,256),rand_range(-512,-640))
			ei.lv = Vector2(rand_range(-48,48),rand_range(192,-64))*rand_range(0.8,1.1)
			ei.freq = rand_range(0.05,0.75)*rand_range(0.25,0.5)
			ei.time = randf()*2.0*PI/ei.freq
			ei.delay_shoot *= rand_range(0.75,1.5)
			ei.hp += 2*(difficulty-1)
			ei.ammo = randi()%3+4
			add_child(ei)
		elif rnd<2.0:
			for i in range(int(rand_range(4,9.5))):
				var mi = mine.instance()
				mi.position = Vector2(rand_range(-256,256),rand_range(-512,-640))
				mi.lv = Vector2(rand_range(-8,8),rand_range(96,32))*rand_range(0.8,1.1)
				mi.hp += floor(0.75*difficulty)
				add_child(mi)
		else:
			var ei = enemy3.instance()
			ei.position = Vector2(rand_range(-192,192),rand_range(-512,-640))
			ei.lv = Vector2(rand_range(-32,32),rand_range(192,-64))*rand_range(0.8,1.1)
			ei.freq = rand_range(0.5,0.75)
			ei.time = randf()*2.0*PI/ei.freq
			ei.delay_shoot *= rand_range(0.75,2.0)
			ei.hp += floor(1.5*(difficulty-1))
			ei.ammo = randi()%4+4
			add_child(ei)
		if !half_way && pos>break_dist:
			var timer = Timer.new()
			timer.set_one_shot(true)
			timer.set_wait_time(7.0)
			add_child(timer)
			timer.connect("timeout",self,"_half_way")
			timer.start()
			half_way = true
			spawn_time = 8.0
		else:
			spawn_time = (rand_range(0.1,1.5)+enemies.size()*rand_range(0.01,0.1))*rand_range(0.75,1.2)*(0.5+0.2*max(3-difficulty,1))*spawn_time_multiplier

func _resized():
	scale = max((OS.get_window_size().x-200)/400.0,OS.get_window_size().y/400.0)
	camera.set_zoom(2.0/round(scale)*Vector2(1,1))

func _ready():
	var timer = Timer.new()
	get_tree().connect("screen_resized",self,"_resized")
	_resized()
	$Background/Nebula.set_texture(load("res://images/background/"+NEBULAS[randi()%NEBULAS.size()]))
	$Background/Planet.set_texture(load("res://images/background/"+PLANETS[randi()%PLANETS.size()]))
	$Background/Planet.position = Vector2(round(rand_range(-512,512)),round(rand_range(-2048,512)))
	$Background/Sun.position = Vector2(round(rand_range(-512,512)),round(rand_range(-4096,512)))
	if randf()<0.5:
		$Background/Sun.hide()
	
	if dist>rand_range(12000,20000):
		break_dist = rand_range(0.275,0.35)*dist-1000
	elif dist>rand_range(6000,9000):
		break_dist = rand_range(0.45,0.5)*dist-1000
	else:
		break_dist = dist
		half_way = true
	printt(pos,dist,break_dist)
	
	timer.set_one_shot(true)
	timer.set_wait_time(0.5)
	add_child(timer)
	timer.start()
	yield(timer,"timeout")
	if randf()<0.75:
		if cargo=="PLUTONIUM":
			$UI.add_text("DELIVERY_PLUTONIUM")
			spawn_time += 2.0
		elif cargo=="ICE_CREAM" || cargo=="PARFAIT":
			$UI.add_text("DELIVERY_ICE_CREAM_1")
			$UI.add_text("DELIVERY_ICE_CREAM_2",true,true,20.0,2.0)
			$UI.add_text("DELIVERY_ICE_CREAM_"+str(randi()%2+3))
			spawn_time += 5.0
		elif cargo=="FISH" || cargo=="CHEESE" || cargo=="SWISS_CHEESE":
			$UI.add_text("DELIVERY_SMELL")
			spawn_time += 2.0
		elif cargo=="PIZZA":
			$UI.add_text("DELIVERY_PIZZA")
			spawn_time += 2.0
		elif cargo=="LOVE_LETTER":
			$UI.add_text("DELIVERY_LOVE_LETTER")
			spawn_time += 2.0
		elif cargo=="ANTIBIOTICS" || cargo=="MEDICINE" || cargo=="MEDICAL_SUPPLIES":
			$UI.add_text(tr("DELIVERY_MEDICINE_1")%get_node("/root/Menu").selected_system.name,true,true,20.0,3.0)
			$UI.add_text("DELIVERY_MEDICINE_"+str(randi()%3+2))
			spawn_time += 5.0
		elif cargo=="SYRINGES":
			$UI.add_text("DELIVERY_SYRINGES")
			spawn_time += 2.0
		elif cargo=="BAROMETERS":
			$UI.add_text("DELIVERY_BAROMETERS")
			spawn_time += 2.0
		elif cargo=="VACUUM_CHAMBERS":
			$UI.add_text("DELIVERY_VACUUM_CHAMBERS")
			spawn_time += 2.0
		elif cargo=="ALIVE_RODENTS":
			$UI.add_text("DELIVERY_ALIVE_RODENTS")
			spawn_time += 2.0
		elif cargo=="AIR":
			$UI.add_text("DELIVERY_AIR_"+str(randi()%2+1))
			spawn_time += 2.0
		elif cargo=="SCHRÖDINGERS_CATS":
			$UI.add_text("DELIVERY_SCHRÖDINGERS_CAT")
			spawn_time += 2.0
		elif cargo=="BLACKBOX":
			$UI.add_text("DELIVERY_BLACKBOX")
			spawn_time += 2.0
		elif cargo=="WOLF_GOAT_CABBAGE":
			$UI.add_text("DELIVERY_WOLF_GOAT_CABBAGE")
			spawn_time += 2.0
		elif cargo=="PANDORAS_CUBE":
			$UI.add_text("DELIVERY_PANDORAS_CUBE")
			spawn_time += 2.0
		elif cargo=="SCIENTIFIC_DEVICES":
			var array = [
				"ENTROPY_INVERTER","AM_CONVERTER","QUANTUM_COMPUTER","PLASMA_TRASH_VAPORISER",
				"BRAIN_STIMULATOR","TELEPORTER","LASER_PULSE_CANNON","LIGHT_SABER"]
			var text = tr("DELIVERY_SCIENTIFIC_DEVICES_2")
			for i in range(3):
				var rnd = randi()%array.size()
				text = text.replace("%s"+str(i+1),tr(array[rnd]))
				array.remove(i)
			$UI.add_text("DELIVERY_SCIENTIFIC_DEVICES_1",true,true,20.0,3.0)
			$UI.add_text(text,true,true,20.0,3.0)
			$UI.add_text("DELIVERY_SCIENTIFIC_DEVICES_3")
			spawn_time += 7.0
		else:
			default_message()
	else:
		default_message()
	
	timer.set_wait_time(2.0)
	timer.start()
	yield(timer,"timeout")
	if difficulty>int(rand_range(1.5,2.5)):
		Music.change_to("battle")
	else:
		Music.change_to("exploration")

func default_message():
	var rnd = randf()
	if rnd<0.15:
		$UI.add_text("COURIER_PIRATES_1",true,true,20.0,3.0)
		$UI.add_text("COURIER_PIRATES_"+str(randi()%3+2))
		spawn_time += 4.0
	else:
		$UI.add_text("DELIVERY_START_"+str(randi()%7+1))
		spawn_time += 2.0
