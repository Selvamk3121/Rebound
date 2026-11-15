class_name ControlPanel
extends Interactable

# REBOUND - Electrical Control Panel & Fuse Socket
# Directly controls circuit power to linked Security Doors based on Fuse presence.

signal circuit_state_changed(has_fuse: bool, power_active: bool)

@export var target_door: SecurityDoor
@export var has_fuse: bool = false
@export var power_switch_on: bool = false

@onready var panel_sprite: Sprite2D = $Sprite2D
@onready var fuse_socket_sprite: Sprite2D = $FuseSocket

func _ready() -> void:
	super._ready()
	_update_circuit_status()

func _process(_delta: float) -> void:
	_update_prompt_text()

func _update_prompt_text() -> void:
	if not has_fuse:
		if InventoryManager.has_item("fuse"):
			set_prompt("Insert 50A Fuse")
		else:
			set_prompt("Panel Offline (Requires 50A Fuse)")
	else:
		if power_switch_on:
			set_prompt("Remove Fuse (Cuts Door Power)")
		else:
			set_prompt("Activate Power Switch")

func _on_interacted(_player: Player) -> void:
	if not has_fuse:
		if InventoryManager.has_item("fuse"):
			InventoryManager.remove_item("fuse", 1)
			has_fuse = true
			power_switch_on = true
			AudioManager.play_sfx("click", 1.2)
			_update_circuit_status()
		else:
			AudioManager.play_sfx("click", 0.6)
	else:
		# Remove fuse and return to inventory
		has_fuse = false
		power_switch_on = false
		InventoryManager.add_item("fuse", "50A Facility Fuse", 1, 1, "key")
		AudioManager.play_sfx("click", 0.8)
		_update_circuit_status()

func _update_circuit_status() -> void:
	var circuit_active: bool = has_fuse and power_switch_on
	
	if target_door:
		target_door.set_power(circuit_active)
		
	if panel_sprite:
		panel_sprite.modulate = Color(0.4, 1.0, 0.5) if circuit_active else Color(0.9, 0.4, 0.4)
		
	if fuse_socket_sprite:
		fuse_socket_sprite.visible = has_fuse
		
	circuit_state_changed.emit(has_fuse, circuit_active)
	_update_prompt_text()
