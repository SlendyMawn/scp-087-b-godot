class_name SCPWorld
extends Node3D

enum FLOOR_ACTION {ACT_NONE = 0, ACT_STEPS = 1, ACT_LIGHTS = 2, ACT_FLASH = 3, ACT_WALK = 4, ACT_RUN = 5, ACT_KALLE = 6, ACT_BREATH = 7, ACT_PROCEED = 8, ACT_TRAP=9, ACT_173 = 11, 
ACT_CELL = 12, ACT_LOCK = 13, ACT_RADIO2 = 15, ACT_RADIO3 = 16, ACT_RADIO4 = 17, ACT_TRICK1 = 18, ACT_TRICK2 = 19, ACT_ROAR = 20, ACT_DARKNESS = 21}

# Map meshes
const map0: Mesh = preload("res://gfx/mesh/map/map0.obj")
const map1: Mesh = preload("res://gfx/mesh/map/map1.obj")
const map2: Mesh = preload("res://gfx/mesh/map/map2.obj")
const map3: Mesh = preload("res://gfx/mesh/map/map3.obj") # FIXME: This floor hangs low enough to increment the floor counter upon entering, rendering any events that would have happened here pointless. I am unsure if this happens in the original or not.
const map4: Mesh = preload("res://gfx/mesh/map/map4.obj")
const map5: Mesh = preload("res://gfx/mesh/map/map5.obj")
const map6: Mesh = preload("res://gfx/mesh/map/map6.obj")
const map: Mesh = preload("res://gfx/mesh/map/map.obj")
const map7: Mesh = preload("res://gfx/mesh/map/maze.obj")

# Map colliders

const map0_shape: Shape3D = preload("res://gfx/mesh/map/map0.shape")
const map1_shape: Shape3D = preload("res://gfx/mesh/map/map1.shape")
const map2_shape: Shape3D = preload("res://gfx/mesh/map/map2.shape")
const map3_shape: Shape3D = preload("res://gfx/mesh/map/map3.shape")
const map4_shape: Shape3D = preload("res://gfx/mesh/map/map4.shape")
const map5_shape: Shape3D = preload("res://gfx/mesh/map/map5.shape")
const map6_shape: Shape3D = preload("res://gfx/mesh/map/map6.shape")
const map_shape: Shape3D = preload("res://gfx/mesh/map/map.shape")
const map7_shape: Shape3D = preload("res://gfx/mesh/map/maze.shape")

# Sounds
const FireOn: AudioStream = preload("res://sfx/match.ogg")
const FireOff: AudioStream = preload("res://sfx/fireout.ogg")
const StoneSFX: AudioStream = preload("res://sfx/stone.ogg")
const BreathSFX: AudioStream = preload("res://sfx/breath.ogg")
const LoudStep: AudioStream = preload("res://sfx/loudstep.ogg")
const RoarSFX: AudioStream = preload("res://sfx/roar.ogg")

# Textures

const tex173: StandardMaterial3D = preload("res://gfx/mat/173.material")
const brickwalltexture: StandardMaterial3D = preload("res://gfx/mat/brickwall.material")
const brickwalltexture_trap: StandardMaterial3D = preload("res://gfx/mat/brickwall_trap.material")
const concretefloortexture: StandardMaterial3D = preload("res://gfx/mat/concretefloor.material")

var floor_actions: Array[int]
var floor_timer: Array[int]
var temp

var current_enemy: SCPEnemy
var current_object: Node3D

var ambient_sfx: Array[AudioStream]
var radio_sfx: Array[AudioStream]
var horror_sfx: Array[AudioStream]

var sound_temp: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

var player: SCPPlayer = load("res://obj/player.res").instantiate()


func _init() -> void:
	floor_actions.resize(SCPGame.num_floors)
	floor_timer.resize(SCPGame.num_floors)
	ambient_sfx.resize(10)
	for i in 9:
		ambient_sfx[i] = load("res://sfx/ambient" + str(i + 1) + ".ogg")
	radio_sfx.resize(5)
	for i in 4:
		radio_sfx[i] = load("res://sfx/radio" + str(i + 1) + ".ogg")
	horror_sfx.resize(3)
	for i in 3:
		horror_sfx[i] = load("res://sfx/horror" + str(i + 1) + ".ogg")
	player.position = Vector3(-2.5, -1.3, 0.5)
	add_child(player)
	add_child(sound_temp)
	create_map(SCPGame.num_floors)
	create_glimpses(SCPGame.num_floors)

func _ready() -> void:
	%WorldEnvironment.environment.ambient_light_color = Color8(SCPGame.brightness, SCPGame.brightness, SCPGame.brightness)

func play_sound(sound: AudioStream):
	var oneshot: AudioOneShot = AudioOneShot.new(sound)
	add_child(oneshot)

