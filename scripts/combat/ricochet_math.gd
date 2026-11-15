class_name RicochetMath
extends RefCounted

# REBOUND - Shared Ricochet Physics & Reflection Utility
# Guarantees that Holographic Trajectory Prediction and Actual Projectile
# use the exact same reflection formulas and collision rules.

# R = D - 2(D · N)N
static func calculate_reflection(direction: Vector2, normal: Vector2) -> Vector2:
	var d = direction.normalized()
	var n = normal.normalized()
	return d - 2.0 * (d.dot(n)) * n

# Simulates ricochet path through physics space
# Returns an Array of Vector2 representing the path points: [start_pos, bounce_1, bounce_2, ..., end_pos]
static func simulate_trajectory(
	space_state: PhysicsDirectSpaceState2D,
	start_pos: Vector2,
	initial_direction: Vector2,
	max_bounces: int,
	max_distance: float,
	collision_mask: int = 1, # Layer 1: Walls
	exclude_rids: Array[RID] = []
) -> Array[Vector2]:
	var points: Array[Vector2] = [start_pos]
	var current_pos: Vector2 = start_pos
	var current_dir: Vector2 = initial_direction.normalized()
	var remaining_distance: float = max_distance
	var remaining_bounces: int = max_bounces

	while remaining_distance > 1.0:
		var target_pos: Vector2 = current_pos + (current_dir * remaining_distance)
		
		var query = PhysicsRayQueryParameters2D.create(current_pos, target_pos, collision_mask, exclude_rids)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var result = space_state.intersect_ray(query)
		
		if result.is_empty():
			# No collision: trajectory travels the full remaining distance
			points.append(target_pos)
			break
		else:
			# Collision occurred
			var hit_point: Vector2 = result["position"]
			var hit_normal: Vector2 = result["normal"]
			points.append(hit_point)
			
			var segment_len: float = current_pos.distance_to(hit_point)
			remaining_distance -= segment_len
			
			if remaining_bounces <= 0:
				break
				
			remaining_bounces -= 1
			current_dir = calculate_reflection(current_dir, hit_normal)
			# Nudge origin slightly along normal to prevent re-colliding with same surface
			current_pos = hit_point + (hit_normal * 0.5)

	return points
