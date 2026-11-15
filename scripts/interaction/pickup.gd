class_name Pickup
extends Interactable

# REBOUND - World Pickup Item
# Adds items or currency directly to player inventory on collection.

enum PickupType {
	FUSE,
	MEDKIT,
	RICOCHET_AMMO,
	SCRAP_METAL,
	CREDITS,
	GUNPOWDER,
	RESEARCH_NOTE,
	WEAPON_UNLOCK
}

@export var pickup_type: PickupType = PickupType.FUSE
@export var amount: int = 1
@export var unlock_weapon_slot: int = 2

@onready var sprite: Sprite2D = $Sprite2D

var bob_timer: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	super._ready()
	base_y = position.y
	_configure_type()

func _process(delta: float) -> void:
	bob_timer += delta * 3.0
	if sprite:
		sprite.position.y = sin(bob_timer) * 3.0

func _configure_type() -> void:
	match pickup_type:
		PickupType.FUSE:
			set_prompt("Collect 50A Fuse")
			if sprite and ResourceLoader.exists("res://assets/sprites/items/fuse.png"):
				sprite.texture = load("res://assets/sprites/items/fuse.png")
		PickupType.MEDKIT:
			set_prompt("Collect Medical Kit")
			if sprite and ResourceLoader.exists("res://assets/sprites/items/medkit.png"):
				sprite.texture = load("res://assets/sprites/items/medkit.png")
		PickupType.RICOCHET_AMMO:
			set_prompt("Collect Ammo Batch (+12)")
			if sprite and ResourceLoader.exists("res://assets/sprites/items/ammo_box.png"):
				sprite.texture = load("res://assets/sprites/items/ammo_box.png")
		PickupType.SCRAP_METAL:
			set_prompt("Collect Scrap Metal")
			if sprite and ResourceLoader.exists("res://assets/sprites/items/scrap.png"):
				sprite.texture = load("res://assets/sprites/items/scrap.png")
		PickupType.GUNPOWDER:
			set_prompt("Collect Gunpowder")
			if sprite and ResourceLoader.exists("res://assets/sprites/items/gunpowder.png"):
				sprite.texture = load("res://assets/sprites/items/gunpowder.png")
		PickupType.RESEARCH_NOTE:
			set_prompt("Read Research Note")
			if sprite and ResourceLoader.exists("res://assets/sprites/items/note.png"):
				sprite.texture = load("res://assets/sprites/items/note.png")
		PickupType.WEAPON_UNLOCK:
			set_prompt("Acquire Weapon Case")
			if sprite and ResourceLoader.exists("res://assets/sprites/items/weapon_case.png"):
				sprite.texture = load("res://assets/sprites/items/weapon_case.png")
		PickupType.CREDITS:
			set_prompt("Collect Credits (+%d CR)" % amount)

func _on_interacted(player: Player) -> void:
	var collected: bool = false
	match pickup_type:
		PickupType.FUSE:
			collected = InventoryManager.add_item("fuse", "50A Facility Fuse", amount, 1, "key")
		PickupType.MEDKIT:
			collected = InventoryManager.add_item("medkit", "Medical Kit", amount, 5, "medical")
		PickupType.RICOCHET_AMMO:
			collected = InventoryManager.add_item("ammo", "Field Ammo", 12 * amount, 99, "ammo")
			if player.weapon_controller:
				player.weapon_controller.add_reserve_ammo(player.weapon_controller.current_slot, 12 * amount)
		PickupType.SCRAP_METAL:
			collected = InventoryManager.add_item("scrap", "Scrap Metal", amount, 99, "material")
		PickupType.GUNPOWDER:
			collected = InventoryManager.add_item("gunpowder", "Gunpowder", amount, 99, "material")
		PickupType.RESEARCH_NOTE:
			var hud = _find_hud()
			if hud and hud.has_method("show_note_modal"):
				hud.show_note_modal(
					"FACILITY FIELD MEMORANDUM #402",
					"EMERGENCY MUNITIONS SYNTHESIS:\n\nBallistic resupply lines have been compromised by mutant specimens.\n\nTwo scavenged raw materials can be combined to manufacture ammunition:\n\n  • [1x GUNPOWDER] + [1x SCRAP METAL] = [12x AMMO]\n\nScavenge gunpowder canisters and metal scraps dispersed across the sector floor. Open your Tactical Rig ([I]) to combine them."
				)
			collected = true
		PickupType.WEAPON_UNLOCK:
			GameManager.unlock_weapon(unlock_weapon_slot)
			player.switch_weapon(unlock_weapon_slot)
			var hud = _find_hud()
			if hud and hud.has_method("show_notification"):
				hud.show_notification("NEW ARSENAL UNLOCKED: Security Ricochet Shotgun! Press [2] or Scroll to equip.")
			collected = true
		PickupType.CREDITS:
			GameManager.add_credits(amount)
			collected = true

	if collected:
		AudioManager.play_sfx("pickup")
		queue_free()

func _find_hud() -> HUD:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		return huds[0] as HUD
	var scene = get_tree().current_scene
	if scene and scene.has_node("HUD"):
		return scene.get_node("HUD") as HUD
	return null
