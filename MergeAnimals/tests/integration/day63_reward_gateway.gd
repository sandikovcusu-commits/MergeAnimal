extends SceneTree
const Gateway = preload("res://scripts/powerups/RewardRequestGateway.gd")
var checks := 0
var failures := 0
var requests: Array = []
var results: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if value else "FAIL", message])
	if not value: failures += 1

func run() -> void:
	var gateway = Gateway.new()
	gateway.requested.connect(func(id: int, kind: StringName): requests.append([id, kind]))
	gateway.resolved.connect(func(id: int, kind: StringName, earned: bool): results.append([id, kind, earned]))
	check(gateway.request(&"unsupported") == 0 and requests.is_empty(), "unknown reward rejected")
	var undo: int = gateway.request(Gateway.EXTRA_UNDO)
	check(undo > 0 and requests.size() == 1 and results.is_empty(), "request alone grants nothing")
	check(gateway.has_pending_request() and gateway.request(Gateway.EXTRA_REMOVE) == 0, "only one pending request")
	check(not gateway.resolve(undo + 1, true) and results.is_empty(), "unrelated callback ignored")
	check(gateway.resolve(undo, false) and results.size() == 1 and results[0][2] == false, "failed callback does not earn reward")
	check(not gateway.has_pending_request() and not gateway.resolve(undo, true) and results.size() == 1, "duplicate callback ignored")
	var remove: int = gateway.request(Gateway.EXTRA_REMOVE)
	check(remove != undo and gateway.resolve(remove, true), "distinct remove request accepts successful callback")
	check(results.size() == 2 and results[1] == [remove, Gateway.EXTRA_REMOVE, true], "success reports only the matching request")
	var rescue: int = gateway.request(Gateway.RESCUE)
	check(rescue > remove and not gateway.resolve(remove, true), "old callback cannot resolve a new request")
	check(gateway.resolve(rescue, true) and results.size() == 3 and results[2] == [rescue, Gateway.RESCUE, true], "rescue callback reported once")
	print("Reward gateway checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