func create_map(floor_amount: int):
	# Create door
	print("Generating map...")
	var door: MeshInstance3D = MeshInstance3D.new()
	var door_collider: StaticBody3D = StaticBody3D.new()
	var door_collider_shape: CollisionShape3D = CollisionShape3D.new()
	door.mesh = BoxMesh.new()
	door.mesh.size = Vector3(0.5, 2.0, 1.0)
	door.mesh.material = preload("res://gfx/mat/door.material")
	door.position = Vector3(-3.25, -1.0, 0.5)
	door_collider_shape.shape = BoxShape3D.new()
	door_collider_shape.shape.size = door.mesh.size
	add_child(door)
	door.add_child(door_collider)
	door_collider.add_child(door_collider_shape)
	print("Door placed.")
	
	floor_actions[0] = FLOOR_ACTION.ACT_PROCEED
	floor_timer[0] = 1
	
	
	if randi_range(1, 2) == 1:
		temp = randi_range(3, 4)
		floor_actions[temp] = FLOOR_ACTION.ACT_RADIO2
		floor_timer[temp] = 1
	
	if randi_range(1, 3) < 3:
		temp = randi_range(5, 6)
		floor_actions[temp] = FLOOR_ACTION.ACT_RADIO3
		floor_timer[temp] = 1
	
	
	floor_actions[7] = FLOOR_ACTION.ACT_LOCK
	floor_timer[7] = 1
	
	if randi_range(1, 2) == 1:
		temp = randi_range(8, 9)
		floor_actions[temp] = FLOOR_ACTION.ACT_RADIO4
		floor_timer[temp] = 1
	
	temp = randi_range(10, 11)
	floor_actions[temp] = FLOOR_ACTION.ACT_BREATH
	floor_timer[temp] = 1
	
	temp = randi_range(12, 13)
	floor_actions[temp] = FLOOR_ACTION.ACT_STEPS
	floor_timer[temp] = 1
	
	# This bit of map generation code was left commented out, but seemed significant. (Test later to see what it does?)
	#if randi_range(1, 5) < 5:
		#temp = randi_range(10, 19)
		#floor_actions[temp] = FLOOR_ACTION.ACT_FLASH
		#floor_timer[temp] = randi_range(1, 3)
	
	temp = randi_range(20, 22)
	floor_actions[temp] = FLOOR_ACTION.ACT_LIGHTS
	floor_timer[temp] = 1
	
	match randi_range(1, 4):
		1:
			temp = randi_range(25, 28)
			floor_actions[temp] = FLOOR_ACTION.ACT_TRICK1
			floor_timer[temp] = 1
		2:
			temp = randi_range(12, 13)
			floor_actions[temp] = FLOOR_ACTION.ACT_TRICK2
			floor_timer[temp] = 1
	
	temp = randi_range(29,33)
	floor_actions[temp] = FLOOR_ACTION.ACT_RUN
	floor_timer[temp] = 1
	
	temp = randi_range(34,37)
	floor_actions[temp] = FLOOR_ACTION.ACT_173
	floor_timer[temp] = 1
	
	temp = randi_range(40,60)
	floor_actions[temp] = FLOOR_ACTION.ACT_RUN
	floor_timer[temp] = 1
	
	temp = randi_range(40,60)
	floor_actions[temp] = FLOOR_ACTION.ACT_ROAR
	floor_timer[temp] = 1
	
	temp = randi_range(40,60)
	floor_actions[temp] = FLOOR_ACTION.ACT_TRAP
	floor_timer[temp] = 1
	
	temp = randi_range(40,60)
	floor_actions[temp] = FLOOR_ACTION.ACT_FLASH
	floor_timer[temp] = 1
	
	var randact: int = 0
	var temper: bool = false
	for i in 9:
		match randi_range(1, 10):
			1,9:
				randact = FLOOR_ACTION.ACT_CELL
			2:
				randact = FLOOR_ACTION.ACT_FLASH
			3:
				randact = FLOOR_ACTION.ACT_TRICK1
			4:
				randact = FLOOR_ACTION.ACT_TRICK2
			5:
				randact = FLOOR_ACTION.ACT_BREATH
			6:
				randact = FLOOR_ACTION.ACT_STEPS
			7:
				randact = FLOOR_ACTION.ACT_TRAP
			8:
				randact = FLOOR_ACTION.ACT_ROAR
		temper = false
		while temper == false:
			temp = randi_range(25, 69)
			if floor_actions[temp] == 0:
				floor_actions[temp] = randact
				floor_timer[temp] = 1
				temper = true
	
	randact = 0
	for i in 61:
		match randi_range(1, 10):
			1,9:
				randact = FLOOR_ACTION.ACT_CELL
			2:
				randact = FLOOR_ACTION.ACT_LIGHTS
			# Original source code makes this mistake, for the sake of being accurate - let's make it again. ( ͡° ͜ʖ ͡°)
			3:
				randact = FLOOR_ACTION.ACT_RUN
			3:
				randact = FLOOR_ACTION.ACT_TRICK1
			4:
				randact = FLOOR_ACTION.ACT_TRICK2
			5:
				randact = FLOOR_ACTION.ACT_BREATH
			6:
				randact = FLOOR_ACTION.ACT_STEPS
			7:
				randact = FLOOR_ACTION.ACT_TRAP
			8:
				randact = FLOOR_ACTION.ACT_ROAR
		temper = false
		while temper == false:
			temp = randi_range(75, 200)
			if floor_actions[temp] == 0:
				floor_actions[temp] = randact
				floor_timer[temp] = 1
				temper = true
	
	temp = randi_range(150, 200)
	floor_actions[temp] = FLOOR_ACTION.ACT_DARKNESS
	floor_timer[temp] = 1
	
	for i in floor_amount - 1:
		var new_floor: MeshInstance3D = MeshInstance3D.new()
		if i == 0:
			temp = map0
		else:
			match floor_actions[i]: # The original did i+1 for some reason. This fucks things up immeasurably and i have no idea how the original even functioned.
				FLOOR_ACTION.ACT_173:
					temp = map2
				FLOOR_ACTION.ACT_CELL:
					temp = map1
				FLOOR_ACTION.ACT_TRICK1:
					temp = map4
				FLOOR_ACTION.ACT_TRICK2:
					temp = map5
				FLOOR_ACTION.ACT_FLASH, FLOOR_ACTION.ACT_RUN, FLOOR_ACTION.ACT_WALK, FLOOR_ACTION.ACT_LIGHTS, FLOOR_ACTION.ACT_TRAP, FLOOR_ACTION.ACT_LOCK:
					temp = map
				0:
					match randi_range(1, 20):
						1,2:
							temp = map1
						3,4:
							temp = map2
						5,6:
							temp = map3
						7:
							temp = map4
						8:
							temp = map5
						9:
							temp = map6
						10:
							if i > 40:
								temp = map7
							else:
								temp = map
						_:
							temp = map
				_:
					temp = map
		new_floor.mesh = temp
		if floor(i/2.0) == ceil(i/2.0): # parillinen
			new_floor.position = Vector3(0, -i*2, 0)
		else: # pariton
			new_floor.rotate_y(deg_to_rad(180))
			new_floor.position = Vector3(8, -i*2, 7)
		# Create floor mesh
		var floor_mesh_name: String = temp.resource_path.get_file().trim_suffix(".obj")
		var floor_collider: StaticBody3D = StaticBody3D.new()
		var floor_collider_shape: CollisionShape3D = CollisionShape3D.new()
		floor_collider_shape.shape = get(floor_mesh_name + "_shape")
		add_child(new_floor)
		new_floor.add_child(floor_collider)
		floor_collider.add_child(floor_collider_shape)
		print("Created floor ", str(i))
	# Assign floor textures
	for mapi: ArrayMesh in [map0, map1, map2, map3, map4, map5, map6, map7, map]:
		mapi.surface_set_material(0, concretefloortexture)
		mapi.surface_set_material(1, brickwalltexture)
	map0.surface_set_material(2, preload("res://gfx/mat/white.material"))
	draw_floor_markers(floor_amount)

