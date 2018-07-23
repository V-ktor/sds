extends CanvasLayer

const ACTIONS = ["move_up","move_down","move_left","move_right","shoot","inc_weapon","dec_weapon","inc_shield","dec_shield","inc_engine","dec_engine"]
const NUM_SYSTEMS = 20
const SECURITY = ["SAFE","MODERATE","LOW","DANGER"]
const SECURITY_COLOR = [Color(0.0,0.9,0.2),Color(0.5,0.6,0.1),Color(0.9,0.3,0.0),Color(0.5,0.0,0.0)]
const CARGO = [
"PACKAGE","PACKAGE","PACKAGES","PACKAGES","CRATES","CRATES",
"CRATE","BOX","CHEST",
"CARGO_BOXES","CARGO_BOXES","BARREL","BARRELS",
"LETTERS","LOVE_LETTER","TOP_SECRET_DOCUMENTS",
"TUNGSTEN","GOLD_BARS","PLUTONIUM","DIAMONDS",
"FISH","CHEESE","SWISS_CHEESE","PIZZAS","WATER_TANKS","ICE_CREAM","PARFAIT",
"CRUDE_OIL","BAROMETERS","LUXURY_GOODS",
"ANTIBIOTICS","MEDICINE","MEDICAL_SUPPLIES","SYRINGES",
"ALIVE_RODENTS","AIR","SCHRÖDINGERS_CAT",
"EMPTY_CARGO_CONTAINERS","VACUUM_CHAMBERS","BLACKBOX",
"SCIENTIFIC_DEVICES","SCIENTIFIC_DEVICES","DATA_CUBE","DATA_CUBES",
"PANDORAS_CUBE","WOLF_GOAT_CABBAGE"]
const CARGO_NO_UNIT = [
"PACKAGE","PACKAGES","CRATE","CRATES","BARREL","EMPTY_CARGO_CONTAINERS","LOVE_LETTER",
"VACUUM_CHAMBERS","BARRELS","SCHRÖDINGERS_CAT","BLACKBOX","PANDORAS_CUBE",
"PIZZAS","WATER_TANKS","ALIVE_RODENTS","TOP_SECRET_DOCUMENTS","WOLF_GOAT_CABBAGE",
"DATA_CUBE","DATA_CUBES","BOX","CHEST"
]
const CARGO_SINGLE = [
"PACKAGE","CRATE","CARGO_BOX","BARREL","LOVE_LETTER","SCHRÖDINGERS_CAT","BLACKBOX",
"WOLF_GOAT_CABBAGE","CRUDE_OIL","PANDORAS_CUBE","DATA_CUBE","BOX","CHEST"
]
const CARGO_PREFIX = [
"CRATE","CRATES","PIZZAS","ICE_CREAM","PARFAIT","CHEESE","BOX","CHEST"
]
const PREFIXES = [
"SPACE","MEGA","HYPER","CYBER"
]
const MAX_UPG = 3
const MAX_POWER = 4
const UPGRADES = ["energy","weapon","shield","engine","armor","drive"]

var map = []
var selected_system
var current_system
var started = false

var credits = 0
var upg_energy = 0
var upg_weapon = 0
var upg_shield = 0
var upg_engine = 0
var upg_armor = 0
var upg_drive = 0
var num_delivered = 0

var window_size = Vector2(1024,600)
var fullscreen = false
var maximized = true
var music = true
var music_volume = 100
var sound = true
var sound_volume = 100
var keybinds = {}
var current_action = ""
var current_event

var level = preload("res://scenes/main/level.tscn")


class System:
	var name
	var pos
	var difficulty
	var reward
	var desc
	var cargo
	
	func _init(nm,p,d,r,dc,c):
		name = nm
		pos = p
		difficulty = d
		reward = r
		desc = dc
		cargo = c
	
	func to_dict():
		return {"name":name,"pos_x":pos.x,"pos_y":pos.y,"difficulty":difficulty,"reward":reward,"desc":desc,"cargo":cargo}


