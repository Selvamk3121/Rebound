class_name MainMenu
extends Control

# REBOUND - Main Starting Menu & Tactical Guidance Controller

@onready var start_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/StartButton
@onready var guidance_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/GuidanceButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/ExitButton

@onready var guidance_modal: Control = $GuidanceModal
@onready var close_guidance_button: Button = $GuidanceModal/Panel/MarginContainer/VBoxContainer/CloseGuidanceButton

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.mouse_entered.connect(_on_button_hover)
		start_button.grab_focus()
		
	if guidance_button:
		guidance_button.pressed.connect(_on_guidance_pressed)
		guidance_button.mouse_entered.connect(_on_button_hover)
		
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
		exit_button.mouse_entered.connect(_on_button_hover)
		
	if close_guidance_button:
		close_guidance_button.pressed.connect(_on_close_guidance_pressed)
		close_guidance_button.mouse_entered.connect(_on_button_hover)

func _unhandled_input(event: InputEvent) -> void:
	if guidance_modal and guidance_modal.visible:
		if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE):
			_on_close_guidance_pressed()
			get_viewport().set_input_as_handled()
	else:
		if event is InputEventKey and event.pressed and not event.is_echo():
			if event.keycode == KEY_G:
				_on_guidance_pressed()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				_on_start_pressed()
				get_viewport().set_input_as_handled()

func _on_button_hover() -> void:
	AudioManager.play_sfx("click", 1.2)

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click", 1.0)
	GameManager.current_state = GameManager.GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/levels/test_level.tscn")

func _on_guidance_pressed() -> void:
	AudioManager.play_sfx("click", 1.0)
	if guidance_modal:
		guidance_modal.visible = true
		if close_guidance_button:
			close_guidance_button.grab_focus()

func _on_close_guidance_pressed() -> void:
	AudioManager.play_sfx("click", 0.9)
	if guidance_modal:
		guidance_modal.visible = false
	if start_button:
		start_button.grab_focus()

func _on_exit_pressed() -> void:
	AudioManager.play_sfx("click", 0.8)
	get_tree().quit()
