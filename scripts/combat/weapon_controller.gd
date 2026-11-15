class_name WeaponController
extends Node2D

# REBOUND - Weapon Controller Component
# Handles multi-weapon switching, firing mechanics, ammunition cycles, and trajectory line updates.

signal ammo_changed(current: int, max_val: int, reserve: int)
signal weapon_changed(weapon: WeaponData)
signal reload_started
signal reload_finished
signal magazine_full

@export var projectile_scene: PackedScene = preload("res://scenes/weapons/ricochet_projectile.tscn")
@export var trajectory_line: TrajectoryLine

var weapons: Dictionary = {}
var current_weapon: WeaponData = null
var current_slot: int = 2 # Start with signature Ricochet Gun

var fire_timer: float = 0.0
var reload_timer: float = 0.0
var is_reloading: bool = false

func _ready() -> void:
	_load_default_weapons()
	var start_slot: int = 1
	if GameManager.is_weapon_unlocked(current_slot):
		start_slot = current_slot
	select_weapon(start_slot)

func _load_default_weapons() -> void:
	weapons[1] = load("res://resources/weapons/standard_weapon.tres").duplicate()
	weapons[2] = load("res://resources/weapons/ricochet_weapon.tres").duplicate()
	weapons[3] = load("res://resources/weapons/advanced_weapon.tres").duplicate()
	weapons[4] = load("res://resources/weapons/heavy_weapon.tres").duplicate()
	
	# Apply persistent ammo values across level transitions
	for slot_idx in weapons:
		var w = weapons[slot_idx]
		var saved = GameManager.get_weapon_ammo(slot_idx)
		if saved != null and w != null:
			w.current_ammo = saved["current"]
			w.reserve_ammo = saved["reserve"]

func cycle_weapon(direction: int) -> void:
	var unlocked: Array = []
	for k in [1, 2, 3, 4]:
		if weapons.has(k) and GameManager.is_weapon_unlocked(k):
			unlocked.append(k)
	if unlocked.is_empty():
		return
	var current_idx = unlocked.find(current_slot)
	if current_idx == -1:
		current_idx = 0
	var new_idx = (current_idx + direction) % unlocked.size()
	if new_idx < 0:
		new_idx += unlocked.size()
	select_weapon(unlocked[new_idx])

func get_effective_damage() -> int:
	if not current_weapon:
		return 15
	return current_weapon.damage + GameManager.gun_damage_bonus

func get_effective_bounces() -> int:
	if not current_weapon:
		return 0
	return current_weapon.max_bounces + GameManager.gun_bounce_bonus

func get_effective_max_ammo() -> int:
	if not current_weapon:
		return 10
	return current_weapon.max_ammo + GameManager.gun_mag_bonus

func get_effective_reload_time() -> float:
	if not current_weapon:
		return 1.0
	return current_weapon.reload_time * GameManager.gun_reload_multiplier

func _process(delta: float) -> void:
	if fire_timer > 0.0:
		fire_timer -= delta
		
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_complete_reload()

func update_trajectory_preview(muzzle_pos: Vector2, aim_dir: Vector2, exclude_rids: Array[RID] = []) -> void:
	if not trajectory_line:
		return
		
	var eff_bounces: int = get_effective_bounces()
	if current_weapon and eff_bounces > 0 and current_weapon.preview_distance > 0.0:
		trajectory_line.update_trajectory(
			muzzle_pos,
			aim_dir,
			eff_bounces,
			current_weapon.preview_distance,
			exclude_rids
		)
	else:
		trajectory_line.clear_trajectory()

func select_weapon(slot_index: int) -> void:
	if not weapons.has(slot_index) or weapons[slot_index] == null:
		return
	if not GameManager.is_weapon_unlocked(slot_index):
		return
		
	if is_reloading:
		is_reloading = false
		
	current_slot = slot_index
	current_weapon = weapons[slot_index]
	weapon_changed.emit(current_weapon)
	ammo_changed.emit(current_weapon.current_ammo, get_effective_max_ammo(), current_weapon.reserve_ammo)

func can_fire() -> bool:
	return fire_timer <= 0.0 and not is_reloading and current_weapon != null and current_weapon.current_ammo > 0

func fire(muzzle_pos: Vector2, aim_dir: Vector2, world_root: Node2D) -> bool:
	if not can_fire():
		if current_weapon and current_weapon.current_ammo <= 0 and not is_reloading:
			start_reload()
		return false
		
	fire_timer = current_weapon.fire_rate
	current_weapon.current_ammo -= 1
	GameManager.save_weapon_ammo(current_slot, current_weapon.current_ammo, current_weapon.reserve_ammo)
	ammo_changed.emit(current_weapon.current_ammo, get_effective_max_ammo(), current_weapon.reserve_ammo)
	
	# Spawn physical projectiles (supports multi-pellet spread)
	if projectile_scene and world_root:
		var pellet_count: int = current_weapon.pellets if current_weapon.pellets > 0 else 1
		var spread: float = current_weapon.spread_angle
		for i in range(pellet_count):
			var angle_offset: float = 0.0
			if pellet_count > 1:
				angle_offset = lerp(-spread, spread, float(i) / float(pellet_count - 1))
			var shot_dir: Vector2 = aim_dir.rotated(angle_offset)
			var proj: RicochetProjectile = projectile_scene.instantiate()
			world_root.add_child(proj)
			proj.initialize(
				muzzle_pos,
				shot_dir,
				get_effective_damage(),
				current_weapon.projectile_speed,
				get_effective_bounces(),
				current_weapon.projectile_texture
			)
		
	var sfx: String = current_weapon.sfx_name if current_weapon.sfx_name != "" else "laser_fire"
	AudioManager.play_sfx(sfx, randf_range(0.96, 1.04))
	
	if current_weapon.current_ammo <= 0:
		start_reload()
		
	return true

func start_reload() -> void:
	if is_reloading or current_weapon == null:
		return
	if current_weapon.current_ammo >= get_effective_max_ammo():
		magazine_full.emit()
		AudioManager.play_sfx("click", 1.4)
		return
	if current_weapon.reserve_ammo <= 0:
		AudioManager.play_sfx("click", 0.6)
		return
		
	is_reloading = true
	reload_timer = get_effective_reload_time()
	reload_started.emit()
	AudioManager.play_sfx("reload")

func _complete_reload() -> void:
	is_reloading = false
	if current_weapon:
		var needed: int = get_effective_max_ammo() - current_weapon.current_ammo
		var amount: int = min(needed, current_weapon.reserve_ammo)
		current_weapon.current_ammo += amount
		current_weapon.reserve_ammo -= amount
		GameManager.save_weapon_ammo(current_slot, current_weapon.current_ammo, current_weapon.reserve_ammo)
		ammo_changed.emit(current_weapon.current_ammo, get_effective_max_ammo(), current_weapon.reserve_ammo)
	reload_finished.emit()

func add_reserve_ammo(slot_index: int, amount: int) -> void:
	if weapons.has(slot_index) and weapons[slot_index] != null:
		weapons[slot_index].reserve_ammo += amount
		GameManager.save_weapon_ammo(slot_index, weapons[slot_index].current_ammo, weapons[slot_index].reserve_ammo)
		if slot_index == current_slot:
			ammo_changed.emit(current_weapon.current_ammo, current_weapon.max_ammo, current_weapon.reserve_ammo)

func upgrade_current_weapon(level: int) -> void:
	if current_weapon:
		current_weapon.apply_upgrade_level(level)
		ammo_changed.emit(current_weapon.current_ammo, current_weapon.max_ammo, current_weapon.reserve_ammo)
