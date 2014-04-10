
extends Node2D

var joy_num
var axis_value
var btn_state

func _ready():
	set_process_input(true)

func _input(ev):
	# get the joystick device number from the spinbox
	joy_num = get_node("joy_num").get_value()
	
	# loop through the axes and get their current values
	for axis in range(0,8):
		axis_value = Input.get_joy_axis(joy_num,axis)
		get_node("axis_prog"+str(axis)).set_value(100*axis_value)
		get_node("axis_val"+str(axis)).set_text(str(axis_value))
	
	# loop through the buttons and show which ones are pressed
	for btn in range(0,16):
		btn_state = 1
		if (Input.is_joy_button_pressed(joy_num, btn)):
			get_node("btn"+str(btn)).show()
		else:
			get_node("btn"+str(btn)).hide()
