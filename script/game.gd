extends Node

enum Difficulty {EASY, NORMAL, HARD, CUSTOM}

# Global Settings
#TODO: Save some of these to appdata as user prefs
var brightness: int = 40

var difficulty: Difficulty = Difficulty.EASY:
	set(new_diff):
		match new_diff:
			Difficulty.EASY:
				num_floors = 210
				misc_difficulty = new_diff
			Difficulty.NORMAL:
				num_floors = 256
				misc_difficulty = new_diff
			Difficulty.HARD:
				num_floors = 300
				misc_difficulty = new_diff
		difficulty = new_diff

var misc_difficulty: Difficulty = Difficulty.EASY

var num_floors: int = 210

var show_fps: bool = false

var look_sensitivity_mouse: float = 0.3

var look_sensitivity_gamepad: float = 2.0

var using_gamepad: bool = false:
	set(new_gamepad):
		using_gamepad = new_gamepad
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if using_gamepad else Input.MOUSE_MODE_VISIBLE

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func load_scene(scene: String):
	var loading: Control = preload("res://scn/loading.scn").instantiate()
	loading.scene = scene
	# Remove everything except ourselves and anything marked as PersistUntilReady
	for child in get_tree().root.get_children():
		if child is not SCPGame:
			if child.is_in_group("PersistUntilReady"):
				loading.remove_onready.append(child)
			else:
				child.queue_free()
	get_tree().root.add_child(loading)

# Account for input inprecision
const MOUSE_INPRECISION_THRESHOLD: float = 10.0
const GAMEPAD_INPRECISION_THRESHOLD: float = 0.1

#FIXME: This doesn't reenable mouse on the pause screen specifically for some reason
func _input(event: InputEvent) -> void:
	# If user made their last input using a gamepad, hide the mouse as they probably aren't using it.
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and (event.axis_value > GAMEPAD_INPRECISION_THRESHOLD or event.axis_value < -GAMEPAD_INPRECISION_THRESHOLD)):
		using_gamepad = true
	elif event is InputEventMouseMotion and event.velocity and (event.relative.x > MOUSE_INPRECISION_THRESHOLD or event.relative.x < -MOUSE_INPRECISION_THRESHOLD or event.relative.y > MOUSE_INPRECISION_THRESHOLD or event.relative.y < -MOUSE_INPRECISION_THRESHOLD):
		using_gamepad = false
	elif event is InputEventKey:
		using_gamepad = false
