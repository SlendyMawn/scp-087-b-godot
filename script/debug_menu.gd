class_name SCPDebugMenu
extends Control

var world: SCPWorld
var player: SCPPlayer

func _draw() -> void:
	for marker in get_tree().get_nodes_in_group("debugmarkers"):
		if player.camera.is_position_in_frustum(marker.position):
			var unprojected: Vector2 = player.camera.unproject_position(marker.position)
			draw_circle(unprojected, 6, Color(1.0, 0.0, 0.0, 1.0))
			draw_string(preload("res://gfx/fnt/COURE.ttf"), unprojected + Vector2(0, 16), str(marker.position), HORIZONTAL_ALIGNMENT_CENTER)
			draw_string(preload("res://gfx/fnt/COURE.ttf"), unprojected + Vector2(0, 32), marker.description, HORIZONTAL_ALIGNMENT_CENTER)

func _process(delta: float) -> void:
	var pong_dark:float = 1.0 - snappedf(Time.get_ticks_msec() % 1000, 256) / 2000
	if player and world:
		$"BG/DebugMenuContainer/[X]PlayerPos".text = "PlayerPos: " + str(player.position.snappedf(0.001))
		$"BG/DebugMenuContainer/[X]PlayerRot".text = "PlayerRot: " + "(" + str(snappedf(player.camera.rotation_degrees.x, 0.001)) + ", " + str(snappedf(player.rotation_degrees.y, 0.001)) + ", " + str(snappedf(player.rotation_degrees.z, 0.001)) + ")"
		$"BG/DebugMenuContainer/[X]PlayerFloor".text = "PlayerFloor: " + str(player.player_floor + 1)
		$"BG/DebugMenuContainer/[X]KillTimer".text = "KillTimer: " + str(player.killtimer)
		$BG/DebugMenuContainer/Invuln.text = "Invuln: " + str(player.invuln)
		$"BG/DebugMenuContainer/[X]FloorAct".text = "FloorAct: " + world.FLOOR_ACTION.find_key(world.floor_actions[player.player_floor])
		$"BG/DebugMenuContainer/[X]FloorTimer".text = "FloorTimer: " + str(world.floor_timer[player.player_floor])
		$"BG/DebugMenuContainer/[X]NumFloors".text = "NUM_FLOORS: " + str(SCPGame.num_floors)
		$"BG/DebugMenuContainer/[X]Brightness".text = "BRIGHTNESS: " + str(SCPGame.brightness)
		match get_viewport().debug_draw:
			Viewport.DEBUG_DRAW_DISABLED:
				$BG/DebugMenuContainer/ViewModeContainer/Shaded.add_theme_color_override("font_color", Color(pong_dark, pong_dark, pong_dark, 1.0))
				$BG/DebugMenuContainer/ViewModeContainer/Unshaded.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25, 1.0))
				$BG/DebugMenuContainer/ViewModeContainer/Wireframe.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25, 1.0))
			Viewport.DEBUG_DRAW_UNSHADED:
				$BG/DebugMenuContainer/ViewModeContainer/Shaded.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25, 1.0))
				$BG/DebugMenuContainer/ViewModeContainer/Unshaded.add_theme_color_override("font_color", Color(pong_dark, pong_dark, pong_dark, 1.0))
				$BG/DebugMenuContainer/ViewModeContainer/Wireframe.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25, 1.0))
			Viewport.DEBUG_DRAW_WIREFRAME:
				$BG/DebugMenuContainer/ViewModeContainer/Shaded.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25, 1.0))
				$BG/DebugMenuContainer/ViewModeContainer/Unshaded.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25, 1.0))
				$BG/DebugMenuContainer/ViewModeContainer/Wireframe.add_theme_color_override("font_color", Color(pong_dark, pong_dark, pong_dark, 1.0))
		if world.current_enemy:
			$"BG/DebugMenuContainer/[X]EnemyPos".text = "EnemyPos: " + str(world.current_enemy.position.snappedf(0.001))
			$"BG/DebugMenuContainer/[X]EnemyRot".text = "EnemyRot: " + str(world.current_enemy.rotation_degrees.snappedf(0.001))
			$"BG/DebugMenuContainer/[X]EnemySpeed".text = "EnemySpeed: " + str(world.current_enemy.speed)
			$"BG/DebugMenuContainer/[X]EnemyLethal".text = "EnemyLethal: " + str(world.current_enemy.lethal)
		else:
			$"BG/DebugMenuContainer/[X]EnemyPos".text = "EnemyPos: null"
			$"BG/DebugMenuContainer/[X]EnemyRot".text = "EnemyRot: null"
			$"BG/DebugMenuContainer/[X]EnemySpeed".text = "EnemySpeed: null"
			$"BG/DebugMenuContainer/[X]EnemyLethal".text = "EnemyLethal: null"
	queue_redraw()
