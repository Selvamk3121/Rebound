# REBOUND: Development Manual

## 1. Technical Overview
REBOUND is a 2D top-down survival horror game built on the **Godot 4.7.2** engine.

## 2. Opening & Running the Project
- **Godot Executable**: `/home/selvamk/Downloads/Godot_v4.7.2-stable_linux.x86_64`
- **Project Path**: `/home/selvamk/Downloads/Rebound`
- **Launch Command**:
  ```bash
  /home/selvamk/Downloads/Godot_v4.7.2-stable_linux.x86_64 --path /home/selvamk/Downloads/Rebound
  ```
- **Automated Test Suite**:
  ```bash
  /home/selvamk/Downloads/Godot_v4.7.2-stable_linux.x86_64 --headless --path /home/selvamk/Downloads/Rebound tests/test_runner.tscn
  ```

## 3. Autoload Singletons
1. `GameManager` (`res://autoload/game_manager.gd`): Maintains global game states, pause management, digital credits, and fallback input maps.
2. `InventoryManager` (`res://autoload/inventory_manager.gd`): 12-slot backpack inventory, item addition/subtraction, stacking logic.
3. `AudioManager` (`res://autoload/audio_manager.gd`): Multi-channel SFX pooling and looping background industrial audio.
4. `SaveManager` (`res://autoload/save_manager.gd`): JSON save state serialization to `user://rebound_save.json`.

## 4. Phase 1 & 2 Implementation Architecture

### 4.1 Player Controller (`res://scripts/player/player.gd`)
- 8-direction normalized movement preventing diagonal speed boost.
- Real-time mouse aiming rotation with weapon pivot and muzzle marker.
- Player health and death signaling.
- Dynamic camera following with smoothing.

### 4.2 Shared Ricochet Reflection Utility (`res://scripts/combat/ricochet_math.gd`)
To ensure that the holographic preview never lies about projectile behavior, both the aiming sight and projectile use identical physics queries and reflection mathematics:
$$\vec{R} = \vec{D} - 2(\vec{D} \cdot \vec{N})\vec{N}$$
- `simulate_trajectory(space_state, origin, dir, max_bounces, max_dist, mask)`: Traces physics rays through `PhysicsDirectSpaceState2D`, recording each impact point and surface normal up to the bounce limit.

### 4.3 Holographic Aiming Sight (`res://scripts/combat/trajectory_line.gd`)
- `Line2D` rendering with round caps and cyan glow.
- Circles and arcs drawn at each reflection contact point.
- Only activates for weapons with bounce capability (Ricochet Gun, Bio-Energy Rifle).

### 4.4 Ricochet Projectile (`res://scripts/combat/ricochet_projectile.gd`)
- Floating `CharacterBody2D` with step-by-step `move_and_collide()`.
- Reflects off Physics Layer 1 (Walls), decrementing remaining bounces and emitting spatial ricochet audio.
- Damages Layer 3 (Enemies) and self-terminates upon reaching maximum bounce limits or lifetime expiration.

### 4.5 Weapon System (`res://scripts/combat/weapon_controller.gd` & `WeaponData`)
- Data-driven `WeaponData` resource files:
  - `standard_weapon.tres`: Pistol (0 bounces, rapid fire)
  - `ricochet_weapon.tres`: Security Ricochet Gun (1-5 bounces based on upgrade level)
  - `advanced_weapon.tres`: Prototype Bio-Energy Rifle (high damage, charged 4 bounces)
- Handles ammunition consumption, reloading cycles, reserve pooling, and HUD signal dispatching.
