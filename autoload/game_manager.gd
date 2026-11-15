extends Node

# REBOUND - Game Manager Autoload
# Responsible for high-level game state, pause status, and sector transitions.

signal game_paused(is_paused: bool)
signal player_died
signal objective_updated(objective_text: String)
signal level_changed(level_id: String)

enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

var current_state: GameState = GameState.PLAYING
var current_level_id: String = "level_01_security"
var is_game_paused: bool = false
var credits: int = 0:
	set(value):
		credits = max(0, value)
		credits_changed.emit(credits)

signal credits_changed(new_amount: int)

# Progression, Weapons, and Upgrades
var current_level_number: int = 1
const MAX_LEVELS: int = 5
var has_shown_pickup_prompt: bool = false
var unlocked_weapons: Array[int] = [1] # Only pistol at start

# Persistent Ammunition across levels: { slot_index: { "current": int, "reserve": int } }
var weapon_ammo_state: Dictionary = {
	1: {"current": 12, "reserve": 36},
	2: {"current": 8, "reserve": 24},
	3: {"current": 6, "reserve": 18},
	4: {"current": 20, "reserve": 60}
}

const LEVEL_SCENES: Dictionary = {
	1: "res://scenes/levels/test_level.tscn",
	2: "res://scenes/levels/level_02_reactor.tscn",
	3: "res://scenes/levels/level_03_containment.tscn",
	4: "res://scenes/levels/level_04_labs.tscn",
	5: "res://scenes/levels/level_05_hive.tscn"
}

var gun_damage_bonus: int = 0
var gun_bounce_bonus: int = 0
var gun_mag_bonus: int = 0
var gun_reload_multiplier: float = 1.0

signal weapon_unlocked(slot: int)
signal gun_upgraded(stat: String, new_val: Variant)

func save_weapon_ammo(slot: int, current_val: int, reserve_val: int) -> void:
	weapon_ammo_state[slot] = {"current": current_val, "reserve": reserve_val}

func get_weapon_ammo(slot: int) -> Variant:
	if weapon_ammo_state.has(slot):
		return weapon_ammo_state[slot]
	return null

func get_monster_health_multiplier() -> float:
	return 1.0 + float(current_level_number - 1) * 0.25

func get_monster_damage_multiplier() -> float:
	return 1.0 + float(current_level_number - 1) * 0.15

func get_level_scene_path(lvl: int) -> String:
	return LEVEL_SCENES.get(lvl, LEVEL_SCENES[1])

func unlock_weapon(slot: int) -> void:
	if not unlocked_weapons.has(slot):
		unlocked_weapons.append(slot)
		unlocked_weapons.sort()
		weapon_unlocked.emit(slot)

func is_weapon_unlocked(slot: int) -> bool:
	return unlocked_weapons.has(slot)

func upgrade_gun_stat(stat_type: String, cost: int) -> bool:
	if spend_credits(cost):
		match stat_type:
			"damage":
				gun_damage_bonus += 5
				gun_upgraded.emit("damage", gun_damage_bonus)
			"bounce":
				gun_bounce_bonus += 1
				gun_upgraded.emit("bounce", gun_bounce_bonus)
			"magazine":
				gun_mag_bonus += 4
				gun_upgraded.emit("magazine", gun_mag_bonus)
			"reload":
				gun_reload_multiplier = max(0.4, gun_reload_multiplier - 0.15)
				gun_upgraded.emit("reload", gun_reload_multiplier)
		return true
	return false

func reset_run() -> void:
	current_level_number = 1
	has_shown_pickup_prompt = false
	unlocked_weapons = [1]
	weapon_ammo_state = {
		1: {"current": 12, "reserve": 36},
		2: {"current": 8, "reserve": 24},
		3: {"current": 6, "reserve": 18},
		4: {"current": 20, "reserve": 60}
	}
	gun_damage_bonus = 0
	gun_bounce_bonus = 0
	gun_mag_bonus = 0
	gun_reload_multiplier = 1.0
	credits = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_fallback_inputs()

func _setup_fallback_inputs() -> void:
	var default_actions = {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"interact": [KEY_E],
		"reload": [KEY_R],
		"inventory": [KEY_I],
		"sprint": [KEY_SHIFT],
		"weapon_1": [KEY_1],
		"weapon_2": [KEY_2],
		"weapon_3": [KEY_3],
		"weapon_4": [KEY_4],
		"pause": [KEY_ESCAPE]
	}
	
	for action in default_actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in default_actions[action]:
				var ev = InputEventKey.new()
				ev.physical_keycode = key
				ev.keycode = key
				InputMap.action_add_event(action, ev)
				
	# Ensure reload always has explicit keycode and physical_keycode fallback
	if InputMap.has_action("reload"):
		var r_key = InputEventKey.new()
		r_key.keycode = KEY_R
		InputMap.action_add_event("reload", r_key)
		var r_phys = InputEventKey.new()
		r_phys.physical_keycode = KEY_R
		InputMap.action_add_event("reload", r_phys)
				
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		var space_ev = InputEventKey.new()
		space_ev.physical_keycode = KEY_SPACE
		InputMap.action_add_event("fire", space_ev)
		var m_ev = InputEventMouseButton.new()
		m_ev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", m_ev)

func toggle_pause() -> void:
	if current_state == GameState.GAME_OVER or current_state == GameState.MAIN_MENU:
		return
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	current_state = GameState.PAUSED if is_game_paused else GameState.PLAYING
	game_paused.emit(is_game_paused)

func add_credits(amount: int) -> void:
	credits += amount

func spend_credits(amount: int) -> bool:
	if credits >= amount:
		credits -= amount
		return true
	return false

func notify_player_death() -> void:
	current_state = GameState.GAME_OVER
	player_died.emit()
