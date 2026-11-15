class_name HUD
extends CanvasLayer

# REBOUND - In-Game HUD, 8-Slot Inventory, Crafting, Note Reader & Armoury Terminal

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var energy_label: Label = $MarginContainer/VBoxContainer/EnergyLabel
@onready var energy_bar: ProgressBar = $MarginContainer/VBoxContainer/EnergyBar
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/WeaponHBox/WeaponLabel
@onready var weapon_icon: TextureRect = $MarginContainer/VBoxContainer/WeaponHBox/WeaponIcon
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var credits_label: Label = $MarginContainer/VBoxContainer/CreditsLabel
@onready var bounce_label: Label = $MarginContainer/VBoxContainer/BounceLabel
@onready var threats_label: Label = $MarginContainer/VBoxContainer/ThreatsLabel
@onready var notification_label: Label = $NotificationLabel

# Victory & Retry
@onready var retry_overlay: Control = $RetryOverlay
@onready var retry_status_label: Label = $RetryOverlay/Panel/VBox/StatusLabel
@onready var retry_detail_label: Label = $RetryOverlay/Panel/VBox/DetailLabel
@onready var retry_button: Button = $RetryOverlay/Panel/VBox/ButtonHBox/RetryButton
@onready var safe_room_button: Button = $RetryOverlay/Panel/VBox/ButtonHBox/SafeRoomButton

# 8-Slot Inventory & Combine
@onready var inventory_modal: Control = $InventoryModal
@onready var inventory_grid: GridContainer = $InventoryModal/Panel/Margin/VBox/Grid
@onready var combine_button: Button = $InventoryModal/Panel/Margin/VBox/CombineBox/CombineButton
@onready var combine_status: Label = $InventoryModal/Panel/Margin/VBox/CombineBox/CombineStatus
@onready var close_inventory_button: Button = $InventoryModal/Panel/Margin/VBox/CloseInventoryButton

# Note Reader
@onready var note_modal: Control = $NoteModal
@onready var note_title: Label = $NoteModal/Panel/Margin/VBox/NoteTitle
@onready var note_content: RichTextLabel = $NoteModal/Panel/Margin/VBox/NoteContent
@onready var close_note_button: Button = $NoteModal/Panel/Margin/VBox/CloseNoteButton

# Armoury Modal
@onready var armoury_modal: Control = $ArmouryModal
@onready var armoury_credits_label: Label = $ArmouryModal/Panel/Margin/VBox/ArmouryCredits
@onready var dmg_button: Button = $ArmouryModal/Panel/Margin/VBox/UpgradesVBox/DmgRow/DmgButton
@onready var bounce_button: Button = $ArmouryModal/Panel/Margin/VBox/UpgradesVBox/BounceRow/BounceButton
@onready var mag_button: Button = $ArmouryModal/Panel/Margin/VBox/UpgradesVBox/MagRow/MagButton
@onready var reload_button: Button = $ArmouryModal/Panel/Margin/VBox/UpgradesVBox/ReloadRow/ReloadButton
@onready var close_armoury_button: Button = $ArmouryModal/Panel/Margin/VBox/CloseArmouryButton

var current_weapon_ref: WeaponData = null
var current_player: Player = null
var is_reloading_scene: bool = false
var slot_panels: Array = []
var selected_slots: Array[int] = []

func _ready() -> void:
	GameManager.credits_changed.connect(_on_credits_changed)
	_on_credits_changed(GameManager.credits)
	
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if safe_room_button:
		safe_room_button.pressed.connect(_on_safe_room_pressed)
		
	# Inventory setup
	InventoryManager.inventory_updated.connect(_refresh_inventory_ui)
	_build_inventory_slots()
	if combine_button:
		combine_button.pressed.connect(_on_combine_pressed)
	if close_inventory_button:
		close_inventory_button.pressed.connect(toggle_inventory)
		
	# Note setup
	if close_note_button:
		close_note_button.pressed.connect(_close_note_modal)
		
	# Armoury setup
	if close_armoury_button:
		close_armoury_button.pressed.connect(_close_armoury_modal)
	if dmg_button:
		dmg_button.pressed.connect(func(): _upgrade_stat("damage", 35))
	if bounce_button:
		bounce_button.pressed.connect(func(): _upgrade_stat("bounce", 50))
	if mag_button:
		mag_button.pressed.connect(func(): _upgrade_stat("magazine", 30))
	if reload_button:
		reload_button.pressed.connect(func(): _upgrade_stat("reload", 40))

