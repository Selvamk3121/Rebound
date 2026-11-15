class_name Interactable
extends Area2D

# REBOUND - Universal Interactable Base Class
# Detects player presence, displays prompt label, and handles [E] interaction.

signal interacted(player: Player)

@export var prompt_message: String = "Interact"
@export var is_interactable: bool = true

var player_in_range: Player = null
var prompt_label: Label = null

func _ready() -> void:
	collision_layer = 32 # Layer 6: Interactables
	collision_mask = 2   # Layer 2: Player
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_create_prompt_label()

func _create_prompt_label() -> void:
	prompt_label = Label.new()
	prompt_label.text = "[E] " + prompt_message
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-60, -38)
	prompt_label.custom_minimum_size = Vector2(120, 20)
	prompt_label.modulate = Color(1.0, 0.9, 0.4, 0.95)
	prompt_label.visible = false
	prompt_label.z_index = 20
	add_child(prompt_label)

func set_prompt(new_prompt: String) -> void:
	prompt_message = new_prompt
	if prompt_label:
		prompt_label.text = "[E] " + prompt_message

func _unhandled_input(event: InputEvent) -> void:
	if not is_interactable or not player_in_range:
		return
		
	if event.is_action_pressed("interact"):
		interact(player_in_range)

func interact(player: Player) -> void:
	if not is_interactable:
		return
	GameManager.has_shown_pickup_prompt = true
	if prompt_label:
		prompt_label.visible = false
	interacted.emit(player)
	_on_interacted(player)

func _on_interacted(_player: Player) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body is Player and is_interactable:
		player_in_range = body as Player
		if prompt_label:
			if not GameManager.has_shown_pickup_prompt:
				prompt_label.text = "'e' to grab"
				prompt_label.visible = true
			else:
				# Show only for the first time
				prompt_label.visible = false

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		if prompt_label:
			prompt_label.visible = false
