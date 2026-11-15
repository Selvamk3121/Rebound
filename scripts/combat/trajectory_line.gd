class_name TrajectoryLine
extends Node2D

# REBOUND - Holographic Trajectory Prediction Line
# Renders predicted projectile path and bounce reflection points using RicochetMath.

@export var line_color: Color = Color(0.2, 0.85, 1.0, 0.6)
@export var marker_color: Color = Color(0.4, 0.95, 1.0, 0.85)
@export var line_width: float = 1.5

@onready var line_2d: Line2D = $Line2D

var bounce_markers: Array[Vector2] = []

func _ready() -> void:
	line_2d.top_level = true
	line_2d.width = line_width
	line_2d.default_color = line_color
	line_2d.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line_2d.end_cap_mode = Line2D.LINE_CAP_ROUND

func clear_trajectory() -> void:
	line_2d.clear_points()
	bounce_markers.clear()
	queue_redraw()

func update_trajectory(origin: Vector2, aim_dir: Vector2, max_bounces: int, max_dist: float, exclude_rids: Array[RID] = []) -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not space_state:
		return

	var points: Array[Vector2] = RicochetMath.simulate_trajectory(
		space_state,
		origin,
		aim_dir,
		max_bounces,
		max_dist,
		1, # Layer 1: Walls
		exclude_rids
	)

	line_2d.points = PackedVector2Array(points)
	
	# Keep record of intermediate bounce points for visual marker circles
	bounce_markers.clear()
	if points.size() > 2:
		for i in range(1, points.size() - 1):
			bounce_markers.append(points[i])
			
	queue_redraw()

func _draw() -> void:
	# Draw markers at reflection points in local space
	for global_marker in bounce_markers:
		var local_pos = to_local(global_marker)
		draw_circle(local_pos, 3.5, marker_color)
		draw_arc(local_pos, 5.0, 0, TAU, 12, marker_color, 1.0)
