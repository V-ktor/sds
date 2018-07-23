extends Control

var from = Vector2()
var to = Vector2()


func _draw():
	draw_circle(from,24.0,Color(0.1,0.6,1.0,0.5))
	if from!=to:
		draw_circle(to,8.0,Color(1.0,0.1,0.075,0.5))
		draw_line(from,to,Color(1.0,0.1,0.075,0.5),4)
