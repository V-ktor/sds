extends CanvasLayer

const DEFAULT_TEXT_SPEED = 20.0
const DEFAULT_PAUSE = 4.0
const TEXTBOX_NAME = ["Other","Player"]

var buffer = []
var delay = 0.0
var text_speed = DEFAULT_TEXT_SPEED
var wait = false
var started = false

signal buffer_ended()

class Buffer:
	var text
	var player
	var speed
	var clear
	var pause
	
	func _init(t,pl,s,c,p):
		text = t
		player = pl
		speed = s
		clear = c
		pause = p


func add_text(text,player=true,clear=true,speed=DEFAULT_TEXT_SPEED,pause=DEFAULT_PAUSE):
	buffer.push_back(Buffer.new(tr(text),player,speed,clear,pause))

func next_buffer():
	if buffer.size()<=0:
		return
	
	print("Clear current buffer.")
	var current = buffer[0]
	buffer.pop_front()
	wait = false
	started = false
	if buffer.size()==0:
		buffer_ended(max(current.pause,10.0))
	if current.clear:
		get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/Timer").set_wait_time(current.pause)
		get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/Timer").start()
		if buffer.size()==0 || buffer[0].player!=current.player:
			yield(get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/Timer"),"timeout")
		get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/Label").text = ""

func new_buffer():
	if buffer.size()<=0:
		return
	
	print("Continue with next buffer.")
	var current = buffer[0]
	var anim = get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/AnimationPlayer")
	started = true
	if get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]).modulate.a<1.0 && (!anim.is_playing() || anim.current_animation!="fade_in"):
		anim.queue("fade_in")
	get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/Timer").stop()
	if current.clear:
		get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/Label").text = ""
	elif get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/Label").text.length()>0:
		get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/Label").text += "\n"

func buffer_ended(pause=10.0):
	print("Buffer ended.")
	wait = false
	started = false
	fade_out(true)
	fade_out(false)
	emit_signal("buffer_ended")

func fade_out(player):
	if get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(player)]).modulate.a>0.0 && (!$Left/VBoxContainer/VBoxContainer/TextPlayer/AnimationPlayer.is_playing() || $Left/VBoxContainer/VBoxContainer/TextPlayer/AnimationPlayer.current_animation!="fade_out"):
		get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(player)]+"/AnimationPlayer").clear_queue()
		get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(player)]+"/AnimationPlayer").play("fade_out")

func _process(delta):
	delay -= delta
	if delay<=0.0:
		if buffer.size()>0:
			var current = buffer[0]
			if !started:
				new_buffer()
			if current.text.length()>0:
				get_node("Left/VBoxContainer/VBoxContainer/Text"+TEXTBOX_NAME[int(current.player)]+"/Label").text += current.text[0]
				current.text = current.text.substr(1,current.text.length()-1)
			else:
				if wait:
					next_buffer()
				else:
					delay += current.pause
					wait = true
		elif started:
			buffer_ended()
		delay += 1.0/text_speed
		
	

func _input(event):
	if event.is_action_pressed("ui_accept"):
		delay = 0

func _resized():
	var scale = (OS.get_window_size().x-200)/500.0
	$Left.margin_right = 96*scale
	$Right.margin_left = -96*scale
	$Right/Energy.margin_top = -96*scale
	$Right/Energy/Wheel.position = 96*scale*Vector2(1,1)
	$Right/Energy/Wheel.scale = scale*Vector2(1,1)
	$Right/Energy/HBoxContainer.rect_scale = scale*Vector2(1,1)
	$Right/Energy/HBoxContainer.anchor_right = 1.0/scale
	$Right/Energy/HBoxContainer.margin_right = 5*scale
	$Right/Energy/HBoxContainer.rect_position = Vector2(10,23*scale)
	$Right/VBoxContainer/HP.rect_min_size.y = 16*scale
	$Right/VBoxContainer/SP.rect_min_size.y = 12*scale
	$Right/VBoxContainer/Delay.rect_min_size.y = 12*scale
	$Right/Energy/Energy.margin_top = -12*scale
	$Right/Icon.margin_bottom = 48+64*(scale-1)

func _ready():
	get_tree().connect("screen_resized",self,"_resized")
	_resized()
	set_process_input(true)
	$Left/VBoxContainer/VBoxContainer/TextPlayer/Timer.connect("timeout",self,"fade_out",[true])
	$Left/VBoxContainer/VBoxContainer/TextOther/Timer.connect("timeout",self,"fade_out",[false])
