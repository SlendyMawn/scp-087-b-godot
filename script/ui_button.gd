class_name SCPButton
extends Button

var click_sfx: AudioStreamPlayer = AudioStreamPlayer.new()
@export var click_sound: AudioStream = preload("res://sfx/button.ogg")

func _init() -> void:
	click_sfx.stream = click_sound
	add_child(click_sfx)

func _pressed() -> void:
	if !disabled:
		click_sfx.play()
