class_name EnemyBase
extends CharacterBody2D

signal enemy_damaged(current_hp: int, max_hp: int)
signal enemy_died(enemy: EnemyBase)

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	DEAD
}

@export var stats: EnemyStats

var current_state: State = State.IDLE
var is_awake: bool = false
@export var wake_up_distance: float = 150.0

var current_health: int = 40
var target_player: Player = null
var attack_timer: float = 0.0
var hurt_timer: float = 0.0
var patrol_dir: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var hp_mult = GameManager.get_monster_health_multiplier()
	if stats:
		current_health = int(stats.max_health * hp_mult)
	else:
		current_health = int(40 * hp_mult)
		
	# Find player in tree
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0] as Player

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		velocity = Vector2.ZERO
		return
		
	if attack_timer > 0.0:
		attack_timer -= delta
		
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_process_hurt(delta)

func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	if not is_awake:
		if is_instance_valid(target_player) and not target_player.is_dead:
			var dist = global_position.distance_to(target_player.global_position)
			if dist <= wake_up_distance and _can_see_player():
				wake_up()
		return
		
	if _can_see_player():
		_transition_to(State.CHASE)
		return
		
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		patrol_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		patrol_timer = randf_range(1.5, 3.0)
		if randf() > 0.4:
			_transition_to(State.PATROL)

func wake_up() -> void:
	if is_awake:
		return
	is_awake = true
	_transition_to(State.CHASE)
	if sprite:
		var t = create_tween()
		t.tween_property(sprite, "modulate", Color(1.5, 1.3, 0.4, 1.0), 0.1)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	AudioManager.play_sfx("hit", 1.4)

func _process_patrol(delta: float) -> void:
	if _can_see_player():
		_transition_to(State.CHASE)
		return
		
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		_transition_to(State.IDLE)
		patrol_timer = randf_range(1.0, 2.5)
		return
		
	velocity = patrol_dir * (stats.move_speed * 0.5 if stats else 50.0)
	rotation = lerp_angle(rotation, patrol_dir.angle(), 0.1)
	move_and_slide()

func _process_chase(_delta: float) -> void:
	if not is_instance_valid(target_player) or target_player.is_dead:
		_transition_to(State.IDLE)
		return
		
	var dist_to_player = global_position.distance_to(target_player.global_position)
	var max_det = stats.detection_radius if stats else 240.0
	var atk_range = stats.attack_range if stats else 26.0
	
	if dist_to_player > max_det * 1.5:
		_transition_to(State.IDLE)
		return
		
	if dist_to_player <= atk_range:
		_transition_to(State.ATTACK)
		return
		
	var chase_dir = (target_player.global_position - global_position).normalized()
	velocity = chase_dir * (stats.move_speed if stats else 100.0)
	rotation = lerp_angle(rotation, chase_dir.angle(), 0.15)
	move_and_slide()

func _process_attack(_delta: float) -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(target_player) or target_player.is_dead:
		_transition_to(State.IDLE)
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	var atk_range = stats.attack_range if stats else 26.0
	
	if dist > atk_range * 1.2:
		_transition_to(State.CHASE)
		return
		
	if attack_timer <= 0.0:
		_execute_attack()

func _execute_attack() -> void:
	if not is_instance_valid(target_player) or target_player.is_dead:
		return
		
	var dmg = stats.damage if stats else 10
	var dmg_mult = GameManager.get_monster_damage_multiplier()
	target_player.take_damage(max(1, int(dmg * dmg_mult)))
	attack_timer = stats.attack_cooldown if stats else 1.0
	AudioManager.play_sfx("hit", randf_range(1.1, 1.3))
	
	# Slight lunge forward
	var lunge_dir = (target_player.global_position - global_position).normalized()
	velocity = lunge_dir * 180.0
	move_and_slide()

func _process_hurt(_delta: float) -> void:
	# Stun recovery
	if hurt_timer <= 0.0:
		_transition_to(State.CHASE)

func _can_see_player() -> bool:
	if not is_instance_valid(target_player) or target_player.is_dead:
		return false
		
	var dist = global_position.distance_to(target_player.global_position)
	var max_det = stats.detection_radius if stats else 240.0
	if dist > max_det:
		return false
		
	# Raycast check through walls (Layer 1)
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return true
		
	var query = PhysicsRayQueryParameters2D.create(global_position, target_player.global_position, 1)
	var result = space_state.intersect_ray(query)
	# If ray hit nothing, direct line of sight exists
	return result.is_empty()

func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
		
	if not is_awake:
		wake_up()
		
	var final_damage: int = amount
	if stats and stats.armor_reduction > 0.0:
		final_damage = int(amount * (1.0 - stats.armor_reduction))
		final_damage = max(1, final_damage)
		
	current_health -= final_damage
	var max_hp = stats.max_health if stats else 40
	enemy_damaged.emit(current_health, max_hp)
	
	# Hurt visual feedback
	if sprite:
		sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)
	hurt_timer = 0.2
	
	if current_health <= 0:
		die()
	else:
		_transition_to(State.HURT)
		# Aggro on attacker
		if not target_player:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				target_player = players[0] as Player

func die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	enemy_died.emit(self)
	
	if stats:
		GameManager.add_credits(stats.credit_reward)
		
	if sprite:
		sprite.modulate = Color(0.4, 0.1, 0.1, 0.6)
		
	# Disable collision
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(4, false)
	
	# Brief delay before removal
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(queue_free)

func _transition_to(new_state: State) -> void:
	current_state = new_state
