class_name PatrolComponent

var waypoints: Array[Vector2] = []
var current_index: int = 0
var num_waypoints: int = 20

func generate_waypoints(nav_region: NavigationRegion2D) -> void:
	waypoints.clear()
	current_index = 0
	
	var poly = nav_region.navigation_polygon
	var verts = poly.get_vertices()
	
	var min_x = verts[0].x
	var max_x = verts[0].x
	var min_y = verts[0].y
	var max_y = verts[0].y
	
	for v in verts:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)
	
	for i in range(num_waypoints):
		var random_point = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
		waypoints.append(random_point)

func get_current_waypoint() -> Vector2:
	return waypoints[current_index]

func advance() -> void:
	current_index += 1

func has_next() -> bool:
	return current_index < waypoints.size()

func is_complete() -> bool:
	return current_index >= waypoints.size()

