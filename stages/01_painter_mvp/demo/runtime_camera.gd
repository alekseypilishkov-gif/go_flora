extends Camera3D

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			look_at_from_position(Vector3(6, 5, 7), Vector3.ZERO)
		elif event.keycode == KEY_2:
			look_at_from_position(Vector3(28, 18, 30), Vector3.ZERO)

func _process(delta: float) -> void:
	var motion := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		motion.z -= 1
	if Input.is_physical_key_pressed(KEY_S):
		motion.z += 1
	if Input.is_physical_key_pressed(KEY_A):
		motion.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		motion.x += 1
	position += basis * motion * delta * 8.0
