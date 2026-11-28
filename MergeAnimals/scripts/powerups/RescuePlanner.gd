## Deterministic geometric rescue planning; no scene or physics mutation.
## Danger policy removes every animal crossing the danger line. Of the rest,
## choose a spawn x requiring the fewest additional removals; ties preserve
## higher-level animals, then prefer the old aim and finally the smaller x.
class_name RescuePlanner
extends RefCounted

static func plan(items: Array, danger_y: float, spawn_y: float, spawn_radius: float, min_x: float, max_x: float, desired_x: float, max_remove: int) -> Dictionary:
	if max_remove < 1 or min_x > max_x: return {}
	var mandatory: Array = []
	var others: Array = []
	for item in items:
		if float(item.y) - float(item.radius) < danger_y:
			mandatory.append(item)
		else:
			others.append(item)
	if mandatory.is_empty() or mandatory.size() > max_remove: return {}
	mandatory.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var top_a: float = float(a.y) - float(a.radius)
		var top_b: float = float(b.y) - float(b.radius)
		if not is_equal_approx(top_a, top_b): return top_a < top_b
		if int(a.level) != int(b.level): return int(a.level) < int(b.level)
		return int(a.uid) < int(b.uid)
	)
	# Each potential blocker projects to a closed interval of forbidden spawn x.
	# Endpoints and midpoints enumerate every distinct overlap set on the line.
	var edges: Array[float] = [min_x, max_x]
	var target := clampf(desired_x, min_x, max_x)
	var padding := spawn_radius + 1.25 # >= _spawn_clear's radius+1
	for item in others:
		var reach: float = float(item.radius) + padding
		var dy: float = absf(float(item.y) - spawn_y)
		if dy > reach: continue
		var dx: float = sqrt(maxf(0.0, reach * reach - dy * dy))
		var left: float = float(item.x) - dx
		var right: float = float(item.x) + dx
		if right < min_x or left > max_x: continue
		edges.append(clampf(left, min_x, max_x))
		edges.append(clampf(right, min_x, max_x))
	edges.sort()
	var points: Array[float] = [target, min_x, max_x]
	for i in range(edges.size() - 1):
		points.append((edges[i] + edges[i + 1]) * 0.5)
	var best: Array = []
	var best_x := target
	var best_count := 1000000
	var best_levels := 1000000
	var best_dist := INF
	for x in points:
		var blockers: Array = []
		var levels := 0
		for item in others:
			var reach: float = float(item.radius) + padding
			if Vector2(x, spawn_y).distance_squared_to(Vector2(float(item.x), float(item.y))) <= reach * reach:
				blockers.append(item)
				levels += int(item.level)
		var count := blockers.size()
		var dist := absf(x - target)
		if count < best_count or (count == best_count and (levels < best_levels or (levels == best_levels and (dist < best_dist - 0.0001 or (absf(dist - best_dist) < 0.0001 and x < best_x))))):
			best = blockers
			best_x = x
			best_count = count
			best_levels = levels
			best_dist = dist
	if mandatory.size() + best.size() > max_remove: return {}
	best.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.level) != int(b.level): return int(a.level) < int(b.level)
		return int(a.uid) < int(b.uid)
	)
	var ids: Array = []
	for item in mandatory + best: ids.append(int(item.uid))
	return {"remove_uids": ids, "spawn_x": best_x}