func _start():
	if selected_system==null:
		return
	
	var li = level.instance()
	var player = li.get_node("Player")
	var energy = upg_energy+floor(upg_drive/3)
	if has_node("/root/Level"):
		$"/root/Level".queue_free()
		$"/root/Level".name = "deleted"
	li.name = "Level"
	li.dist = current_system.pos.distance_to(selected_system.pos)*50
	li.difficulty = selected_system.difficulty
	li.cargo = selected_system.cargo
	li.speed *= 1.0+0.1*min(upg_drive,2)
	player.max_weapon_energy = min(1+upg_weapon,MAX_POWER)
	player.max_shield_energy = min(1+upg_shield,MAX_POWER)
	player.max_engine_energy = min(1+upg_engine,MAX_POWER)
	player.weapon_energy = min(floor((2+energy)/2),player.max_weapon_energy)
	player.engine_energy = min(ceil((2+energy)/3),player.max_engine_energy)
	player.shield_energy = min(floor((2+energy)/6),player.max_shield_energy)
	player.energy = 2+energy-player.weapon_energy-player.engine_energy-player.shield_energy
	if player.energy>0 && player.shield_energy<player.max_shield_energy:
		player.shield_energy += 1
		player.energy -= 1
	if player.energy>0 && player.weapon_energy<player.max_weapon_energy:
		player.weapon_energy += 1
		player.energy -= 1
	if player.energy>0 && player.engine_energy<player.max_engine_energy:
		player.engine_energy += 1
		player.energy -= 1
	player.max_hp += min(upg_armor,2)
	player.hp += min(upg_armor,2)
	if upg_weapon>2:
		player.base_fire_rate *= 1.2
	if upg_shield>2:
		player.base_reload *= 1.2
	if upg_engine>2:
		player.base_speed *= 1.2
	if upg_armor>2:
		player.sp += 1
		player.max_sp += 1
	_save()
	Transition.fade_out()
	yield(Transition,"finished")
	hide()
	get_tree().get_root().add_child(li)
	Transition.fade_in()
	started = true

func finished(score):
	if selected_system==null:
		return
	
	current_system = selected_system
	selected_system = null
	current_system.desc = tr("CURRENT_SYSTEM")
	credits += current_system.reward+score
	num_delivered += 1
	_save()
	Transition.fade_out(0.5)
	yield(Transition,"finished")
	if has_node("/root/Level"):
		$"/root/Level".queue_free()
		$"/root/Level".name = "deleted"
	show()
	_show_map()
	Transition.fade_in()
	Music.change_to("menu")
	$Result/Panel/VBoxContainer/Title.text = tr("MISSION_ACCOMPLISHED")
	if current_system.cargo in CARGO_SINGLE:
		$Result/Panel/VBoxContainer/Label.text = tr("RECEIVED_REWARD").format({"cargo":tr(current_system.cargo),"is":tr("IS"),"payment":str(current_system.reward+score)+" "+tr("CREDITS")})
	else:
		$Result/Panel/VBoxContainer/Label.text = tr("RECEIVED_REWARD").format({"cargo":tr(current_system.cargo),"is":tr("ARE"),"payment":str(current_system.reward+score)+" "+tr("CREDITS")})
	$Result.show()
	started = false

func failed():
	Transition.fade_out(0.25)
	yield(Transition,"finished")
	if has_node("/root/Level"):
		$"/root/Level".queue_free()
		$"/root/Level".name = "deleted"
	show()
	_show_map()
	Transition.fade_in()
	Music.change_to("menu")
	$Result/Panel/VBoxContainer/Title.text = tr("MISSION_FAILED")
	$Result/Panel/VBoxContainer/Label.text = tr("MISSION_FAILED_TEXT")%current_system.name
	$Result.show()
	started = false

func show():
	$Panel.show()

func hide():
	for c in get_children():
		if c.has_method("hide"):
			c.hide()


