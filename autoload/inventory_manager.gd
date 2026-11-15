extends Node

# REBOUND - Inventory Manager Autoload
# Manages player inventory slots, item stacking, and item usage.

signal inventory_updated
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal item_used(item_id: String)

const MAX_SLOTS: int = 8

# Array of Dictionary: {"id": String, "count": int, "max_stack": int, "name": String, "type": String}
var slots: Array = []

func _ready() -> void:
	reset_inventory()

func reset_inventory() -> void:
	slots.clear()
	for i in range(MAX_SLOTS):
		slots.append(null)
	inventory_updated.emit()

func can_combine_ammo() -> bool:
	return has_item("gunpowder", 1) and has_item("scrap", 1)

func can_combine_slots(slot_a: int, slot_b: int) -> bool:
	if slot_a < 0 or slot_a >= MAX_SLOTS or slot_b < 0 or slot_b >= MAX_SLOTS:
		return false
	if slot_a == slot_b:
		return false
	var item_a = slots[slot_a]
	var item_b = slots[slot_b]
	if item_a == null or item_b == null:
		return false
	var ids = [item_a["id"], item_b["id"]]
	return ids.has("gunpowder") and ids.has("scrap")

func combine_slots(slot_a: int, slot_b: int, ammo_yield: int = 12) -> bool:
	if not can_combine_slots(slot_a, slot_b):
		return false
	_deduct_slot(slot_a, 1)
	_deduct_slot(slot_b, 1)
	add_item("ammo", "Field Ammo", ammo_yield, 99, "ammo")
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if p and p.weapon_controller:
			p.weapon_controller.add_reserve_ammo(p.weapon_controller.current_slot, ammo_yield)
			
	AudioManager.play_sfx("pickup")
	inventory_updated.emit()
	return true

func _deduct_slot(slot_idx: int, amount: int = 1) -> void:
	if slot_idx < 0 or slot_idx >= MAX_SLOTS:
		return
	var s = slots[slot_idx]
	if s == null:
		return
	s["count"] -= amount
	if s["count"] <= 0:
		slots[slot_idx] = null

func combine_ammo(ammo_yield: int = 12) -> bool:
	if not can_combine_ammo():
		return false
	remove_item("gunpowder", 1)
	remove_item("scrap", 1)
	add_item("ammo", "Field Ammo", ammo_yield, 99, "ammo")
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if p and p.weapon_controller:
			p.weapon_controller.add_reserve_ammo(p.weapon_controller.current_slot, ammo_yield)
			
	AudioManager.play_sfx("pickup")
	return true

func add_item(item_id: String, item_name: String, count: int = 1, max_stack: int = 99, type: String = "general") -> bool:
	var remaining: int = count
	
	# First pass: try stacking onto existing matching slots
	for i in range(MAX_SLOTS):
		var slot = slots[i]
		if slot != null and slot["id"] == item_id:
			var space: int = slot["max_stack"] - slot["count"]
			if space > 0:
				var to_add: int = min(remaining, space)
				slot["count"] += to_add
				remaining -= to_add
				if remaining <= 0:
					item_added.emit(item_id, count)
					inventory_updated.emit()
					return true
					
	# Second pass: find empty slot
	while remaining > 0:
		var empty_index: int = -1
		for i in range(MAX_SLOTS):
			if slots[i] == null:
				empty_index = i
				break
				
		if empty_index == -1:
			# Inventory full
			inventory_updated.emit()
			return false
			
		var to_add: int = min(remaining, max_stack)
		slots[empty_index] = {
			"id": item_id,
			"name": item_name,
			"count": to_add,
			"max_stack": max_stack,
			"type": type
		}
		remaining -= to_add
		
	item_added.emit(item_id, count)
	inventory_updated.emit()
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	if not has_item(item_id, count):
		return false
		
	var remaining: int = count
	for i in range(MAX_SLOTS - 1, -1, -1):
		var slot = slots[i]
		if slot != null and slot["id"] == item_id:
			if slot["count"] <= remaining:
				remaining -= slot["count"]
				slots[i] = null
			else:
				slot["count"] -= remaining
				remaining = 0
			if remaining <= 0:
				break
				
	item_removed.emit(item_id, count)
	inventory_updated.emit()
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	var total: int = 0
	for slot in slots:
		if slot != null and slot["id"] == item_id:
			total += slot["count"]
			if total >= count:
				return true
	return false

func get_item_count(item_id: String) -> int:
	var total: int = 0
	for slot in slots:
		if slot != null and slot["id"] == item_id:
			total += slot["count"]
	return total

func get_slot(index: int) -> Dictionary:
	if index >= 0 and index < MAX_SLOTS and slots[index] != null:
		return slots[index]
	return {}
