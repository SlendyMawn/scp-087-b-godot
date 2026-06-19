class_name SCPEnemy
extends CharacterBody3D

var current_anim_time: float
var speed: float # FIXME: Attempts to set this value to 0 seem to, fail? Setting up a setter with a print will display that the value was changed, and this change will be reflected in the input in the editor. But it just... wont?
var enemy_sees: bool
var player_sees: bool
var lethal: bool = true
var player: SCPPlayer
@onready var dontlooksfx: AudioStreamPlayer3D = $DontLookSFX

# Legacy Blitz3D function - Replace later!
func animate2(current: float, start: int, quit:int, speed: float):
	$model/AnimationPlayer.seek(current + speed)
	current_anim_time = $model/AnimationPlayer.current_animation_position
	if current_anim_time > quit:
		$model/AnimationPlayer.seek(start)
	if current_anim_time < start:
		$model/AnimationPlayer.seek(quit)

func _process(delta: float) -> void:
	$SCPDebugMarker.position = position # Somehow this wasn't a given?
	current_anim_time = $model/AnimationPlayer.current_animation_position
	$OcclusionCast.target_position = to_local(player.position)
	enemy_sees = $OcclusionCast.get_collider() == player
	if enemy_sees and player_sees:
		player.blur_timer = 200
func _physics_process(delta: float) -> void:
	var dir: Vector3
	if player and enemy_sees:
		look_at(player.position)
		rotation.x = 0
		rotation.z = 0
		velocity = -transform.basis.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y = -0.1
	move_and_slide()


func _on_kill_zone_body_entered(body: Node3D) -> void:
	if "killtimer" in body and lethal:
		if body.invuln == false:
			body.killtimer = max(body.killtimer, 1)


func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	player_sees = true


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	player_sees = false

func override_material(material: StandardMaterial3D):
	$model/Skeleton3D/Skeleton.set_surface_override_material(0, material)