func randomize_system():
	if current_system!=null:
		map = [current_system]
	else:
		map = []
	
	for i in range(int(NUM_SYSTEMS*rand_range(0.8,1.2))):
		var s
		var pos
		var reward
		var difficulty = randi()%4
		var dist = 0
		var desc = tr("DELIVERY_"+str(randi()%4+1))
		var ammount = str(randi()%20+2)
		var cargo = CARGO[randi()%CARGO.size()]
		var name = Names.get_name()
		var cargo_str = tr(cargo)
		if (cargo in CARGO_SINGLE) && (cargo in CARGO_NO_UNIT):
			ammount = tr("A")
		elif !(cargo in CARGO_NO_UNIT):
			ammount = str(int(rand_range(1.5,6.5)))+"t"+tr("OF")
		while dist<4096:
			pos = Vector2(int(rand_range(0,$Map/Background/Control.rect_size.x-128)),int(rand_range(0,$Map/Background/Control.rect_size.y-32)))
			dist = 8192
			for sy in map:
				var d = pos.distance_squared_to(sy.pos)+1000.0/max(abs(pos.x-sy.pos.x)-abs(pos.y-sy.pos.y),1)
				if d<=dist:
					dist = d
		reward = current_system.pos.distance_to(pos)
		reward = int((0.05*reward*sqrt(reward)+150)*(1.5+difficulty+max(difficulty-1.5,0))*rand_range(0.4,0.5))
		if (cargo in CARGO_PREFIX) && randf()<0.5:
			cargo_str = tr(PREFIXES[randi()%PREFIXES.size()])+" "+tr(cargo)
		s = System.new(name,pos,difficulty,reward,desc.format({"ammount":ammount,"cargo":cargo_str,"destination":name}),cargo)
		map.push_back(s)
	
	update_map()

func upg_cost(type,level):
	var cost = 200*(level+1)*(level+1)
	if type=="energy":
		cost *= 2
	elif type=="armor":
		cost *= 1.5
	elif type=="weapon":
		cost *= 1.25
	elif type=="drive":
		cost *= 1.75
	return cost

func _upgrade(type):
	var level = get("upg_"+type)
	var cost = upg_cost(type,level)
	if credits<cost || level>=MAX_UPG:
		return
	
	credits -= cost
	set("upg_"+type,level+1)
	show_upgrades()

func _downgrade(type):
	var level = get("upg_"+type)
	if level<1:
		return
	
	var cost = upg_cost(type,level-1)
	credits += cost
	set("upg_"+type,level-1)
	show_upgrades()


func _show_options():
	revert_settings()
	$Options.show()

func _show_add_keybind(action):
	current_action = action
	current_event = null
	$Options/AddKey/VBoxContainer/Label.text = tr("ADD_KEYBIND")%action
	$Options/AddKey/VBoxContainer/Key.text = ""
	$Options/AddKey.show()
	$Options/Block.show()

func _hide_add_keybind():
	$Options/AddKey.hide()
	$Options/Block.hide()

func _show_map():
	randomize_system()
	update_map()
	show_map()

func show_map():
	$Map.show()
	$Map/Upgrades.hide()
	if selected_system!=null:
		$Map/System.show()
	$Map/HBoxContainer/Button3.text = tr("UPGRADES")
	$Map/VBoxContainer/Credits.text = tr("CREDITS")+": "+str(credits)
	$Map/VBoxContainer/Delivered.text = tr("DELIVERED")+": "+str(num_delivered)

func show_upgrades():
	$Map.show()
	for s in UPGRADES:
		var level = get("upg_"+s)
		var cost = upg_cost(s,level)
		get_node("Map/Upgrades/ScrollContainer/VBoxContainer/"+s.capitalize()+"/VBoxContainer/Level").text = str(level)+"/"+str(MAX_UPG)
		get_node("Map/Upgrades/ScrollContainer/VBoxContainer/"+s.capitalize()+"/VBoxContainer/Cost").text = tr("COST")+": "+str(cost)
		if level==MAX_UPG:
			get_node("Map/Upgrades/ScrollContainer/VBoxContainer/"+s.capitalize()+"/VBoxContainer/Desc").text = "-"
		elif level==MAX_UPG-1:
			get_node("Map/Upgrades/ScrollContainer/VBoxContainer/"+s.capitalize()+"/VBoxContainer/Desc").text = tr("LAST_UPG_"+s.to_upper())
		else:
			get_node("Map/Upgrades/ScrollContainer/VBoxContainer/"+s.capitalize()+"/VBoxContainer/Desc").text = tr("UPG_"+s.to_upper())
		get_node("Map/Upgrades/ScrollContainer/VBoxContainer/"+s.capitalize()+"/VBoxContainer2/Button1").disabled = credits<cost
		get_node("Map/Upgrades/ScrollContainer/VBoxContainer/"+s.capitalize()+"/VBoxContainer2/Button2").disabled = level<1
	$Map/Upgrades.show()
	$Map/System.hide()
	$Map/HBoxContainer/Button3.text = tr("MAP")
	$Map/VBoxContainer/Credits.text = tr("CREDITS")+": "+str(credits)

