class_name SecurityDoor
extends StaticBody2D

# REBOUND - Fuse & Power-Controlled Security Door
# Physics collision and visual state update dynamically based on power source.

signal door_state_changed(is_open: bool)

@export var door_name: String = "Sector Security Bulkhead"
@export var is_open: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var status_light: Sprite2D = $StatusLight

func _ready() -> void:
	_update_door_state(is_open, false)

func set_power(has_power: bool) -> void:
	if is_open == has_power:
		return
	_update_door_state(has_power, true)

func _update_door_state(opened: bool, play_audio: bool = true) -> void:
	is_open = opened
	
	# Layer 1: Walls
	set_collision_layer_value(1, not is_open)
	
	if is_open:
		if sprite:
			sprite.modulate = Color(0.3, 1.0, 0.4, 0.4)
		if status_light:
			status_light.modulate = Color(0.2, 1.0, 0.3, 1.0)
		if play_audio:
			AudioManager.play_sfx("door_open", 1.1)
	else:
		if sprite:
			sprite.modulate = Color.WHITE
		if status_light:
			status_light.modulate = Color(1.0, 0.2, 0.2, 1.0)
		if play_audio:
			AudioManager.play_sfx("door_open", 0.8)
			
	door_state_changed.emit(is_open)
