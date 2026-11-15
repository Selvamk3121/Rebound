class_name SectorLevel
extends Node2D

# REBOUND - Universal Combat Sector Controller
# Manages threat count, level difficulty scaling, exit airlock unlocking, and HUD integration.

@export var level_number: int = 1
@export var sector_name: String = "Sector"

@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var enemies_container: Node2D = $Enemies
@onready var exit_door: SectorDoor = $ExitDoor

var total_enemies: int = 0
var remaining_enemies: int = 0
var level_cleared: bool = false

func _ready() -> void:
	GameManager.current_level_number = level_number
	if hud and player:
		hud.setup_player(player)
		GameManager.player_died.connect(_on_player_died)
		hud.show_notification("ENTERING %s (Level %d/5)" % [sector_name.to_upper(), level_number])
		
	_setup_enemy_tracking()

func _setup_enemy_tracking() -> void:
	if not enemies_container:
		return
		
	var enemies = enemies_container.get_children()
	total_enemies = enemies.size()
	remaining_enemies = total_enemies
	
	if hud:
		hud.update_threats(remaining_enemies, total_enemies)
		
	for enemy in enemies:
		if enemy is EnemyBase:
			enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(_enemy: EnemyBase) -> void:
	remaining_enemies = max(0, remaining_enemies - 1)
	if hud:
		hud.update_threats(remaining_enemies, total_enemies)
		
	if remaining_enemies == 0 and not level_cleared:
		level_cleared = true
		_on_all_mobs_cleared()

func _on_all_mobs_cleared() -> void:
	AudioManager.play_sfx("pickup")
	if exit_door:
		exit_door.unlock_exit_airlock()
	if hud:
		hud.show_notification("SECTOR PURGED: Airlock door to Safe Room is unlocked!")
		hud.show_victory_screen(total_enemies, GameManager.credits)

func _on_player_died() -> void:
	if hud and not level_cleared:
		hud.show_game_over_screen()
