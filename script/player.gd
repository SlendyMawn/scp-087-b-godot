# I made a mistake and didn't port the player correctly as i didn't know wtf i was looking at until i had already finished it.
# The actual player (and enemy) are just small circles that sit on the ground with the camera at an offset above it
# I adjusted the code to account for this new player i've made and i'm not sure what benefit making the player similar to the old one would provide, but just so you know, this isn't really accurate.
class_name SCPPlayer
extends CharacterBody3D

var shake: float = 0.0
var shakeX: float = 0.0
var lasty: float
var killtimer: int = 0
var player_floor: int = 0
var invuln: bool = false
var debug_menu: SCPDebugMenu = preload("res://obj/debug_menu.res").instantiate()
var blur_timer: int
var last_pause: CanvasLayer

@onready var worldenv: WorldEnvironment = get_tree().root.find_child("WorldEnvironment", true, false)
@onready var camera: Camera3D = $Camera3D
@onready var fps_label: Label = $FPSLabel

func process_input(delta: float):
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Test commands
	if OS.is_debug_build() or OS.get_cmdline_args().has("-debug"):
		if Input.is_action_just_pressed("test_view_default"):
			RenderingServer.set_debug_generate_wireframes(false)
			worldenv.environment.fog_enabled = true
			$DreamFilter.show()
			get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
			print("Viewmode: Shaded")
		
		if Input.is_action_just_pressed("test_view_wireframe"):
			RenderingServer.set_debug_generate_wireframes(true)
			worldenv.environment.fog_enabled = false
			$DreamFilter.hide()
			get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
			print("Viewmode: Wireframe")
		
		if Input.is_action_just_pressed("test_view_unlit"):
			RenderingServer.set_debug_generate_wireframes(false)
			worldenv.environment.fog_enabled = false
			$DreamFilter.hide()
			get_viewport().debug_draw = Viewport.DEBUG_DRAW_UNSHADED
			print("Viewmode: Unlit")
		
		if Input.is_action_just_pressed("test_kill"):
			killtimer += 1
		
		if Input.is_action_just_pressed("test_invuln"):
			invuln = !invuln
			print("Degreelessness Mode ON" if invuln else "Degreelessness Mode OFF")
		
		if Input.is_action_just_pressed("test_debug"):
			if debug_menu.is_inside_tree():
				get_tree().root.remove_child(debug_menu)
			else:
				get_tree().root.add_child(debug_menu)
	
	if Input.is_action_just_pressed("pause") and !get_tree().paused and last_pause == null:
		last_pause = load("res://obj/pause.res").instantiate()
		get_tree().root.add_child(last_pause)
		get_tree().paused = true
	
	
	# Movement input
	#TODO: Implement step-up code so we can walk back up the stairs if we so please.
	var input_movement_vector: Vector2 = Vector2()
	var cam_xform = self.get_global_transform()
	velocity.x = 0
	velocity.z = 0
	if Input.is_action_pressed("movement_forward") or Input.is_action_pressed("movement_backward") or Input.is_action_pressed("movement_left") or Input.is_action_pressed("movement_right"):
		shake += 0.5
		shakeX += 0.5
		if shake >= 10.0:
			shake = -10.0
			$Footstep.play()
		if shake < 0.0:
			$Camera3D.position.y -= 0.005
		else:
			$Camera3D.position.y += 0.005
		
		if shakeX >= 20.0:
			shakeX = -20.0
		if shakeX < 0.0:
			$Camera3D.position.x -= 0.002
		else:
			$Camera3D.position.x += 0.002
		
		if Input.is_action_pressed(&"movement_forward"):
			input_movement_vector.y = -1.2
		if Input.is_action_pressed(&"movement_backward"):
			input_movement_vector.y = 0.9
		if Input.is_action_pressed(&"movement_left"):
			input_movement_vector.x = -1.0
		if Input.is_action_pressed(&"movement_right"):
			input_movement_vector.x = 1.0
	
	# Gamepad Look
	if Input.get_axis(&"movement_look_down", &"movement_look_up"):
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x + deg_to_rad(Input.get_axis(&"movement_look_down", &"movement_look_up") * SCPGame.look_sensitivity_gamepad), deg_to_rad(-70), deg_to_rad(70))
	if Input.get_axis(&"movement_look_left", &"movement_look_right"):
		self.rotate_y(deg_to_rad(Input.get_axis(&"movement_look_right", &"movement_look_left") * SCPGame.look_sensitivity_gamepad))
	
	if !is_on_floor():
		velocity.y -= 0.24
		if velocity.y < -64:
			# If you fall out of bounds somehow this should kill you eventually
			killtimer = maxf(1, killtimer)
	else:
		if lasty < -5.4:
			killtimer = maxf(1, killtimer)
	
	lasty = velocity.y
	
	var dir: Vector3
	
	dir += cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	velocity.x += dir.x
	velocity.z += dir.z
	
	# Stair Step Up
	# FIXME: This gets stuck on the last step? Why? Aren't these uniform?
	if is_on_wall() and input_movement_vector != Vector2(0, 0):
		var step_up_test: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
		step_up_test.from = transform
		step_up_test.motion = velocity / 2
		step_up_test.motion.y = 0.84
		step_up_test.recovery_as_collision = true
		if !PhysicsServer3D.body_test_motion(get_rid(), step_up_test):
			print("Step detected, adjusting velocity by ", velocity - step_up_test.motion)
			velocity = step_up_test.motion
	