func create_glimpses(floor_amount: int):
	var FloorX: float
	var FloorY: float
	var FloorZ: float
	var StartX: float
	var EndX: float
	
	for i in floor_amount:
		if floor_actions[i] == 0 and randi_range(1, 7) == 1:
			FloorX = 4
			FloorY = (-i * 2) - 1
			
			if floor(i/2.0) == ceil(i/2.0):
				FloorZ = 0.5
				StartX = 0.8
				EndX = 7.2
			else:
				FloorZ = 6.5
				StartX = 7.2
				EndX = 0.8
			
			var glimpse: SCPGlimpse = load("res://obj/glimpse.res").instantiate()
			# The original uses a random function that only return ints seemingly by mistake, which let these faces spawn in walls at the start/end of a floor.
			glimpse.position = Vector3(randf_range(StartX, EndX), FloorY, FloorZ)
			add_child(glimpse)

func draw_floor_markers(floor_amount: int):
	for i in range(1, floor_amount):
		var number: String = ""
		match randi_range(1, 600):
			1:
				number = ""
			2:
				number = str(randi_range(33, 122))
			3:
				number = "NIL"
			4:
				number = "?"
			5:
				number = "NO"
			6:
				number = "stop"
			_:
				number = str(i + 1)
		if i > 140:
			number = ""
			for n in range(1, 5):
				number = number + str(randi_range(33,122))
		var floor_marker: Node3D = load("res://obj/sign.res").instantiate()
		if floor(i/2.0) == ceil(i/2.0):
			floor_marker.position = Vector3(-0.1, (-i*2)-0.6, 0.5)
			floor_marker.rotate_y(deg_to_rad(90))
		else:
			floor_marker.position = Vector3(7.4+0.6+0.1, (-i*2)-0.6, 6+0.5)
			floor_marker.rotate_y(deg_to_rad(-90))
		floor_marker.get_node("FloorNum").text = number
		add_child(floor_marker)
		print("Added floor marker for floor " + str(i))

