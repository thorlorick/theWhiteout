class_name PatrolComponent

var nav_region: NavigationRegion2D = null

func setup(region: NavigationRegion2D) -> void:
	nav_region = region

func get_random_point() -> Vector2:
	return NavigationServer2D.map_get_random_point(
		nav_region.get_navigation_map(),
		1,
		false
	)
