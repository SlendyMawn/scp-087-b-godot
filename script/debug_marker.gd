## Debug marker, shown to player when accessing the debug menu.
class_name SCPDebugMarker
extends Node3D

@export var description: String
@export var id: int

func _init(new_id: int = randi(), new_desc: String = name) -> void:
	description = new_desc
	id = new_id

func _ready() -> void:
	add_to_group("debugmarkers")
