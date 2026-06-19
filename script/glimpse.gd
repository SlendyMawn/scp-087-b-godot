class_name SCPGlimpse
extends Node3D

func _ready() -> void:
	if randi_range(0, 1) == 1:
		$Sprite3D.texture = preload("res://gfx/tex/glimpse2.png")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is SCPPlayer:
		$NoSFX.play()
		hide()
		await $NoSFX.finished
		queue_free()
