class_name Player
extends CharacterBody2D

signal health_changed(current: int, max_val: int)
signal stamina_changed(current: float, max_val: float)
signal died
signal weapon_switched(weapon_index: int)

@export var speed: float = 110.0
@export var sprint_speed: float = 190.0
@export var max_health: int = 100
var current_health: int = 100

@export var max_stamina: float = 100.0
var current_stamina: float = 100.0
var stamina_drain_rate: float = 25.0
var stamina_recharge_rate: float = 22.0
var stamina_recharge_delay: float = 1.2
var stamina_delay_timer: float = 0.0
var is_sprinting: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle
@onready var muzzle_flash: Sprite2D = $WeaponPivot/Muzzle/MuzzleFlash
@onready var camera: Camera2D = $Camera2D
@onready var weapon_controller: WeaponController = $WeaponController
@onready var trajectory_line: TrajectoryLine = $TrajectoryLine

var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	current_stamina = max_stamina
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(current_stamina, max_stamina)
	if weapon_controller:
		if trajectory_line:
			weapon_controller.trajectory_line = trajectory_line
		weapon_controller.weapon_changed.connect(_on_weapon_changed)
		if weapon_controller.current_weapon:
			_on_weapon_changed(weapon_controller.current_weapon)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
		
	_handle_stamina(delta)
	_handle_movement()
	_handle_aim()
	
	if weapon_controller and muzzle:
		var aim_dir = get_aim_direction()
		weapon_controller.update_trajectory_preview(muzzle.global_position, aim_dir, [get_rid()])

func _handle_stamina(delta: float) -> void:
	var wants_sprint = (Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)) and velocity.length_squared() > 10.0
	if wants_sprint and current_stamina > 0.0:
		is_sprinting = true
		current_stamina = max(0.0, current_stamina - stamina_drain_rate * delta)
		stamina_delay_timer = stamina_recharge_delay
		stamina_changed.emit(current_stamina, max_stamina)
	else:
		is_sprinting = false
		if stamina_delay_timer > 0.0:
			stamina_delay_timer -= delta
		elif current_stamina < max_stamina:
			current_stamina = min(max_stamina, current_stamina + stamina_recharge_rate * delta)
			stamina_changed.emit(current_stamina, max_stamina)

func _input(event: InputEvent) -> void:
	if is_dead:
		return
		
	if event.is_action_pressed("reload") or _is_key_pressed(event, KEY_R):
		if weapon_controller:
			weapon_controller.start_reload()
			get_viewport().set_input_as_handled()

func _is_key_pressed(event: InputEvent, key: Key) -> bool:
	if event is InputEventKey and event.pressed and not event.is_echo():
		return event.keycode == key or event.physical_keycode == key or event.key_label == key
	return false

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
		
	if event.is_action_pressed("fire"):
		_fire_weapon()
	elif event.is_action_pressed("reload") or _is_key_pressed(event, KEY_R):
		if weapon_controller:
			weapon_controller.start_reload()
	elif _is_key_pressed(event, KEY_H):
		use_medical_kit()
	elif event.is_action_pressed("weapon_1") or _is_key_pressed(event, KEY_1):
		switch_weapon(1)
	elif event.is_action_pressed("weapon_2") or _is_key_pressed(event, KEY_2):
		switch_weapon(2)
	elif event.is_action_pressed("weapon_3") or _is_key_pressed(event, KEY_3):
		switch_weapon(3)
	elif _is_key_pressed(event, KEY_4) or (InputMap.has_action("weapon_4") and event.is_action_pressed("weapon_4")):
		switch_weapon(4)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cycle_weapon(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cycle_weapon(1)

func _handle_movement() -> void:
	var input_direction: Vector2 = Vector2.ZERO
	input_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()
		
	var target_speed = sprint_speed if is_sprinting else speed
	velocity = input_direction * target_speed
	move_and_slide()

func _handle_aim() -> void:
	var aim_dir: Vector2 = get_aim_direction()
	if aim_dir != Vector2.ZERO:
		weapon_pivot.rotation = aim_dir.angle()
		rotation = lerp_angle(rotation, aim_dir.angle(), 0.2)

func get_aim_direction() -> Vector2:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - global_position).normalized()
	return dir if dir != Vector2.ZERO else Vector2.RIGHT

func _fire_weapon() -> void:
	if weapon_controller and muzzle:
		var aim_dir: Vector2 = get_aim_direction()
		var scene_root: Node2D = get_tree().current_scene as Node2D
		var fired = weapon_controller.fire(muzzle.global_position, aim_dir, scene_root)
		if fired and muzzle_flash and weapon_controller.current_weapon:
			if weapon_controller.current_weapon.muzzle_flash_texture:
				muzzle_flash.texture = weapon_controller.current_weapon.muzzle_flash_texture
			muzzle_flash.show()
			var t = create_tween()
			t.tween_property(muzzle_flash, "scale", Vector2(1.5, 1.5), 0.04)
			t.tween_callback(muzzle_flash.hide)
			t.tween_property(muzzle_flash, "scale", Vector2(1.0, 1.0), 0.01)

func switch_weapon(index: int) -> void:
	if weapon_controller:
		weapon_controller.select_weapon(index)
	weapon_switched.emit(index)
	AudioManager.play_sfx("click")

func cycle_weapon(direction: int) -> void:
	if weapon_controller:
		weapon_controller.cycle_weapon(direction)
		weapon_switched.emit(weapon_controller.current_slot)
		AudioManager.play_sfx("click")

func _on_weapon_changed(weapon: WeaponData) -> void:
	if not weapon:
		return
	if sprite:
		sprite.frame = weapon.sprite_frame
	if muzzle:
		muzzle.position = weapon.muzzle_offset

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	AudioManager.play_sfx("hit")
	
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	if is_dead:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func use_medical_kit() -> bool:
	if is_dead or current_health >= max_health:
		return false
	if InventoryManager.has_item("medkit"):
		InventoryManager.remove_item("medkit", 1)
		heal(40)
		AudioManager.play_sfx("pickup")
		return true
	return false

func die() -> void:
	is_dead = true
	died.emit()
	if trajectory_line:
		trajectory_line.clear_trajectory()
	GameManager.notify_player_death()
