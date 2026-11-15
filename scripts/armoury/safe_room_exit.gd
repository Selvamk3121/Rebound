class_name SafeRoomExit
extends Interactable

# REBOUND - Safe Zone Airlock Transition to Next Combat Sector

func _ready() -> void:
	super._ready()
	var next_lvl = GameManager.current_level_number + 1
	if next_lvl <= GameManager.MAX_LEVELS:
		set_prompt("Press [E] to Enter Sector %02d" % next_lvl)
	else:
		set_prompt("Press [E] to Finalize Facility Evacuation")

func _on_interacted(_player: Player) -> void:
	GameManager.current_level_number += 1
	AudioManager.play_sfx("door_open")
	if GameManager.current_level_number > GameManager.MAX_LEVELS:
		GameManager.current_state = GameManager.GameState.VICTORY
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_victory_screen"):
			hud.show_victory_screen(50, GameManager.credits)
	else:
		var scene_path = GameManager.get_level_scene_path(GameManager.current_level_number)
		get_tree().change_scene_to_file(scene_path)
