"""Test-only candidate: bound a single downward physics-step at the floor.
Not production code; comparing this with an unmodified baseline does not imply
that the resulting feel or behavior is acceptable.
"""
from pathlib import Path
import sys
p=Path(sys.argv[1])/'scripts/gameplay/Animal.gd'
s=p.read_text();needle='''func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	supported = false'''
replace='''func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Experimental single-step floor bound, active only in an isolated CI copy.
	var pieces := get_parent()
	var board := pieces.get_parent() if pieces else null
	if board is Node2D and board.get("floor_height") != null and state.step > 0.0:
		var position_in_board: Vector2 = board.to_local(state.transform.origin)
		var speed_in_board: Vector2 = board.global_transform.basis_xform_inv(state.linear_velocity)
		var gap: float = float(board.floor_height) - data.radius - position_in_board.y
		if gap >= 0.0 and speed_in_board.y > 0.0 and speed_in_board.y * state.step > gap:
			speed_in_board.y = maxf(0.0, gap / state.step)
			state.linear_velocity = board.global_transform.basis_xform(speed_in_board)
	supported = false'''
if s.count(needle)!=1: raise SystemExit('unexpected Animal.gd')
p.write_text(s.replace(needle,replace))
