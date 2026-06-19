class_name AudioOneShot
extends AudioStreamPlayer

func _init(sound: AudioStream) -> void:
	stream = sound
	finished.connect(queue_free)

func _ready() -> void:
	play()