func _input(event: InputEvent) -> void:
	# Note dismissal
	if note_modal and note_modal.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("pause") or _is_confirm_key(event):
			_close_note_modal()
			get_viewport().set_input_as_handled()
			return
			
	# Armoury modal dismissal
	if armoury_modal and armoury_modal.visible:
		if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE):
			_close_armoury_modal()
			get_viewport().set_input_as_handled()
			return

	# Inventory toggle
	if event.is_action_pressed("inventory") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_I):
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	# Victory / Retry inputs
	if retry_overlay and retry_overlay.visible:
		if event.is_action_pressed("reload") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_R):
			var vp = get_viewport()
			if vp:
				vp.set_input_as_handled()
			_on_retry_pressed()

func _is_confirm_key(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.is_echo():
		return event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_KP_ENTER
	return false

func setup_player(player: Player) -> void:
	if not player:
		return
	current_player = player
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.current_health, player.max_health)
	
	if player.has_signal("stamina_changed"):
		player.stamina_changed.connect(_on_stamina_changed)
		_on_stamina_changed(player.current_stamina, player.max_stamina)
	
	if player.weapon_controller:
		player.weapon_controller.ammo_changed.connect(_on_ammo_changed)
		player.weapon_controller.weapon_changed.connect(_on_weapon_changed)
		player.weapon_controller.reload_started.connect(_on_reload_started)
		player.weapon_controller.reload_finished.connect(_on_reload_finished)
		player.weapon_controller.magazine_full.connect(_on_magazine_full)
		if player.weapon_controller.current_weapon:
			_on_weapon_changed(player.weapon_controller.current_weapon)

func _on_stamina_changed(current: float, max_val: float) -> void:
	if energy_bar:
		energy_bar.max_value = max_val
		energy_bar.value = current
	if energy_label:
		var pct = int((current / max(1.0, max_val)) * 100.0)
		energy_label.text = "ENERGY: %d%%" % pct
		if current < 25.0:
			energy_label.modulate = Color(1.0, 0.4, 0.4)
		else:
			energy_label.modulate = Color(0.3, 0.9, 1.0)

# ==================== INVENTORY & COMBINING ====================

func _build_inventory_slots() -> void:
	if not inventory_grid:
		return
	for c in inventory_grid.get_children():
		c.queue_free()
	slot_panels.clear()
	selected_slots.clear()
	
	for i in range(InventoryManager.MAX_SLOTS):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(95, 44)
		var slot_idx = i
		btn.pressed.connect(func(): _on_slot_clicked(slot_idx))
		
		var vb = VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var name_lbl = Label.new()
		name_lbl.name = "ItemName"
		name_lbl.text = "[EMPTY]"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.modulate = Color(0.6, 0.6, 0.6)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var count_lbl = Label.new()
		count_lbl.name = "ItemCount"
		count_lbl.text = ""
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.add_theme_font_size_override("font_size", 8)
		count_lbl.modulate = Color(0.3, 0.9, 0.8)
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		vb.add_child(name_lbl)
		vb.add_child(count_lbl)
		btn.add_child(vb)
		inventory_grid.add_child(btn)
		slot_panels.append(btn)
		
	_refresh_inventory_ui()

func _on_slot_clicked(idx: int) -> void:
	if idx < 0 or idx >= InventoryManager.slots.size():
		return
	var item = InventoryManager.slots[idx]
	if item == null:
		return
		
	if selected_slots.has(idx):
		selected_slots.erase(idx)
	else:
		if selected_slots.size() >= 2:
			selected_slots.remove_at(0)
		selected_slots.append(idx)
		
	AudioManager.play_sfx("click", 1.2)
	_refresh_inventory_ui()

func toggle_inventory() -> void:
	if inventory_modal:
		inventory_modal.visible = !inventory_modal.visible
		if inventory_modal.visible:
			_refresh_inventory_ui()
			AudioManager.play_sfx("click")
		else:
			selected_slots.clear()

func _exit_tree() -> void:
	if InventoryManager.inventory_updated.is_connected(_refresh_inventory_ui):
		InventoryManager.inventory_updated.disconnect(_refresh_inventory_ui)
	if GameManager.credits_changed.is_connected(_on_credits_changed):
		GameManager.credits_changed.disconnect(_on_credits_changed)