func _physics_process(delta: float) -> void:
	# I didn't realise this at the time, but physics_process is actually capped to 60fps by default, allowing the game to render at a higher framerate while still retaining the behaviour of the original game.
	#TODO: Implement deltatime to handle this better at lower framerates
	update_floors(SCPGame.num_floors)
	# This seems to happen awfully frequently, double check if its like this in the original. (Consider quintupling the higher number and negating it by player floors * 3?)
	if randi_range(1, 1000) < 2:
		$Ambient.position = Vector3(player.position.x + randi_range(-1, 1), player.position.y + randi_range(-2, -10), player.position.z + randi_range(-1, 1))
		$Ambient.stream = ambient_sfx[randi_range(0, 8)]
		$Ambient.play()

func update_floors(floor_amount: int):
	var FloorX: float
	var FloorY: float
	var FloorZ: float
	var StartX: float
	var EndX: float
	for i in floor_amount:
		if floor_timer[i] > 0:
			FloorX = 4
			# Had to change the height formula due to coordinate system changes
			FloorY = (-i * 2) - 1
			if floor(i/2.0) == ceil(i/2.0): #parillinen
				# Swapped these values as they were the wrong way around when ran in godot. (Origninal on right comment)
				FloorZ = 0.25 #6.75
				StartX = 0.5 #7.5
				EndX = 7.5 #0.5
			else: #pariton
				FloorZ = 6.75 #0.25
				StartX = 7.5 #0.5
				EndX = 0.5 #7.5
			match floor_actions[i]:
				
				FLOOR_ACTION.ACT_LIGHTS:
					if floor_timer[i] > 1:
						floor_timer[i] += 1
						if floor_timer[i] > 100:
							current_enemy.animate2(current_enemy.current_anim_time,1,14,0.15)
						if floor_timer[i] == 100:
							create_enemy(Vector3(EndX, FloorY-0.5, FloorZ))
							current_enemy.speed = 0.6
						if floor_timer[i] == 210:
							play_sound(FireOn)
						if floor_timer[i] == 250:
							%WorldEnvironment.environment.ambient_light_color = Color8(SCPGame.brightness, SCPGame.brightness, SCPGame.brightness)
						if floor_timer[i] == 290:
							play_sound(horror_sfx[2])
						if floor_timer[i] == 450:
							current_enemy.queue_free()
							floor_timer[i] = 0
				
				FLOOR_ACTION.ACT_RUN:
					if floor_timer[i] > 1:
						floor_timer[i] += 1
						if floor_timer[i] == 100:
							create_enemy(Vector3(EndX, FloorY-0.5, FloorZ))
							current_enemy.speed = 2.1
						elif floor_timer[i] == 130 or floor_timer[i] == 260 or floor_timer[i] == 380: #valot syttyy
							play_sound(horror_sfx[0])
							%WorldEnvironment.environment.fog_depth_begin = 1
							%WorldEnvironment.environment.fog_depth_end = 20
							%WorldEnvironment.environment.ambient_light_color = Color8(SCPGame.brightness, SCPGame.brightness, SCPGame.brightness)
							current_enemy.speed = 0.00000000000000001 # Setting this to 0 doesn't work for some reason.
						elif floor_timer[i] == 170 or floor_timer[i] == 300: #valot sammuu
							current_enemy.speed = 1.8
							%WorldEnvironment.environment.fog_depth_begin = 1
							%WorldEnvironment.environment.fog_depth_end = 2.5
							%WorldEnvironment.environment.ambient_light_color = Color8(15, 15, 15)
						elif floor_timer[i] == 450:
							%WorldEnvironment.environment.fog_depth_begin = 1
							%WorldEnvironment.environment.fog_depth_end = 2.5
							%WorldEnvironment.environment.ambient_light_color = Color8(SCPGame.brightness, SCPGame.brightness, SCPGame.brightness)
							current_enemy.queue_free()
							floor_timer[i] = 0
				
				FLOOR_ACTION.ACT_173:
					if floor_timer[i] > 1:
						floor_timer[i] += 1
						if current_enemy.enemy_sees and floor_timer[i] > 150:
							if current_enemy.player_sees == true:
								current_enemy.speed = 0.00000000000000001 # Setting this to 0 doesn't work for some reason.
								current_enemy.animate2(current_enemy.current_anim_time,206,250,0.05)
								if floor_timer[i] < 10000:
									play_sound(horror_sfx[2])
									floor_timer[i] = 10001
							else:
								current_enemy.speed = 1.2
						else:
							current_enemy.speed = 0.00000000000000001 # Setting this to 0 doesn't work for some reason.
						if (floor_timer[i] % 660) == 15:
							current_enemy.dontlooksfx.play()
					if player.player_floor > i:
						current_enemy.queue_free()
						floor_timer[i] = 0
				
				FLOOR_ACTION.ACT_TRAP:
					if floor_timer[i] > 2:
						floor_timer[i] += 1
						if floor_timer[i] == 500:
							current_object.queue_free()
							play_sound(StoneSFX)
						if floor_timer[i] == 1000:
							current_enemy.queue_free()
							floor_timer[i] = 0
	
	if floor_timer[player.player_floor] > 0:
		FloorX = 4
		FloorY = (-player.player_floor * 2) - 1
		
		if floor(player.player_floor/2.0) == ceil(player.player_floor/2.0): #parillinen
			# Swapped these values as they were the wrong way around when ran in godot. (Origninal on right comment)
			FloorZ = 0.5 #6.5
			StartX = 0.5 #7.5
			EndX = 7.5 #0.5
		else: #pariton
			FloorZ = 6.5 #0.5
			StartX = 7.5 #0.5
			EndX = 0.5 #7.5
		
		match floor_actions[player.player_floor]:
			
			FLOOR_ACTION.ACT_PROCEED:
				floor_timer[player.player_floor] += 1
				if floor_timer[player.player_floor] == 150:
					play_sound(radio_sfx[0])
					floor_timer[player.player_floor] = 0
			
			FLOOR_ACTION.ACT_RADIO2:
				play_sound(radio_sfx[1]) # signal seems to be getting weaker
				floor_timer[player.player_floor] = 0
			
			FLOOR_ACTION.ACT_RADIO3:
				play_sound(radio_sfx[2]) # good luck
				floor_timer[player.player_floor] = 0
			
			FLOOR_ACTION.ACT_RADIO4:
				play_sound(radio_sfx[3]) # MÖRKÖILYÄ
				floor_timer[player.player_floor] = 0
			
			FLOOR_ACTION.ACT_FLASH:
				if floor_timer[player.player_floor] == 1:
					spawn_debug_marker(Vector3(EndX,FloorY,FloorZ), FLOOR_ACTION.ACT_FLASH, "ACT_FLASH_TRIGGER_1")
					if player.position.distance_to(Vector3(EndX,FloorY,FloorZ)) < 1.5:
						create_enemy(Vector3(EndX,FloorY-0.5,FloorZ))
						current_enemy.lethal = false
						play_sound(horror_sfx[randi_range(0, 2)])
						floor_timer[player.player_floor] = 5
				elif floor_timer[player.player_floor] == 2:
					remove_debug_marker(FLOOR_ACTION.ACT_FLASH)
					spawn_debug_marker(Vector3(FloorX,FloorY,FloorZ), FLOOR_ACTION.ACT_FLASH, "ACT_FLASH_TRIGGER_2")
					if player.position.distance_to(Vector3(FloorX,FloorY,FloorZ)) < 1.5:
						create_enemy(Vector3(FloorX,FloorY-0.5,FloorZ))
						current_enemy.lethal = false
						play_sound(horror_sfx[randi_range(0, 2)])
						floor_timer[player.player_floor] = 5
				elif floor_timer[player.player_floor] == 3:
					spawn_debug_marker(Vector3(StartX,FloorY,FloorZ), FLOOR_ACTION.ACT_FLASH, "ACT_FLASH_TRIGGER_3")
					if player.position.distance_to(Vector3(StartX,FloorY,FloorZ)) < 1.5:
						create_enemy(Vector3(StartX,FloorY-0.5,FloorZ))
						current_enemy.lethal = false
						play_sound(horror_sfx[randi_range(0, 2)])
						floor_timer[player.player_floor] = 5
				else:
					remove_debug_marker(FLOOR_ACTION.ACT_FLASH)
					floor_timer[player.player_floor] += 1
					if floor_timer[player.player_floor] > 30:
						current_enemy.queue_free()
						floor_timer[player.player_floor] = 0
			
			FLOOR_ACTION.ACT_LIGHTS:
				if floor_timer[player.player_floor] == 1:
					if player.position.distance_to(Vector3(FloorX,FloorY,FloorZ)) < 1.0:
						play_sound(horror_sfx[1])
						play_sound(FireOff)
						floor_timer[player.player_floor] = 2
						%WorldEnvironment.environment.ambient_light_color = Color8(25, 25, 25)
			
			FLOOR_ACTION.ACT_STEPS:
				if floor_timer[player.player_floor] == 1:
					sound_temp.stream = LoudStep
					sound_temp.max_polyphony = 3
					floor_timer[player.player_floor] = 2
				elif floor_timer[player.player_floor] < 3000:
					if player.position.distance_to(Vector3(EndX,FloorY,FloorZ)) < 6:
						sound_temp.position = Vector3(FloorX + (FloorX - EndX) * 1.1, FloorY, FloorZ)
						floor_timer[player.player_floor] += 1
						if (floor_timer[player.player_floor] % 150) < randi_range(1, 50):
							sound_temp.play()
							floor_timer[player.player_floor] = 51
			
			FLOOR_ACTION.ACT_BREATH:
				if floor_timer[player.player_floor] == 1:
					floor_timer[player.player_floor] = 2
					sound_temp.stream = BreathSFX
					sound_temp.max_polyphony = 1
				elif floor_timer[player.player_floor] < 3000:
					if player.position.distance_to(Vector3(EndX,FloorY,FloorZ)) < 7:
						sound_temp.position = Vector3(FloorX + (FloorX - EndX) * 1.1, FloorY, FloorZ)
						floor_timer[player.player_floor] += 1
						if (floor_timer[player.player_floor] % 600) < 10:
							sound_temp.play()
							floor_timer[player.player_floor] = 11
			
			FLOOR_ACTION.ACT_RUN:
				if floor_timer[player.player_floor] == 1:
					if player.position.distance_to(Vector3(FloorX,FloorY,FloorZ)) < 3.0:
						play_sound(horror_sfx[1])
						play_sound(FireOff)
						floor_timer[player.player_floor] = 2
						%WorldEnvironment.environment.ambient_light_color = Color8(25, 25, 25)
			
			FLOOR_ACTION.ACT_173:
				if floor_timer[player.player_floor] == 1:
					if floor(player.player_floor/2.0) == ceil(player.player_floor/2.0):
						create_enemy(Vector3(StartX+1.8, FloorY-0.5, FloorZ-6.0), tex173)
					else:
						create_enemy(Vector3(StartX-1.8, FloorY-0.5, FloorZ+6.0), tex173)
					current_enemy.speed = 0.00000000000000001 # Setting this to 0 doesn't work for some reason.
					floor_timer[player.player_floor] = 2
			
			FLOOR_ACTION.ACT_CELL:
				if floor_timer[player.player_floor] == 1:
					if floor(player.player_floor/2.0) == ceil(player.player_floor/2.0):
						create_enemy(Vector3(StartX+4.0, FloorY, FloorZ+2.0), tex173)
					else:
						create_enemy(Vector3(StartX-4.0, FloorY, FloorZ-2.0), tex173)
						current_enemy.rotation_degrees.y = 180
					current_enemy.speed = 0.00000000000000001 # Setting this to 0 doesn't work for some reason.
					floor_timer[player.player_floor] = 2
				else:
					floor_timer[player.player_floor] += 1
					if current_enemy != null:
						current_enemy.animate2(current_enemy.current_anim_time, 206, 250, 3)
						if abs(player.position.x - current_enemy.position.x) < 0.025 and randi_range(1, 40) == 1:
							if current_enemy.speed < 0.1:
								play_sound(horror_sfx[2])
							current_enemy.animate2(0, 0, 0, 0)
							current_enemy.position.z -= 1.5
							floor_timer[player.player_floor] = 0
					if (floor_timer[player.player_floor] % 610) == 5:
						if floor(player.player_floor/2.0) == ceil(player.player_floor/2.0):
							sound_temp.position = Vector3(StartX+4.0, FloorY, FloorZ+2.0)
						else:
							sound_temp.position = Vector3(StartX-4.0, FloorY, FloorZ-2.0)
						sound_temp.stream = BreathSFX
						sound_temp.play()
				
			FLOOR_ACTION.ACT_LOCK:
				spawn_debug_marker(Vector3(FloorX,FloorY,FloorZ), FLOOR_ACTION.ACT_LOCK, "ACT_LOCK_TRIGGER")
				if player.position.distance_to(Vector3(FloorX,FloorY,FloorZ)) < 1.0:
					# This wall is kinda ugly looking, find some way to correct the uvs? Adjust spawn position so player cannot see it appear if they just walk backwards?
					var lock_wall: MeshInstance3D = MeshInstance3D.new()
					var lock_wall_collider: StaticBody3D = StaticBody3D.new()
					var lock_wall_collider_shape: CollisionShape3D = CollisionShape3D.new()
					lock_wall_collider_shape.shape = BoxShape3D.new()
					lock_wall.mesh = BoxMesh.new()
					lock_wall.mesh.size = Vector3(0.5, 2.0, 1.0)
					lock_wall_collider_shape.shape.size = lock_wall.mesh.size
					add_child(lock_wall)
					lock_wall.add_child(lock_wall_collider)
					lock_wall_collider.add_child(lock_wall_collider_shape)
					if floor(player.player_floor/2.0) == ceil(player.player_floor/2.0):
						lock_wall.position = Vector3(StartX+1, FloorY, FloorZ)
					else:
						lock_wall.position = Vector3(StartX-1, FloorY, FloorZ)
					lock_wall.mesh.surface_set_material(0, brickwalltexture_trap)
					sound_temp.position = lock_wall.position
					sound_temp.stream = StoneSFX
					sound_temp.play()
					floor_timer[player.player_floor] = 0
					remove_debug_marker(FLOOR_ACTION.ACT_LOCK)
			
			FLOOR_ACTION.ACT_TRICK1:
				if floor_timer[player.player_floor] == 1:
					if floor(player.player_floor/2.0) == ceil(player.player_floor/2.0):
						spawn_debug_marker(Vector3(StartX+1.0, FloorY-0.25, FloorZ-5.0), FLOOR_ACTION.ACT_TRICK1, "ACT_TRICK1_TRIGGER")
						if player.position.distance_to(Vector3(StartX+1.0, FloorY-0.25, FloorZ-5.0)) < 0.25:
							create_enemy(Vector3(StartX+1.0, FloorY, FloorZ-2.0), tex173)
							current_enemy.speed = 0.6
							floor_timer[player.player_floor] = 2
							play_sound(horror_sfx[2])
							remove_debug_marker(FLOOR_ACTION.ACT_TRICK1)
					else:
						spawn_debug_marker(Vector3(StartX-1.0, FloorY-0.25, FloorZ+5.0), FLOOR_ACTION.ACT_TRICK1, "ACT_TRICK1_TRIGGER")
						if player.position.distance_to(Vector3(StartX-1.0, FloorY-0.25, FloorZ+5.0)) < 0.25:
							create_enemy(Vector3(StartX-1.0, FloorY, FloorZ+2.0), tex173)
							current_enemy.speed = 0.6
							floor_timer[player.player_floor] = 2
							play_sound(horror_sfx[2])
							remove_debug_marker(FLOOR_ACTION.ACT_TRICK1)
			
			FLOOR_ACTION.ACT_TRICK2:
				if floor_timer[player.player_floor] == 1:
					if floor(player.player_floor/2.0) == ceil(player.player_floor/2.0):
						spawn_debug_marker(Vector3(StartX-1.0, FloorY-0.25, FloorZ-5.0), FLOOR_ACTION.ACT_TRICK2, "ACT_TRICK2_TRIGGER")
						if player.position.distance_to(Vector3(StartX-1.0, FloorY-0.25, FloorZ-5.0)) < 0.25:
							create_enemy(Vector3(StartX-1.0, FloorY, FloorZ-2.0), tex173)
							current_enemy.speed = 0.6
							floor_timer[player.player_floor] = 2
							play_sound(horror_sfx[2])
					else:
						spawn_debug_marker(Vector3(StartX+1.0, FloorY-0.25, FloorZ+5.0), FLOOR_ACTION.ACT_TRICK2, "ACT_TRICK2_TRIGGER")
						if player.position.distance_to(Vector3(StartX+1.0, FloorY-0.25, FloorZ+5.0)) < 0.25:
							create_enemy(Vector3(StartX+1.0, FloorY, FloorZ+2.0), tex173)
							current_enemy.speed = 0.6
							floor_timer[player.player_floor] = 2
							play_sound(horror_sfx[2])

			
			FLOOR_ACTION.ACT_TRAP:
				if floor_timer[player.player_floor] == 1:
					var trap_wall: MeshInstance3D = MeshInstance3D.new()
					var trap_wall_collider: StaticBody3D = StaticBody3D.new()
					var trap_wall_collider_shape: CollisionShape3D = CollisionShape3D.new()
					current_object = trap_wall
					trap_wall_collider_shape.shape = BoxShape3D.new()
					trap_wall.mesh = BoxMesh.new()
					trap_wall.mesh.size = Vector3(0.5, 2, 1.0)
					trap_wall_collider_shape.shape.size = trap_wall.mesh.size
					add_child(trap_wall)
					trap_wall.add_child(trap_wall_collider)
					trap_wall_collider.add_child(trap_wall_collider_shape)
					if floor(player.player_floor/2.0) == ceil(player.player_floor/2.0):
						trap_wall.position = Vector3(EndX-0.5, FloorY, FloorZ)
					else:
						trap_wall.position = Vector3(EndX+0.5, FloorY, FloorZ)
					trap_wall.mesh.surface_set_material(0, brickwalltexture_trap)
					floor_timer[player.player_floor] = 2
				elif floor_timer[player.player_floor] == 2:
					if player.position.distance_to(Vector3(FloorX,FloorY,FloorZ)) < 1.0:
						create_enemy(Vector3(StartX, FloorY-0.5, FloorZ))
						current_enemy.speed = 0.6
						play_sound(horror_sfx[randi_range(0, 2)])
						floor_timer[player.player_floor] = 3
			
			FLOOR_ACTION.ACT_ROAR:
				if floor_timer[player.player_floor] == 1:
					if player.position.distance_to(Vector3(EndX,FloorY,FloorZ)) < 6:
						sound_temp.position = Vector3(FloorX, FloorY-3, FloorZ)
						sound_temp.stream = RoarSFX
						sound_temp.play()
						floor_timer[player.player_floor] = 51
				else:
					floor_timer[player.player_floor] += 1
					if floor_timer[player.player_floor] < 370:
						# I figured this would originally just leave your camera at a slight offset if left as is. So now it resets/is left in a correctable state
						player.camera.h_offset = randf_range(-0.005, 0.005)
						player.camera.v_offset = randf_range(-0.005, 0.005)
						player.camera.rotate_x(deg_to_rad(randf_range(-1, 1)))
						player.rotate_y(deg_to_rad(randf_range(-1, 1)))
					else:
						floor_timer[player.player_floor] = 0
						player.camera.h_offset = 0
						player.camera.v_offset = 0
			
			FLOOR_ACTION.ACT_DARKNESS:
				if floor_timer[player.player_floor] == 1:
					if player.position.distance_to(Vector3(FloorX,FloorY,FloorZ)) < 1.0:
						var darkness_wall: MeshInstance3D = MeshInstance3D.new()
						var darkness_wall_collider: StaticBody3D = StaticBody3D.new()
						var darkness_wall_collider_shape: CollisionShape3D = CollisionShape3D.new()
						darkness_wall_collider_shape.shape = BoxShape3D.new()
						darkness_wall.mesh = BoxMesh.new()
						darkness_wall.mesh.size = Vector3(0.5, 1, 0.5)
						darkness_wall_collider_shape.shape.size = darkness_wall.mesh.size
						add_child(darkness_wall)
						darkness_wall.add_child(darkness_wall_collider)
						darkness_wall_collider.add_child(darkness_wall_collider_shape)
						darkness_wall.mesh.surface_set_material(0, brickwalltexture)
						if floor(player.player_floor/2.0) == ceil(player.player_floor/2.0):
							darkness_wall.position = Vector3(EndX+0.5, FloorY, FloorZ)
						else:
							darkness_wall.position = Vector3(EndX-0.5, FloorY, FloorZ)
						sound_temp.position = darkness_wall.position
						sound_temp.stream = StoneSFX
						sound_temp.play()
						floor_timer[player.player_floor] = 2
				elif floor_timer[player.player_floor] < 600:
					floor_timer[player.player_floor] += 1
					var temp: float = maxf(SCPGame.brightness - (floor_timer[player.player_floor] / 600.0) * SCPGame.brightness, 10)
					%WorldEnvironment.environment.ambient_light_color = Color8(temp, temp, temp)
					if floor_timer[player.player_floor] == 600:
						create_enemy(Vector3(FloorX, FloorY-0.5, FloorZ))
						current_enemy.speed = 0.01
						play_sound(horror_sfx[randi_range(0, 2)])
						floor_timer[player.player_floor] = 601

func create_enemy(spawn_at: Vector3, material: StandardMaterial3D = load("res://gfx/mat/mental.material")) -> SCPEnemy:
	if current_enemy != null:
		current_enemy.queue_free()
		current_enemy = null
	var enemy: SCPEnemy = load("res://obj/enemy.res").instantiate()
	enemy.position = spawn_at
	enemy.override_material(material)
	current_enemy = enemy
	enemy.player = player
	add_child(enemy)
	print("Created enemy at ", spawn_at)
	return enemy

# Debug marker functions

func spawn_debug_marker(pos: Vector3, id: int = randi(), desc: String = "DebugMarker"):
	var marker_dup: bool = false
	for marker in get_tree().get_nodes_in_group("debugmarkers"):
		if marker.id == FLOOR_ACTION.ACT_LOCK:
			marker_dup = true
			break
	if !marker_dup:
		var new_marker: SCPDebugMarker = SCPDebugMarker.new(id, desc)
		new_marker.position = pos
		add_child(new_marker)
		return new_marker
	return null

func remove_debug_marker(id:int):
	for marker in get_tree().get_nodes_in_group("debugmarkers"):
		if marker.id == id:
			marker.queue_free()
			break