func _physics_process(delta: float) -> void:
	blur_timer = maxi(blur_timer - 1, 0)
	if killtimer > 0:
		kill(delta)
	else:
		process_input(delta)
	#TODO: Replace with the last floor object you stepped on determining your floor?
	player_floor = -position.y / 2
	move_and_slide()

func _process(delta: float) -> void:
	fps_label.text = "FPS: " + str(int(1 / delta))
	fps_label.visible = SCPGame.show_fps
	if blur_timer < 50:
		update_blur(0.7 + (blur_timer / 50.0) * 0.2)
	else:
		update_blur()

#TODO: Replace with SCP mouse look/smoothing code?
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x + deg_to_rad(event.relative.y * SCPGame.look_sensitivity_mouse * -1), deg_to_rad(-70), deg_to_rad(70))
		self.rotate_y(deg_to_rad(event.relative.x * SCPGame.look_sensitivity_mouse * -1))

func kill(delta: float):
	if killtimer == 1:
		$DeathSFX.play()
	killtimer += 1
	$Camera3D.rotate_x(deg_to_rad(-killtimer * delta))
	$Camera3D.rotate_z(deg_to_rad(((float(-killtimer) / 2))) * delta)
	velocity.y -= 0.24
	$CollisionShape3D.shape.height = clamp($CollisionShape3D.shape.height - float(killtimer) * delta, 0.025, 2.0)
	worldenv.environment.ambient_light_color = Color8(255 - killtimer, 100 - killtimer, 100 - killtimer, 255)
	if killtimer > 90:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if player_floor > 130:
			match randi_range(1, 7):
				1:
					OS.alert("NO", "Error!")
				2:
					OS.alert("It's not about whether you die or not, it's about when you die.", "Error!")
				3:
					OS.alert("NICE", "Error!")
				4:
					OS.alert("welcome to NIL", "Error!")
		SCPGame.load_scene("res://scn/menu.scn")
		return

func _ready() -> void:
	debug_menu.player = self
	if get_parent_node_3d() is SCPWorld:
		debug_menu.world = get_parent_node_3d()
	if !OS.has_feature("mobile"):
		$MobileControls.queue_free()
	else:
		fps_label.reparent($MobileControls/MobileFPSLabel)
		fps_label.label_settings.font_size *= 2

# Dream Filter
func update_blur(power: float = 0.9):
	var viewport: Viewport = get_viewport()
	var texture: Texture2D = viewport.get_texture()
	$Camera3D/DreamBuffer/DreamRect.modulate.a = power
	$Camera3D/DreamBuffer/DreamRect.texture = texture
	texture = $Camera3D/DreamBuffer.get_texture()
	$DreamFilter.texture = texture
	$DreamFilter.material.set("shader_parameter/power", power)


func _on_pause_button_pressed() -> void:
	Input.action_press(&"pause")
	Input.action_release(&"pause")
