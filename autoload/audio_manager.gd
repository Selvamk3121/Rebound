extends Node

# REBOUND - Audio Manager Autoload
# Handles playing SFX and looping background ambience.

var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer

var sound_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = "Master"
	add_child(ambience_player)
	
	# Pool of SFX players
	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
		
	# Pre-load available sounds
	_load_sound("laser_fire", "res://assets/audio/sfx/laser_fire.ogg")
	_load_sound("ricochet", "res://assets/audio/sfx/ricochet.ogg")
	_load_sound("reload", "res://assets/audio/sfx/reload.ogg")
	_load_sound("footstep", "res://assets/audio/sfx/footstep.ogg")
	_load_sound("door_open", "res://assets/audio/sfx/door_open.ogg")
	_load_sound("click", "res://assets/audio/sfx/click.ogg")
	_load_sound("pickup", "res://assets/audio/sfx/pickup.ogg")
	_load_sound("hit", "res://assets/audio/sfx/hit.ogg")
	
	_start_ambience()

func _load_sound(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			sound_cache[key] = stream

func play_sfx(sound_name: String, pitch_scale: float = 1.0) -> void:
	if not sound_cache.has(sound_name):
		return
	var stream: AudioStream = sound_cache[sound_name]
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.play()
			return
	# If all busy, steal the first one
	sfx_players[0].stream = stream
	sfx_players[0].pitch_scale = pitch_scale
	sfx_players[0].play()

func _start_ambience() -> void:
	var path: String = "res://assets/audio/ambience/ambience_industrial.wav"
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			ambience_player.stream = stream
			ambience_player.volume_db = -12.0
			ambience_player.play()