func _toggle_upg_map():
	if $Map/Upgrades.visible:
		show_map()
	else:
		show_upgrades()

func update_map():
	for c in $Map/Background/Control.get_children():
		c.name = "deleted"
		c.queue_free()
	
	for s in map:
		var bi = $Map/Background/Button.duplicate()
		bi.name = s.name
		bi.get_node("Label").text = s.name
		bi.rect_position = s.pos
		bi.connect("pressed",self,"_select_system",[s])
		$Map/Background/Control.add_child(bi)
		bi.show()
	
	$Map/Background/Control.from = current_system.pos+Vector2(16,16)
	$Map/Background/Control.to = current_system.pos+Vector2(16,16)
	$Map/Background/Control.update()


func apply_settings():
	OS.window_size = window_size
	OS.window_fullscreen = fullscreen
	if !fullscreen:
		OS.window_maximized = maximized
	AudioServer.set_bus_mute(1,!music)
	AudioServer.set_bus_volume_db(1,linear2db(music_volume/100.0))
	AudioServer.set_bus_mute(2,!sound)
	AudioServer.set_bus_volume_db(2,linear2db(sound_volume/100.0))
	
	for action in ACTIONS:
		for event in InputMap.get_action_list(action):
			# Clear old key binds.
			InputMap.action_erase_event(action,event)
		for event in keybinds[action]:
			# Add new key binds.
			InputMap.action_add_event(action,event)
	update_keybinds()
	save_config()

func accept_settings():
	apply_settings()
	$Options.hide()

func revert_settings():
	window_size = OS.window_size
	fullscreen = OS.window_fullscreen
	maximized = OS.window_maximized
	music = !AudioServer.is_bus_mute(1)
	music_volume = int(db2linear(AudioServer.get_bus_volume_db(1))*100)
	sound = !AudioServer.is_bus_mute(2)
	sound_volume = int(db2linear(AudioServer.get_bus_volume_db(2))*100)
	
	$Options/VBoxContainer/Video/VBoxContainer/WindowSize/SpinBoxX.value = window_size.x
	$Options/VBoxContainer/Video/VBoxContainer/WindowSize/SpinBoxY.value = window_size.y
	$Options/VBoxContainer/Video/VBoxContainer/Fullscreen/CheckBox.pressed = fullscreen
	$Options/VBoxContainer/Audio/VBoxContainer/Music/CheckBox.pressed = music
	$Options/VBoxContainer/Audio/VBoxContainer/Music/SpinBox.value = music_volume
	$Options/VBoxContainer/Audio/VBoxContainer/Sound/CheckBox.pressed = sound
	$Options/VBoxContainer/Audio/VBoxContainer/Sound/SpinBox.value = sound_volume
	
	for action in ACTIONS:
		keybinds[action] = InputMap.get_action_list(action)

func _set_window_size_x(value):
	window_size.x = value

func _set_window_size_y(value):
	window_size.y = value

func _set_fullscreen(enabled):
	fullscreen = enabled

func _set_music(enabled):
	music = enabled

func _set_music_volume(volume):
	music_volume = volume

func _set_sound(enabled):
	sound = enabled

func _set_sound_volume(volume):
	sound_volume = volume

func _remove_keybind(action,event):
	keybinds[action].erase(event)
	update_keybinds()