func _refresh_inventory_ui() -> void:
	if not is_inside_tree() or slot_panels.is_empty():
		return
	for i in range(slot_panels.size()):
		var p = slot_panels[i]
		if not is_instance_valid(p):
			continue
		var vb = p.get_node_or_null("VBoxContainer")
		if not vb:
			continue
		var name_lbl: Label = vb.get_node_or_null("ItemName")
		var count_lbl: Label = vb.get_node_or_null("ItemCount")
		if not name_lbl or not count_lbl:
			continue
			
		var is_selected = selected_slots.has(i)
		if is_selected:
			p.self_modulate = Color(0.2, 1.4, 0.5, 1.0)
		else:
			p.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
			
		if i < InventoryManager.slots.size():
			var item = InventoryManager.slots[i]
			if item != null:
				var prefix = "[SEL] " if is_selected else ""
				name_lbl.text = prefix + item.get("name", "")
				name_lbl.modulate = Color(0.2, 1.0, 0.4) if is_selected else Color.WHITE
				count_lbl.text = "Qty: %d" % item.get("count", 0)
			else:
				name_lbl.text = "[EMPTY]"
				name_lbl.modulate = Color(0.5, 0.5, 0.5)
				count_lbl.text = ""
			
	if combine_button and combine_status:
		if selected_slots.size() == 2:
			var slot_a = selected_slots[0]
			var slot_b = selected_slots[1]
			var can_craft = InventoryManager.can_combine_slots(slot_a, slot_b)
			combine_button.disabled = !can_craft
			if can_craft:
				combine_button.text = "[ COMBINE SELECTED: 1x Gunpowder + 1x Scrap -> 12x Ammo ]"
				combine_status.text = "Selected materials ready! Press Combine."
				combine_status.modulate = Color(0.2, 1.0, 0.4)
			else:
				combine_button.text = "[ INCOMPATIBLE ITEMS SELECTED ]"
				combine_status.text = "These selected items cannot be combined."
				combine_status.modulate = Color(0.9, 0.5, 0.3)
		elif selected_slots.size() == 1:
			combine_button.disabled = true
			var item = InventoryManager.slots[selected_slots[0]]
			var item_name = item.get("name", "Item") if item else "Item"
			combine_button.text = "[ SELECT SECOND ITEM TO COMBINE ]"
			combine_status.text = "Selected (1/2): %s. Click another material to combine." % item_name
			combine_status.modulate = Color(0.9, 0.8, 0.3)
		else:
			var can_craft_general = InventoryManager.can_combine_ammo()
			combine_button.disabled = !can_craft_general
			if can_craft_general:
				combine_button.text = "[ COMBINE: 1x Gunpowder + 1x Scrap -> 12x Ammo ]"
				combine_status.text = "Materials in rig! Click items to select or combine directly."
				combine_status.modulate = Color(0.3, 0.9, 0.9)
			else:
				combine_button.text = "[ COMBINE: Select 2 Items ]"
				combine_status.text = "Click Gunpowder & Scrap Metal to select, then combine."
				combine_status.modulate = Color(0.7, 0.7, 0.7)

func _on_combine_pressed() -> void:
	var success: bool = false
	if selected_slots.size() == 2:
		success = InventoryManager.combine_slots(selected_slots[0], selected_slots[1], 12)
		selected_slots.clear()
	else:
		success = InventoryManager.combine_ammo(12)
		selected_slots.clear()
		
	if success:
		_refresh_inventory_ui()
		show_notification("CRAFTED: 12x Field Ammo synthesized into reserve!")

# ==================== NOTE MODAL ====================

func show_note_modal(title_text: String, content_text: String) -> void:
	if note_modal:
		note_title.text = "[ %s ]" % title_text
		note_content.text = content_text
		note_modal.visible = true
		if close_note_button:
			close_note_button.grab_focus()
		AudioManager.play_sfx("click")

func _close_note_modal() -> void:
	if note_modal:
		note_modal.visible = false
		AudioManager.play_sfx("click", 0.9)

# ==================== ARMOURY TERMINAL ====================

func show_armoury_modal(player: Player) -> void:
	current_player = player
	if armoury_modal:
		_refresh_armoury_ui()
		armoury_modal.visible = true
		if close_armoury_button:
			close_armoury_button.grab_focus()

func _refresh_armoury_ui() -> void:
	if armoury_credits_label:
		armoury_credits_label.text = "AVAILABLE CREDITS: %d CR" % GameManager.credits
	if current_player and current_player.weapon_controller:
		var wc = current_player.weapon_controller
		dmg_button.disabled = GameManager.credits < 35
		bounce_button.disabled = GameManager.credits < 50
		mag_button.disabled = GameManager.credits < 30
		reload_button.disabled = GameManager.credits < 40 or GameManager.gun_reload_multiplier <= 0.4

