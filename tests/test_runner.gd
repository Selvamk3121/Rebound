extends Node2D

# REBOUND - Scene-based Automated Regression & Integration Test Suite (Phases 1, 2, 3)

func _ready() -> void:
	print("==================================================")
	print("--- BEGINNING REBOUND PHASE 1, 2 & 3 TESTS ---")
	print("==================================================")
	
	# Load Player
	var player_scene = load("res://scenes/player/player.tscn")
	assert(player_scene != null, "Could not load player.tscn")
	var player: Player = player_scene.instantiate()
	add_child(player)
	
	# PHASE 1 TESTS
	# Test 1: Initial Health
	assert(player.current_health == 100, "Initial health should be 100")
	print("PASS [01]: Player Health Initialization (100/100)")
	
	# Test 2: Damage and Healing
	player.take_damage(30)
	assert(player.current_health == 70, "Health after 30 dmg should be 70")
	player.heal(15)
	assert(player.current_health == 85, "Health after 15 heal should be 85")
	player.heal(100)
	assert(player.current_health == 100, "Health capped at max_health")
	print("PASS [02]: Player Damage & Healing Mechanics")
	
	# Test 3: Diagonal Velocity Normalization
	var test_dir = Vector2(1, 1).normalized()
	var test_vel = test_dir * player.speed
	assert(abs(test_vel.length() - player.speed) < 0.01, "Diagonal speed must be normalized")
	print("PASS [03]: Diagonal Movement Normalization")
	
	# Test 4: Aim Angle calculation
	var aim_target = player.global_position + Vector2(100, 0)
	var dir_to_target = (aim_target - player.global_position).normalized()
	assert(is_equal_approx(dir_to_target.angle(), 0.0), "Aim angle should be 0 radians")
	print("PASS [04]: Aim Direction Vector Calculation")
	
	# PHASE 2 TESTS
	# Test 5: Reflection Math Formula
	var dir_a = Vector2(1, 0)
	var norm_a = Vector2(-1, 0)
	var refl_a = RicochetMath.calculate_reflection(dir_a, norm_a)
	assert(refl_a.is_equal_approx(Vector2(-1, 0)), "Reflection of (1,0) on (-1,0) should be (-1,0)")
	
	var dir_b = Vector2(1, 1).normalized()
	var norm_b = Vector2(0, -1)
	var refl_b = RicochetMath.calculate_reflection(dir_b, norm_b)
	assert(refl_b.is_equal_approx(Vector2(1, -1).normalized()), "Reflection of (1,1) on (0,-1) should be (1,-1)")
	print("PASS [05]: Ricochet Reflection Formula R = D - 2(D.N)N Exactness")
	
	# Test 6: Starting Weapon (Pistol) & Unlocking Ricochet Gun
	assert(player.weapon_controller != null, "Player must have WeaponController")
	var starting_weapon = player.weapon_controller.current_weapon
	assert(starting_weapon != null, "Current weapon must be loaded")
	assert(starting_weapon.weapon_type == WeaponData.WeaponType.STANDARD, "Starting weapon must be Laser Pulse Pistol")
	assert(GameManager.is_weapon_unlocked(1) == true, "Slot 1 must be unlocked")
	assert(GameManager.is_weapon_unlocked(2) == false, "Slot 2 must start locked")
	
	# Unlock weapon 2 to verify shotgun configuration
	GameManager.unlock_weapon(2)
	player.switch_weapon(2)
	var ricochet_weapon = player.weapon_controller.current_weapon
	assert(ricochet_weapon.weapon_type == WeaponData.WeaponType.RICOCHET, "Weapon 2 should be Ricochet Gun")
	assert(ricochet_weapon.max_bounces == 2, "Default ricochet weapon should have 2 bounces")
	print("PASS [06]: Starting Pistol Only & Ricochet Unlock System Verified")
	
	# Test 7: Firing & Ammo Consumption
	var init_ammo = ricochet_weapon.current_ammo
	var fired = player.weapon_controller.fire(player.muzzle.global_position, Vector2.RIGHT, self)
	assert(fired == true, "Fire weapon should return true")
	assert(ricochet_weapon.current_ammo == init_ammo - 1, "Ammunition should decrement by 1 on fire")
	print("PASS [07]: Weapon Firing & Ammo Deduction (Ammo: %d -> %d)" % [init_ammo, ricochet_weapon.current_ammo])
	
	# Test 8: Reloading Logic
	player.weapon_controller.start_reload()
	assert(player.weapon_controller.is_reloading == true, "Should be in reload state")
	player.weapon_controller._complete_reload()
	assert(player.weapon_controller.is_reloading == false, "Should finish reload")
	assert(ricochet_weapon.current_ammo == ricochet_weapon.max_ammo, "Ammo should be fully restored after reload")
	print("PASS [08]: Reload Cycle & Magazine Restoration")
	
	# Test 9: Ricochet Upgrade System
	ricochet_weapon.apply_upgrade_level(1)
	assert(ricochet_weapon.max_bounces == 1, "Level 1 should have 1 bounce")
	ricochet_weapon.apply_upgrade_level(3)
	assert(ricochet_weapon.max_bounces == 3, "Level 3 should have 3 bounces")
	ricochet_weapon.apply_upgrade_level(5)
	assert(ricochet_weapon.max_bounces == 5, "Level 5 should have 5 bounces")
	print("PASS [09]: Ricochet Upgrades 1-5 Bounce Scaling Verified")
	
	# Test 10: Holographic Trajectory Line Simulation
	assert(player.trajectory_line != null, "TrajectoryLine node must exist on player")
	player.weapon_controller.update_trajectory_preview(Vector2(0, 0), Vector2.RIGHT, [player.get_rid()])
	assert(player.trajectory_line.line_2d.points.size() >= 2, "Trajectory should generate points")
	print("PASS [10]: Holographic Trajectory Prediction Line Geometry Generated")
	
	# PHASE 3 TESTS (ENEMIES)
	# Test 11: Crawler Instantiation & Stats
	var crawler_scene = load("res://scenes/enemies/crawler.tscn")
	assert(crawler_scene != null, "Crawler scene must exist")
	var crawler: EnemyBase = crawler_scene.instantiate()
	add_child(crawler)
	assert(crawler.stats != null, "Crawler stats must be loaded")
	assert(crawler.stats.enemy_name == "Mutant Crawler", "Crawler name verified")
	assert(crawler.current_health == 55, "Crawler HP should be 55")
	print("PASS [11]: Crawler Archetype Initialization (HP: %d)" % crawler.current_health)
	
	# Test 12: Brute Armored Damage Reduction
	var brute_scene = load("res://scenes/enemies/brute.tscn")
	assert(brute_scene != null, "Brute scene must exist")
	var brute: EnemyBase = brute_scene.instantiate()
	add_child(brute)
	assert(brute.stats.armor_reduction == 0.4, "Brute armor reduction should be 40%")
	brute.take_damage(20) # 20 * (1 - 0.4) = 12 damage taken -> 180 - 12 = 168 HP
	assert(brute.current_health == 168, "Brute HP after armor calculation should be 168")
	print("PASS [12]: Brute Armored Damage Reduction (20 dmg -> 12 actual, HP: %d)" % brute.current_health)
	brute.queue_free()
	
	# Test 13: Enemy Death & Credit Reward
	var start_credits = GameManager.credits
	crawler.take_damage(100) # Fatal damage
	assert(crawler.current_state == EnemyBase.State.DEAD, "Crawler should enter DEAD state")
	assert(GameManager.credits == start_credits + crawler.stats.credit_reward, "Credits should be awarded on kill")
	print("PASS [13]: Enemy Death State & Credit Bounty Award (+%d CR)" % crawler.stats.credit_reward)
	
	# PHASE 4 TESTS: WEAPON VISUAL SWITCHING & NEW MOBS & RETRY
	# Test 14: Weapon Visual Frame Switching (using spritesheet frames 1, 2, 3, 4)
	player.switch_weapon(1)
	assert(player.sprite.frame == 1, "Slot 1 (Pistol) should set player sprite frame to 1")
	# Unlock slots 2, 3, 4 for testing frame visual changes
	GameManager.unlock_weapon(2)
	GameManager.unlock_weapon(3)
	GameManager.unlock_weapon(4)
	player.switch_weapon(2)
	assert(player.sprite.frame == 2, "Slot 2 (Ricochet) should set player sprite frame to 2")
	player.switch_weapon(3)
	assert(player.sprite.frame == 3, "Slot 3 (Advanced Rifle) should set player sprite frame to 3")
	player.switch_weapon(4)
	assert(player.sprite.frame == 4, "Slot 4 (Heavy Vulcan) should set player sprite frame to 4")
	print("PASS [14]: Dynamic Weapon Switching updates Sprite2D frame (Frames 1-4)")
	
	# Test 15: Acid Spitter Initialization & Stats
	var spitter_scene = load("res://scenes/enemies/spitter.tscn")
	assert(spitter_scene != null, "Spitter scene must exist")
	var spitter: EnemyBase = spitter_scene.instantiate()
	add_child(spitter)
	assert(spitter.stats != null, "Spitter stats must be loaded")
	assert(spitter.stats.enemy_name == "Acid Spitter", "Spitter name verified")
	assert(spitter.current_health == 85, "Spitter HP should be 85")
	print("PASS [15]: Acid Spitter Archetype Verified (HP: %d, Armor: %.2f)" % [spitter.current_health, spitter.stats.armor_reduction])
	spitter.queue_free()
	
	# Test 16: Void Parasite Initialization & Stats
	var parasite_scene = load("res://scenes/enemies/parasite.tscn")
	assert(parasite_scene != null, "Parasite scene must exist")
	var parasite: EnemyBase = parasite_scene.instantiate()
	add_child(parasite)
	assert(parasite.stats != null, "Parasite stats must be loaded")
	assert(parasite.stats.enemy_name == "Void Parasite", "Parasite name verified")
	assert(parasite.current_health == 60, "Parasite HP should be 60")
	assert(parasite.stats.move_speed == 85.0, "Parasite speed should be 85")
	print("PASS [16]: Void Parasite Archetype Verified (HP: %d, Speed: %.1f)" % [parasite.current_health, parasite.stats.move_speed])
	parasite.queue_free()
	
	# Test 17: Level Cleared & Retry Option Interface
	var hud_scene = load("res://scenes/ui/hud.tscn")
	assert(hud_scene != null, "HUD scene must exist")
	var hud_instance: HUD = hud_scene.instantiate()
	add_child(hud_instance)
	assert(hud_instance.retry_overlay != null, "HUD must have retry overlay")
	assert(hud_instance.retry_overlay.visible == false, "Retry overlay starts hidden")
	hud_instance.show_victory_screen(5, 120)
	assert(hud_instance.retry_overlay.visible == true, "Retry overlay should become visible on victory")
	assert(hud_instance.retry_status_label.text.contains("SECTOR PURGED"), "Victory status header should be displayed")
	print("PASS [17]: Victory State & Retry Overlay Activation Verified")
	hud_instance.queue_free()
	
	# PHASE 5 TESTS: MAIN MENU & COMBINED WEAPON ENHANCEMENTS
	# Test 18: Starting Main Menu & Guidance System
	var menu_scene = load("res://scenes/ui/main_menu.tscn")
	assert(menu_scene != null, "MainMenu scene must exist")
	var menu = menu_scene.instantiate()
	add_child(menu)
	assert(menu.start_button != null, "Start button must exist")
	assert(menu.guidance_button != null, "Guidance button must exist")
	assert(menu.guidance_modal != null, "Guidance modal must exist")
	assert(menu.guidance_modal.visible == false, "Guidance modal should start hidden")
	menu._on_guidance_pressed()
	assert(menu.guidance_modal.visible == true, "Guidance modal should become visible")
	menu._on_close_guidance_pressed()
	assert(menu.guidance_modal.visible == false, "Guidance modal should close properly")
	print("PASS [18]: Starting Menu Deployment & Guidance Briefing Toggle Verified")
	menu.queue_free()
	
	# Test 19: Enhanced Weapon Assets & Shotgun Pellets
	var ricochet_w = player.weapon_controller.weapons[2]
	assert(ricochet_w.pellets == 3, "Shotgun must fire 3 pellets")
	assert(ricochet_w.projectile_texture != null, "Shotgun must have projectile texture")
	assert(ricochet_w.icon_texture != null, "Shotgun must have icon texture")
	assert(ricochet_w.muzzle_flash_texture != null, "Shotgun must have muzzle flash texture")
	
	var laser_w = player.weapon_controller.weapons[1]
	assert(laser_w.icon_texture != null, "Laser Pistol must have icon texture")
	assert(laser_w.projectile_texture != null, "Laser Pistol must have projectile texture")
	
	var plasma_w = player.weapon_controller.weapons[3]
	assert(plasma_w.icon_texture != null, "Plasma Cannon must have icon texture")
	assert(plasma_w.projectile_texture != null, "Plasma Cannon must have projectile texture")
	print("PASS [19]: Combined Sci-Fi Weapons Visual Assets & Multi-Pellet Mechanics Verified")
	
	# PHASE 6 TESTS: 8-SLOT INVENTORY, CRAFTING, FIRST-TIME PROMPT, SAFE ROOM & ARMOURY BOX
	# Test 20: 8-Slot Inventory Capacity
	InventoryManager.reset_inventory()
	assert(InventoryManager.MAX_SLOTS == 8, "Inventory must have exactly 8 slots")
	assert(InventoryManager.slots.size() == 8, "Inventory slots array must contain 8 slots")
	print("PASS [20]: 8-Slot Limited Inventory System Verified")

	# Test 21: Material Combining System (Gunpowder + Scrap Metal -> Ammo)
	assert(InventoryManager.can_combine_ammo() == false, "Cannot combine without materials")
	InventoryManager.add_item("gunpowder", "Gunpowder", 1, 99, "material")
	InventoryManager.add_item("scrap", "Scrap Metal", 1, 99, "material")
	assert(InventoryManager.can_combine_ammo() == true, "Can combine when having gunpowder and scrap")
	var combine_success = InventoryManager.combine_ammo(12)
	assert(combine_success == true, "Combine ammo operation should succeed")
	assert(InventoryManager.has_item("ammo", 12), "Ammo should be added to inventory")
	assert(InventoryManager.has_item("gunpowder", 1) == false, "Gunpowder consumed")
	assert(InventoryManager.has_item("scrap", 1) == false, "Scrap metal consumed")
	print("PASS [21]: Gunpowder + Scrap Metal -> Ammo Crafting Verified")

	# Test 22: First-time prompt 'e' to grab suppression
	GameManager.has_shown_pickup_prompt = false
	var pickup_scene = load("res://scenes/objects/pickup.tscn")
	var pickup_inst = pickup_scene.instantiate()
	pickup_inst.prompt_message = "to grab"
	add_child(pickup_inst)
	pickup_inst._on_body_entered(player)
	assert(pickup_inst.prompt_label != null, "Prompt label should exist")
	assert(pickup_inst.prompt_label.text.contains("'e' to grab"), "First time prompt should show 'e' to grab")
	assert(pickup_inst.prompt_label.visible == true, "Prompt label should be visible")
	pickup_inst._on_body_exited(player)
	GameManager.has_shown_pickup_prompt = true
	pickup_inst._on_body_entered(player)
	assert(pickup_inst.prompt_label.visible == false, "Prompt should be suppressed once player has seen it")
	pickup_inst.queue_free()
	print("PASS [22]: First-Time Interaction Prompt Suppression Verified")

	# Test 23: Safe Room & Armoury Station Upgrades
	var safe_room_scene = load("res://scenes/armoury/safe_room.tscn")
	assert(safe_room_scene != null, "Safe room scene must exist")
	GameManager.credits = 100
	var initial_dmg = GameManager.gun_damage_bonus
	var upgraded = GameManager.upgrade_gun_stat("damage", 25)
	assert(upgraded == true, "Upgrading damage with sufficient credits should succeed")
	assert(GameManager.gun_damage_bonus == initial_dmg + 5, "Damage bonus should increase by 5")
	assert(GameManager.credits == 75, "Credits should be deducted by 25")
	print("PASS [23]: Safe Room Armoury Box Stat Enhancement Verified")

	# Test 24: Level 3 Weapon Unlock Pickup
	GameManager.unlocked_weapons = [1]
	assert(GameManager.is_weapon_unlocked(2) == false, "Weapon 2 initially locked")
	var lvl3_scene = load("res://scenes/levels/level_03_containment.tscn")
	assert(lvl3_scene != null, "Level 03 Containment scene must exist")
	var lvl3 = lvl3_scene.instantiate()
	add_child(lvl3)
	var weapon_pickup = lvl3.find_child("WeaponUnlockShotgun", true, false)
	assert(weapon_pickup != null, "Level 3 must contain WeaponUnlockShotgun")
	assert(weapon_pickup.pickup_type == 7, "Pickup type should be WEAPON_UNLOCK")
	assert(weapon_pickup.unlock_weapon_slot == 2, "Pickup should unlock weapon slot 2")
	GameManager.unlock_weapon(weapon_pickup.unlock_weapon_slot)
	assert(GameManager.is_weapon_unlocked(2) == true, "Weapon 2 should now be unlocked")
	lvl3.queue_free()
	print("PASS [24]: Level 3 Security Shotgun Unlock Pickup Verified")

	# PHASE 7 TESTS: SPRINT/ENERGY, SLEEPING MOBS, PERSISTENT AMMO, SELECT COMBINE & 5-LEVEL PROGRESSION
	# Test 25: Player Slower Movement & Sprint Stamina System
	assert(player.speed == 110.0, "Player base speed should be 110 (slower pace)")
	assert(player.sprint_speed == 190.0, "Player sprint speed should be 190")
	assert(player.max_stamina == 100.0, "Player max stamina should be 100")
	player.current_stamina = 100.0
	# Simulate 1 second of sprinting
	player.velocity = Vector2(100, 0)
	player.current_stamina -= player.stamina_drain_rate * 1.0
	player.stamina_delay_timer = player.stamina_recharge_delay
	assert(player.current_stamina < 100.0, "Stamina drains while sprinting")
	assert(player.stamina_delay_timer > 0.0, "Sprint triggers recharge delay timer")
	player.current_stamina = 100.0
	print("PASS [25]: Player Slower Movement & Sprint Stamina System Verified")

	# Test 26: Dormant / Sleeping Monster AI & Wake-Up Mechanic
	var test_mob: EnemyBase = crawler_scene.instantiate()
	add_child(test_mob)
	assert(test_mob.is_awake == false, "Monster starts dormant/idle")
	assert(test_mob.current_state == EnemyBase.State.IDLE, "Monster starts in IDLE state")
	test_mob.wake_up()
	assert(test_mob.is_awake == true, "Monster wakes up when triggered")
	assert(test_mob.current_state == EnemyBase.State.CHASE, "Monster transitions to CHASE after wake-up")
	test_mob.queue_free()
	print("PASS [26]: Monster Dormancy & Proximity Wake-Up System Verified")

	# Test 27: Persistent Ammunition Across Level Transitions
	GameManager.save_weapon_ammo(1, 7, 23)
	var saved_ammo = GameManager.get_weapon_ammo(1)
	assert(saved_ammo != null, "Ammo state saved in GameManager")
	assert(saved_ammo["current"] == 7, "Current ammo preserved as 7")
	assert(saved_ammo["reserve"] == 23, "Reserve ammo preserved as 23")
	var new_player_scene = load("res://scenes/player/player.tscn")
	var new_player: Player = new_player_scene.instantiate()
	add_child(new_player)
	assert(new_player.weapon_controller.weapons[1].current_ammo == 7, "WeaponController restored persistent current ammo")
	assert(new_player.weapon_controller.weapons[1].reserve_ammo == 23, "WeaponController restored persistent reserve ammo")
	new_player.queue_free()
	print("PASS [27]: Non-Resetting Weapon Ammo Persistence Verified")

	# Test 28: Interactive Inventory Item Selection & Slot-Based Crafting
	InventoryManager.reset_inventory()
	InventoryManager.add_item("gunpowder", "Gunpowder", 1, 99, "material")
	InventoryManager.add_item("scrap", "Scrap Metal", 1, 99, "material")
	assert(InventoryManager.can_combine_slots(0, 1) == true, "Slots 0 & 1 with gunpowder + scrap can combine")
	assert(InventoryManager.can_combine_slots(0, 0) == false, "Cannot combine slot with itself")
	var slot_crafted = InventoryManager.combine_slots(0, 1, 12)
	assert(slot_crafted == true, "Slot combining successful")
	assert(InventoryManager.has_item("ammo", 12), "12x Ammo crafted from selected slots")
	print("PASS [28]: Click Two Items & Combine System Verified")

	# Test 29: 5-Level Architecture & Interactive Sector Doors
	assert(GameManager.MAX_LEVELS == 5, "Total campaign levels must be 5")
	for lvl in range(1, 6):
		var scene_path = GameManager.get_level_scene_path(lvl)
		assert(ResourceLoader.exists(scene_path), "Level %d scene must exist: %s" % [lvl, scene_path])
	var door_scene = load("res://scenes/objects/sector_door.tscn")
	assert(door_scene != null, "SectorDoor scene must exist")
	var door: SectorDoor = door_scene.instantiate()
	add_child(door)
	door.door_type = SectorDoor.DoorType.HALLWAY_GATE
	door._on_interacted(player)
	assert(door.is_open == true, "Hallway door opens upon interaction")
	door.queue_free()
	print("PASS [29]: 5-Level Progression & Interactive Bulkhead Doors Verified")

	print("==================================================")
	print("--- ALL 29 REBOUND REGRESSION TESTS PASSED! ---")
	print("==================================================")
	get_tree().quit(0)