func _confirm_keybind():
	if !(current_action in ACTIONS) || current_event==null:
		return
	if !(current_event in keybinds[current_action]):
		keybinds[current_action].push_back(current_event)
	_hide_add_keybind()
	update_keybinds()

func update_keybinds():
	for action in ACTIONS:
		if !has_node("Options/VBoxContainer/Control/VBoxContainer/"+action.capitalize()):
			var ci = $Options/VBoxContainer/Control/VBoxContainer/Action.duplicate()
			ci.name = action.capitalize()
			ci.get_node("Label").text = tr(action.to_upper())
			ci.get_node("ButtonAdd").connect("pressed",self,"_show_add_keybind",[action])
			$Options/VBoxContainer/Control/VBoxContainer.add_child(ci)
			ci.show()
		for event in keybinds[action]:
			var event_name = ""
			if event is InputEventKey:
				event_name = "K"+str(event.device)+"_"+str(event.scancode)
			elif event is InputEventMouseButton:
				event_name = "M"+str(event.device)+"_"+str(event.button_index)
			elif event is InputEventJoypadButton:
				event_name = "B"+str(event.device)+"_"+str(event.button_index)
			if !has_node("Options/VBoxContainer/Control/VBoxContainer/"+action.capitalize()+"/"+event_name):
				var bi = $Options/VBoxContainer/Control/VBoxContainer/Action/ButtonAdd.duplicate()
				bi.name = event_name
				if event is InputEventKey:
					bi.text = OS.get_scancode_string(event.scancode)
				elif event is InputEventMouseButton:
					if event.button_index==1:
						bi.text = tr("LEFT")+" "
					elif event.button_index==2:
						bi.text = tr("RIGHT")+" "
					bi.text += tr("MOUSE_BUTTON")
					if event.button_index>2:
						bi.text += " "+str(event.button_index)
				elif event is InputEventJoypadButton:
					bi.text = tr("JOYPAD_BUTTON")+" "+str(event.button_index)
				bi.connect("pressed",self,"_remove_keybind",[action,event])
				get_node("Options/VBoxContainer/Control/VBoxContainer/"+action.capitalize()).add_child(bi)
			
	


func load_config():
	var file = ConfigFile.new()
	var error = file.load("user://config.cfg")
	if error!=OK:
		print("No config file found!")
	
	window_size = file.get_value("video","window_size",OS.get_screen_size())
	fullscreen = file.get_value("video","fullscreen",false)
	maximized = file.get_value("video","maximized",true)
	music = file.get_value("audio","music",true)
	music_volume = file.get_value("audio","music_volume",100)
	sound = file.get_value("audio","sound",true)
	sound_volume = file.get_value("audio","sound_volume",100)
	if file.has_section("controls"):
		for action in ACTIONS:
			keybinds[action] = file.get_value("controls",action,[])
	else:
		for action in ACTIONS:
			keybinds[action] = InputMap.get_action_list(action)
	
	apply_settings()

func save_config():
	var file = ConfigFile.new()
	file.set_value("video","window_size",window_size)
	file.set_value("video","fullscreen",fullscreen)
	file.set_value("video","maximized",maximized)
	file.set_value("audio","music",music)
	file.set_value("audio","music_volume",music_volume)
	file.set_value("audio","sound",sound)
	file.set_value("audio","sound_volume",sound_volume)
	for action in ACTIONS:
		file.set_value("controls",action,InputMap.get_action_list(action))
	
	file.save("user://config.cfg")

func _load():
	var file = File.new()
	var error = file.open("user://save.sav",File.READ)
	if error!=OK:
		print("Can't open save file!")
		current_system = System.new(Names.get_name(),$Map/Background/Control.rect_size/2,0,0,"HOME_SYSTEM","")
		randomize_system()
		credits = 200
		return
	
	var currentline = JSON.parse(file.get_line()).get_result()
	if currentline!=null:
		credits = currentline["credits"]
		num_delivered = currentline["delivered"]
	currentline = JSON.parse(file.get_line()).get_result()
	if currentline!=null:
		current_system = System.new(currentline["name"],Vector2(currentline["pos_x"],currentline["pos_y"]),currentline["difficulty"],currentline["reward"],currentline["desc"],currentline["cargo"])
	currentline = JSON.parse(file.get_line()).get_result()
	if currentline!=null:
		for s in UPGRADES:
			if currentline.has(s):
				set("upg_"+s,currentline[s])
	randomize_system()
	
	file.close()