func _upgrade_stat(stat: String, cost: int) -> void:
	if GameManager.upgrade_gun_stat(stat, cost):
		AudioManager.play_sfx("pickup")
		_refresh_armoury_ui()
		if current_player and current_player.weapon_controller and current_player.weapon_controller.current_weapon:
			_on_weapon_changed(current_player.weapon_controller.current_weapon)
		show_notification("UPGRADE APPLIED: Gun %s enhanced!" % stat.capitalize())

func _close_armoury_modal() -> void:
	if armoury_modal:
		armoury_modal.visible = false
		AudioManager.play_sfx("click", 0.9)

# ==================== NOTIFICATIONS ====================

func show_notification(msg: String) -> void:
	if notification_label:
		notification_label.text = msg
		notification_label.visible = true
		var t = create_tween()
		t.tween_property(notification_label, "modulate:a", 1.0, 0.2)
		t.tween_interval(3.0)
		t.tween_property(notification_label, "modulate:a", 0.0, 0.5)
		t.tween_callback(func(): notification_label.visible = false)

# ==================== VICTORY & SAFE ROOM ====================

func update_threats(remaining: int, total: int) -> void:
	if threats_label:
		if remaining <= 0:
			threats_label.text = "HOSTILES: ALL PURGED (0/%d)" % total
			threats_label.modulate = Color(0.3, 1.0, 0.4)
		else:
			threats_label.text = "HOSTILES: %d / %d REMAINING" % [remaining, total]
			threats_label.modulate = Color(1.0, 0.85, 0.3)

func show_victory_screen(total_mobs: int, total_credits: int) -> void:
	if retry_overlay:
		retry_status_label.text = "[ SECTOR PURGED ]"
		retry_status_label.modulate = Color(0.2, 1.0, 0.45)
		retry_detail_label.text = "All %d mutant threats eliminated!\nCredits secured: %d CR\nProceed to Safe Room to upgrade weaponry." % [total_mobs, total_credits]
		safe_room_button.visible = true
		retry_overlay.visible = true
		safe_room_button.grab_focus()

func show_game_over_screen() -> void:
	if retry_overlay:
		retry_status_label.text = "[ SUBJECT TERMINATED ]"
		retry_status_label.modulate = Color(1.0, 0.25, 0.25)
		retry_detail_label.text = "Biological vitals flatlined in containment."
		safe_room_button.visible = false
		retry_overlay.visible = true
		retry_button.grab_focus()

func _on_retry_pressed() -> void:
	if is_reloading_scene:
		return
	is_reloading_scene = true
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.PLAYING
	get_tree().reload_current_scene()

func _on_safe_room_pressed() -> void:
	if is_reloading_scene:
		return
	is_reloading_scene = true
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/armoury/safe_room.tscn")

func _on_health_changed(current: int, max_val: int) -> void:
	if health_label and health_bar:
		health_label.text = "HP: %d / %d" % [current, max_val]
		health_bar.max_value = max_val
		health_bar.value = current

func _on_weapon_changed(weapon: WeaponData) -> void:
	current_weapon_ref = weapon
	if weapon_label:
		weapon_label.text = "WEAPON: %s" % weapon.weapon_name
	if weapon_icon:
		if weapon.icon_texture:
			weapon_icon.texture = weapon.icon_texture
			weapon_icon.visible = true
		else:
			weapon_icon.visible = false
	if bounce_label:
		var eff_bounces = weapon.max_bounces + GameManager.gun_bounce_bonus
		if eff_bounces > 0:
			bounce_label.text = "BOUNCES: %d (Upgrade +%d)" % [eff_bounces, GameManager.gun_bounce_bonus]
			bounce_label.visible = true
		else:
			bounce_label.visible = false
	if ammo_label:
		var eff_max = weapon.max_ammo + GameManager.gun_mag_bonus
		ammo_label.text = "AMMO: %d / %d" % [weapon.current_ammo, weapon.reserve_ammo]

func _on_ammo_changed(current: int, max_val: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "AMMO: %d / %d" % [current, reserve]

func _on_reload_started() -> void:
	if ammo_label:
		ammo_label.text = "RELOADING..."

func _on_magazine_full() -> void:
	if ammo_label and current_weapon_ref:
		ammo_label.text = "AMMO: %d / %d (FULL)" % [current_weapon_ref.current_ammo, current_weapon_ref.reserve_ammo]

func _on_reload_finished() -> void:
	if current_weapon_ref and ammo_label:
		ammo_label.text = "AMMO: %d / %d" % [current_weapon_ref.current_ammo, current_weapon_ref.reserve_ammo]

func _on_credits_changed(amount: int) -> void:
	if credits_label:
		credits_label.text = "CREDITS: %d CR" % amount
	_refresh_armoury_ui()
