# REBOUND: Project Structure & File Layout

## 1. Overview
This document specifies the filesystem layout and role of each directory in the REBOUND Godot 4.x project.

```
REBOUND/
├── project.godot               # Main Godot 4 project definition and configuration
├── autoload/                   # Global singleton managers
│   ├── game_manager.gd         # Game state, level transitions, pause status, digital credits
│   ├── inventory_manager.gd    # Backpack slots, item stacking, inventory queries
│   ├── audio_manager.gd        # Dynamic audio bus manager, SFX pooling, ambience loop
│   └── save_manager.gd         # Serialization and deserialization to user:// storage
├── scenes/
│   ├── player/
│   │   └── player.tscn         # CharacterBody2D player with aiming pivot and camera
│   ├── objects/
│   │   └── wall_block.tscn     # Modular collision barrier
│   ├── levels/
│   │   └── test_level.tscn     # Phase 1 test arena
│   ├── weapons/                # Weapon nodes and projectiles
│   ├── enemies/                # Enemy base and variants (Crawler, Brute, Stalker, Prototype)
│   ├── ui/                     # Heads-up display, inventory, pause, crafting screens
│   └── armoury/                # Safe zone hub and fabricator
├── scripts/
│   ├── player/
│   │   └── player.gd           # 8-direction movement, health, mouse-pivot aiming
│   ├── combat/                 # Shared Ricochet math and projectile logic
│   ├── enemies/                # Enemy state machines
│   ├── inventory/              # Inventory data models
│   ├── crafting/               # Recipe validation and crafting logic
│   ├── puzzles/                # Fuse, power panel, and security door state logic
│   └── ui/                     # UI view controllers
├── assets/
│   ├── sprites/                # CC0 sprite assets (player, tiles, enemies, weapons)
│   ├── audio/
│   │   ├── sfx/                # Sound effects (laser, ricochet, reload, footsteps, click, hit)
│   │   └── ambience/           # Background atmospheric industrial loops
│   └── fonts/
├── tests/
│   ├── test_runner.tscn        # Scene-based test harness
│   └── test_runner.gd          # Automated regression tests
└── docs/                       # Technical project documentation
    ├── DEVELOPMENT_MANUAL.md
    ├── GAME_DESIGN_DOCUMENT.md
    ├── PROJECT_STRUCTURE.md
    ├── CONTROLS.md
    └── TESTING_REPORT.md
```