func _save():
	var file = File.new()
	var error = file.open("user://save.sav",File.WRITE)
	if error!=OK:
		print("Can't create save file!")
	
	var upg = {}
	for s in UPGRADES:
		upg[s] = get("upg_"+s)
	file.store_line(JSON.print({"credits":credits,"delivered":num_delivered}))
	file.store_line(JSON.print(current_system.to_dict()))
	file.store_line(JSON.print(upg))
	file.close()

func _quit():
	save_config()
	_save()
	get_tree().quit()


func _select_system(s):
	selected_system = s
	$Map/System/Name.text = s.name
	$Map/System/Distance.text = tr("DISTANCE")+": "+str(int(current_system.pos.distance_to(s.pos)))
	$Map/System/Difficulty.text = tr("SECURITY")+": "+tr(SECURITY[s.difficulty])
	$Map/System/Difficulty.modulate = SECURITY_COLOR[s.difficulty]
	if s==current_system:
		$Map/System/Reward.text = "-"
	else:
		$Map/System/Reward.text = str(s.reward)+" "+tr("CREDITS")
	$Map/System/Desc.text = s.desc
	$Map/HBoxContainer/Button1.disabled = s==current_system
	$Map/System.show()
	$Map/Background/Control.from = current_system.pos+Vector2(16,16)
	$Map/Background/Control.to = selected_system.pos+Vector2(16,16)
	$Map/Background/Control.update()

func pause():
	get_tree().paused = true
	$Pause.show()

func resume():
	get_tree().paused = false
	$Pause.hide()

func _abbord():
	failed()
	resume()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if started:
			if $Pause.visible:
				resume()
			else:
				pause()
		elif $Result.visible:
			$Result.hide()
		elif $Map/Upgrades.visible:
			show_map()
		elif $Map.visible:
			$Map.hide()
		elif $Options/AddKey.visible:
			_hide_add_keybind()
		elif $Options.visible:
			$Options.hide()
	if $Options/AddKey.visible:
		if event is InputEventKey:
			current_event = event
			$Options/AddKey/VBoxContainer/Key.text = OS.get_scancode_string(event.scancode)
		elif event is InputEventMouseButton:
			current_event = event
			if event.button_index==1:
				$Options/AddKey/VBoxContainer/Key.text = tr("LEFT")+" "
			elif event.button_index==2:
				$Options/AddKey/VBoxContainer/Key.text = tr("RIGHT")+" "
			else:
				$Options/AddKey/VBoxContainer/Key.text = ""
			$Options/AddKey/VBoxContainer/Key.text += tr("MOUSE_BUTTON")
			if event.button_index>2:
				$Options/AddKey/VBoxContainer/Key.text += " "+str(event.button_index)
		elif event is InputEventJoypadButton:
			current_event = event
			$Options/AddKey/VBoxContainer/Key.text = tr("JOYPAD_BUTTON")+" "+str(event.button_index)
			
		

