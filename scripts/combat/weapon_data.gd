class_name WeaponData
extends Resource

# REBOUND - Weapon Configuration Resource

enum WeaponType {
	STANDARD,
	RICOCHET,
	ADVANCED,
	HEAVY
}

@export var weapon_name: String = "Security Ricochet Gun"
@export var weapon_type: WeaponType = WeaponType.RICOCHET
@export var damage: int = 25
@export var projectile_speed: float = 450.0
@export var max_bounces: int = 2
@export var upgrade_level: int = 1
@export var max_ammo: int = 8
@export var current_ammo: int = 8
@export var reserve_ammo: int = 32
@export var reload_time: float = 1.2
@export var fire_rate: float = 0.35
@export var preview_distance: float = 380.0
@export var projectile_lifetime: float = 3.0
@export var sprite_frame: int = 2
@export var muzzle_offset: Vector2 = Vector2(24, 6)

# Enhanced weapon presentation attributes from sample
@export var icon_texture: Texture2D
@export var projectile_texture: Texture2D
@export var muzzle_flash_texture: Texture2D
@export var pellets: int = 1
@export var spread_angle: float = 0.0
@export var sfx_name: String = "laser_fire"

# Set upgrade level (1 to 5) and scale statistics
func apply_upgrade_level(lvl: int) -> void:
	upgrade_level = clampi(lvl, 1, 5)
	max_bounces = upgrade_level # Level 1 = 1, Level 2 = 2, ..., Level 5 = 5
	damage = 20 + (upgrade_level * 5)
	projectile_speed = 400.0 + (upgrade_level * 30.0)
	preview_distance = 320.0 + (upgrade_level * 50.0)
