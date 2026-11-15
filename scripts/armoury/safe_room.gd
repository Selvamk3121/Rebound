extends Node2D

# REBOUND - Safe Zone Hub Controller (Monsters Free)

@onready var player: Player = $Player
@onready var hud: HUD = $HUD

func _ready() -> void:
	if hud and player:
		hud.setup_player(player)
		hud.update_threats(0, 0)
		hud.show_notification("SAFE ZONE ACCESSED: No biological threats detected. Upgrade weapon at Armoury.")
