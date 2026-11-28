## Adapter boundary only; no advertising SDK, reward, or inventory is implemented here.
## A platform integration may listen to requested and must call resolve only after
## receiving and verifying that platform's completion callback. Never resolve on
## button press, ad start, close, timeout, or a client-side simulation.
class_name RewardRequestGateway
extends RefCounted

signal requested(request_id: int, kind: StringName)
signal resolved(request_id: int, kind: StringName, earned: bool)

const EXTRA_UNDO: StringName = &"extra_undo"
const EXTRA_REMOVE: StringName = &"extra_remove"
const RESCUE: StringName = &"rescue"
const KINDS := [EXTRA_UNDO, EXTRA_REMOVE, RESCUE]

var _next_id: int = 1
var _pending_id: int = 0
var _pending_kind: StringName = &""

## Returns 0 if unsupported or another request is outstanding.
func request(kind: StringName) -> int:
	if kind not in KINDS or _pending_id != 0:
		return 0
	var id := _next_id
	_next_id += 1
	_pending_id = id
	_pending_kind = kind
	requested.emit(id, kind)
	return id

## Platform adapter is responsible for verification; stale callbacks are ignored.
## Returns true only for the first callback matching the outstanding request.
func resolve(request_id: int, earned: bool) -> bool:
	if request_id <= 0 or request_id != _pending_id:
		return false
	var kind := _pending_kind
	_pending_id = 0
	_pending_kind = &""
	resolved.emit(request_id, kind, earned)
	return true

func has_pending_request() -> bool:
	return _pending_id != 0
