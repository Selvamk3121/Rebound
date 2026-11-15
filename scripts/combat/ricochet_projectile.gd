class_name RicochetProjectile
extends CharacterBody2D

# REBOUND - Ricochet Projectile
# Simulates physical projectile reflection off solid surfaces using shared RicochetMath.

signal bounced(bounce_count: int, hit_point: Vector2)
signal hit_target(target: Node2D)

@export var speed: float = 450.0
@export var damage: int = 25
@export var max_bounces: int = 2
@export var lifetime: float = 3.5

var current_bounces: int = 0
var direction: Vector2 = Vector2.RIGHT
var time_alive: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func initialize(start_pos: Vector2, dir: Vector2, dmg: int, spd: float, bounces: int, custom_texture: Texture2D = null) -> void:
	global_position = start_pos
	direction = dir.normalized()
	damage = dmg
	speed = spd
	max_bounces = bounces
	velocity = direction * speed
	rotation = direction.angle()
	if custom_texture and sprite:
		sprite.texture = custom_texture

func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		return

	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		
		# Check if struck an enemy or damageable entity
		if collider and collider.has_method("take_damage"):
			collider.take_damage(damage)
			hit_target.emit(collider)
			AudioManager.play_sfx("hit")
			queue_free()
			return
			
		# Check wall reflection
		if current_bounces < max_bounces:
			current_bounces += 1
			var normal: Vector2 = collision.get_normal()
			var reflected_dir: Vector2 = RicochetMath.calculate_reflection(velocity.normalized(), normal)
			velocity = reflected_dir * speed
			rotation = reflected_dir.angle()
			bounced.emit(current_bounces, collision.get_position())
			AudioManager.play_sfx("ricochet", randf_range(0.95, 1.05))
		else:
			# Reached maximum bounce limit
			AudioManager.play_sfx("hit")
			queue_free()
