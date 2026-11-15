# REBOUND: Testing & Verification Report

## Automated Regression & Unit Test Matrix (Phases 1–3)

| Test ID | System / Feature | Test Procedure | Expected Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TEST-01** | Engine Compatibility | Launch Godot 4.7.2 headless scanner | Project scans, builds autoloads without syntax error | **PASS** |
| **TEST-02** | Asset Import Pipeline | Scan and import CC0 audio and sprite files | All textures and audio streams imported cleanly | **PASS** |
| **TEST-03** | Player Initialization | Instantiate `res://scenes/player/player.tscn` | `current_health` initialized to `100`, max 100 | **PASS** |
| **TEST-04** | Health & Damage | Invoke `take_damage(30)`, `heal(15)`, `heal(100)` | Health reaches 70, then 85, capped at 100 | **PASS** |
| **TEST-05** | Velocity Normalization | Compute diagonal vector `(1, 1).normalized() * speed` | Vector length strictly matches `140.00` | **PASS** |
| **TEST-06** | Aim Rotation Math | Compute target direction from player origin | Angle matches exact expected radians | **PASS** |
| **TEST-07** | Reflection Formula Exactness | Calculate reflection for orthogonal & 45-degree vectors | $R = D - 2(D \cdot N)N$ matches vector reflection exactly | **PASS** |
| **TEST-08** | Security Ricochet Gun Setup | Verify default loaded weapon stats | Default weapon is Ricochet Gun with 2 bounces, 8 ammo | **PASS** |
| **TEST-09** | Firing & Ammo Consumption | Invoke `fire()` with muzzle position & aim direction | Ammo drops from 8 to 7, projectile spawns, SFX plays | **PASS** |
| **TEST-10** | Reload Cycle | Invoke `start_reload()` and complete cycle | Magazine restored to 8, reserve ammo deducted | **PASS** |
| **TEST-11** | Ricochet Upgrade Scaling | Apply upgrade levels 1 through 5 | Max bounces scale from 1 to 5 respectively | **PASS** |
| **TEST-12** | Holographic Trajectory Sight | Execute `update_trajectory_preview()` in physics space | Multi-point prediction line generated with bounce markers | **PASS** |
| **TEST-13** | Crawler Archetype Init | Instantiate Crawler and check stats | Max HP: 35, Speed: 125, Name: "Mutant Crawler" | **PASS** |
| **TEST-14** | Brute Armor Reduction | Inflict 20 damage on Brute with 40% armor | Only 12 damage taken, health drops to 108 | **PASS** |
| **TEST-15** | Enemy Death & Credit Reward | Apply lethal damage to Crawler | Transitions to DEAD state, grants +10 Credits | **PASS** |
| **TEST-16** | Scene Integration | Run `res://scenes/levels/test_level.tscn` | Arena loads, HUD renders, enemies navigate, 0 errors | **PASS** |
