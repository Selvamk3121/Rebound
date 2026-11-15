class_name SectorDoor
extends Interactable

# REBOUND - Interactive Sector Door
# Handles Hallway Gates, Sector Bulkheads, and Safe Room Exit Airlocks.

enum DoorType {
	HALLWAY_GATE,
	EXIT_AIRLOCK
}

@export var door_type: DoorType = DoorType.HALLWAY_GATE
@export var is_open: bool = false
@export var target_scene: String = "res://scenes/armoury/safe_room.tscn"

@onready var sprite: Sprite2D = $Sprite2D
@onready var blocker: StaticBody2D = $StaticBody2D

func _ready() -> void:
	super._ready()
	_update_door_state()

func _update_door_state() -> void:
	if blocker:
		blocker.set_collision_layer_value(1, not is_open)
	
	if is_open:
		if sprite:
			sprite.modulate = Color(0.3, 1.0, 0.4, 0.3)
		set_prompt("Door Open")
		is_interactable = false
	else:
		if sprite:
			sprite.modulate = Color.WHITE
		if door_type == DoorType.HALLWAY_GATE:
			set_prompt("Open Bulkhead Door")
			is_interactable = true
		elif door_type == DoorType.EXIT_AIRLOCK:
			set_prompt("Enter Safe Room")

func unlock_exit_airlock() -> void:
	if door_type == DoorType.EXIT_AIRLOCK:
		is_interactable = true
		if sprite:
			sprite.modulate = Color(0.2, 0.9, 0.3, 1.0)
		set_prompt("Enter Safe Room Airlock")

func _on_interacted(_player: Player) -> void:
	if door_type == DoorType.HALLWAY_GATE:
		is_open = true
		_update_door_state()
		AudioManager.play_sfx("door_open", 1.0)
	elif door_type == DoorType.EXIT_AIRLOCK:
		AudioManager.play_sfx("door_open", 1.2)
		if target_scene != "":
			get_tree().change_scene_to_file(target_scene)