func _ready():
	var dir = Directory.new()
	if !dir.dir_exists("user://"):
		dir.make_dir_recursive("user://")
	
	randomize()
	load_config()
	_load()
	set_process_input(true)
	Music.change_to("menu")
	
	if OS.has_feature("web"):
		# Hide quit button for web version.
		$Panel/VBoxContainer/Button2.hide()
	
	# Connect buttons
	$Panel/VBoxContainer/Button1.connect("pressed",self,"_show_map")
	$Panel/VBoxContainer/Button2.connect("pressed",self,"_quit")
	$Panel/VBoxContainer/Button3.connect("pressed",self,"_show_options")
	$Map/HBoxContainer/Button1.connect("pressed",self,"_start")
	$Map/HBoxContainer/Button2.connect("pressed",$Map,"hide")
	$Map/HBoxContainer/Button3.connect("pressed",self,"_toggle_upg_map")
	for s in UPGRADES:
		get_node("Map/Upgrades/ScrollContainer/VBoxContainer/"+s.capitalize()+"/VBoxContainer2/Button1").connect("pressed",self,"_upgrade",[s])
		get_node("Map/Upgrades/ScrollContainer/VBoxContainer/"+s.capitalize()+"/VBoxContainer2/Button2").connect("pressed",self,"_downgrade",[s])
	$Result/Panel/HBoxContainer/Button1.connect("pressed",$Result,"hide")
	$Options/HBoxContainer/Button1.connect("pressed",self,"accept_settings")
	$Options/HBoxContainer/Button2.connect("pressed",self,"apply_settings")
	$Options/HBoxContainer/Button3.connect("pressed",$Options,"hide")
	$Options/VBoxContainer/Video/VBoxContainer/WindowSize/SpinBoxX.connect("value_changed",self,"_set_window_size_x")
	$Options/VBoxContainer/Video/VBoxContainer/WindowSize/SpinBoxY.connect("value_changed",self,"_set_window_size_y")
	$Options/VBoxContainer/Video/VBoxContainer/Fullscreen/CheckBox.connect("toggled",self,"_set_fullscreen")
	$Options/VBoxContainer/Audio/VBoxContainer/Music/CheckBox.connect("toggled",self,"_set_music")
	$Options/VBoxContainer/Audio/VBoxContainer/Music/SpinBox.connect("value_changed",self,"_set_music_volume")
	$Options/VBoxContainer/Audio/VBoxContainer/Sound/CheckBox.connect("toggled",self,"_set_sound")
	$Options/VBoxContainer/Audio/VBoxContainer/Sound/SpinBox.connect("value_changed",self,"_set_sound_volume")
	$Options/AddKey/HBoxContainer/Button1.connect("pressed",self,"_confirm_keybind")
	$Options/AddKey/HBoxContainer/Button2.connect("pressed",self,"_hide_add_keybind")
	$Pause/Panel/HBoxContainer/Button1.connect("pressed",self,"resume")
	$Pause/Panel/HBoxContainer/Button2.connect("pressed",self,"_abbord")
	
	return
	# Import font.
	var font = BitmapFont.new()
	font.add_texture(preload("res://images/fonts/font.png"))
	for i in [0,32]:
		font.add_char(KEY_A+i,0,Rect2(2*Vector2( 1, 1),2*Vector2(7,9)))
		font.add_char(KEY_B+i,0,Rect2(2*Vector2( 9, 1),2*Vector2(7,9)))
		font.add_char(KEY_C+i,0,Rect2(2*Vector2(17, 1),2*Vector2(7,9)))
		font.add_char(KEY_D+i,0,Rect2(2*Vector2(25, 1),2*Vector2(7,9)))
		font.add_char(KEY_E+i,0,Rect2(2*Vector2(33, 1),2*Vector2(7,9)))
		font.add_char(KEY_F+i,0,Rect2(2*Vector2(41, 1),2*Vector2(7,9)))
		font.add_char(KEY_G+i,0,Rect2(2*Vector2(49, 1),2*Vector2(7,9)))
		font.add_char(KEY_H+i,0,Rect2(2*Vector2(57, 1),2*Vector2(7,9)))
		font.add_char(KEY_I+i,0,Rect2(2*Vector2(65, 1),2*Vector2(3,9)))
		font.add_char(KEY_J+i,0,Rect2(2*Vector2(69, 1),2*Vector2(6,9)))
		font.add_char(KEY_K+i,0,Rect2(2*Vector2(76, 1),2*Vector2(6,9)))
		font.add_char(KEY_L+i,0,Rect2(2*Vector2(83, 1),2*Vector2(6,9)))
		font.add_char(KEY_M+i,0,Rect2(2*Vector2(90, 1),2*Vector2(10,9)))
		font.add_char(KEY_N+i,0,Rect2(2*Vector2( 1,11),2*Vector2(7,9)))
		font.add_char(KEY_O+i,0,Rect2(2*Vector2( 9,11),2*Vector2(7,9)))
		font.add_char(KEY_P+i,0,Rect2(2*Vector2(17,11),2*Vector2(6,9)))
		font.add_char(KEY_Q+i,0,Rect2(2*Vector2(24,11),2*Vector2(7,9)))
		font.add_char(KEY_R+i,0,Rect2(2*Vector2(32,11),2*Vector2(6,9)))
		font.add_char(KEY_S+i,0,Rect2(2*Vector2(39,11),2*Vector2(6,9)))
		font.add_char(KEY_T+i,0,Rect2(2*Vector2(46,11),2*Vector2(7,9)))
		font.add_char(KEY_U+i,0,Rect2(2*Vector2(54,11),2*Vector2(7,9)))
		font.add_char(KEY_V+i,0,Rect2(2*Vector2(62,11),2*Vector2(7,9)))
		font.add_char(KEY_W+i,0,Rect2(2*Vector2(70,11),2*Vector2(10,9)))
		font.add_char(KEY_X+i,0,Rect2(2*Vector2(81,11),2*Vector2(7,9)))
		font.add_char(KEY_Y+i,0,Rect2(2*Vector2(89,11),2*Vector2(7,9)))
		font.add_char(KEY_Z+i,0,Rect2(2*Vector2(97,11),2*Vector2(6,9)))
	font.add_char(KEY_ODIAERESIS,0,Rect2(2*Vector2(104,10),2*Vector2(7,10)))
	font.add_char(KEY_ODIAERESIS+32,0,Rect2(2*Vector2(104,10),2*Vector2(7,10)))
	font.add_char(KEY_SPACE,0,Rect2(2*Vector2(101,1),2*Vector2(5,9)))
	font.add_char(KEY_0,0,Rect2(2*Vector2( 1,21),2*Vector2(7,9)))
	font.add_char(KEY_1,0,Rect2(2*Vector2( 9,21),2*Vector2(5,9)))
	font.add_char(KEY_2,0,Rect2(2*Vector2(15,21),2*Vector2(6,9)))
	font.add_char(KEY_3,0,Rect2(2*Vector2(22,21),2*Vector2(7,9)))
	font.add_char(KEY_4,0,Rect2(2*Vector2(30,21),2*Vector2(7,9)))
	font.add_char(KEY_5,0,Rect2(2*Vector2(38,21),2*Vector2(6,9)))
	font.add_char(KEY_6,0,Rect2(2*Vector2(45,21),2*Vector2(7,9)))
	font.add_char(KEY_7,0,Rect2(2*Vector2(53,21),2*Vector2(6,9)))
	font.add_char(KEY_8,0,Rect2(2*Vector2(60,21),2*Vector2(7,9)))
	font.add_char(KEY_9,0,Rect2(2*Vector2(68,21),2*Vector2(7,9)))
	font.add_char(KEY_PERIOD,0,Rect2(2*Vector2(76,21),2*Vector2(3,9)))
	font.add_char(KEY_COMMA,0,Rect2(2*Vector2(80,21),2*Vector2(4,9)))
	font.add_char(KEY_COLON,0,Rect2(2*Vector2(85,21),2*Vector2(3,9)))
	font.add_char(KEY_EXCLAM,0,Rect2(2*Vector2(89,21),2*Vector2(3,9)))
	font.add_char(KEY_QUESTION,0,Rect2(2*Vector2(93,21),2*Vector2(7,9)))
	font.add_char(KEY_SLASH,0,Rect2(2*Vector2(101,21),2*Vector2(5,9)))
	font.add_char(KEY_MINUS,0,Rect2(2*Vector2(107,21),2*Vector2(6,9)))
	font.add_char(KEY_PLUS,0,Rect2(2*Vector2(105,1),2*Vector2(7,9)))
	font.add_char(KEY_APOSTROPHE,0,Rect2(2*Vector2(101,1),2*Vector2(3,9)))
	font.add_char(KEY_PERCENT,0,Rect2(2*Vector2(113,1),2*Vector2(7,9)))
	font.set_height(19)
	
	ResourceSaver.save("res://fonts/font.tres",font)
	
	
