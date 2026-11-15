class_name ArmouryBox
extends Interactable

# REBOUND - Safe Zone Weapon Upgrade Terminal

func _ready() -> void:
	super._ready()
	set_prompt("Access Weapon Armoury")

func _on_interacted(player: Player) -> void:
	var hud = _find_hud()
	if hud and hud.has_method("show_armoury_modal"):
		hud.show_armoury_modal(player)
		AudioManager.play_sfx("click")

func _find_hud() -> HUD:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		return huds[0] as HUD
	var scene = get_tree().current_scene
	if scene and scene.has_node("HUD"):
		return scene.get_node("HUD") as HUD
	return null
