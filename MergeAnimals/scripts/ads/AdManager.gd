extends Node
## Only the explicit full-launch rewarded export permits ads. Basic Launch and
## ordinary builds remain fail-closed even when the SDK itself is available.
signal provider_changed(provider: String)
signal rescue_result(session_id: String, transaction_id: String, earned: bool, outcome: String)
const INIT_TIMEOUT := 8.0
const REQUEST_TIMEOUT := 20.0
const PLAYING_TIMEOUT := 180.0
var provider := "local"
var sdk_state := "unavailable"
var sdk_environment := "disabled"
var platform_muted := false
var gameplay_active := false
var _sent_gameplay := false
var _elapsed := 0.0
var adblock_checked := false
var adblock_present := true
var ads_disabled := false
var ad_state := "idle"
var transaction_id := ""
var transaction_session := ""
var transaction_owner: WeakRef
var _ad_elapsed := 0.0
var _was_tree_paused := false
var _audio_was_paused := false
var _audio_suspended := false
var _callback: JavaScriptObject
var _blocker: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web") and OS.has_feature("crazygames"):
		sdk_state = "initializing"
		CrazyGamesBridge.callbacks.adblock_detection_result.connect(_on_adblock_result)
		_callback = JavaScriptBridge.create_callback(_on_web_ad_callback)
		JavaScriptBridge.get_interface("window").mergeRescueAdCallback = _callback

func _on_adblock_result(present: bool) -> void:
	adblock_checked = true
	adblock_present = present
	_refresh_provider()

func _refresh_provider() -> void:
	provider = "crazygames" if rewarded_available() else "local"
	provider_changed.emit(provider)

func _process(delta: float) -> void:
	if ad_state in ["requested", "started"]:
		_ad_elapsed += delta
		if not is_instance_valid(transaction_owner.get_ref() if transaction_owner else null):
			_finish_ad("owner_gone", false)
		elif _ad_elapsed >= (PLAYING_TIMEOUT if ad_state == "started" else REQUEST_TIMEOUT):
			ads_disabled = true # quarantine unknown late SDK callbacks for this process
			_finish_ad("timeout", false)
	if sdk_state == "ready":
		var muted = JavaScriptBridge.eval("!!(window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.game && window.CrazyGames.SDK.game.settings && window.CrazyGames.SDK.game.settings.muteAudio)")
		if typeof(muted) in [TYPE_BOOL, TYPE_INT] and bool(muted) != platform_muted:
			platform_muted = bool(muted)
			var store = load("res://scripts/ui/SettingsStore.gd")
			if store: store.apply(store.load_values())
		return
	if sdk_state != "initializing": return
	_elapsed += delta
	if CrazyGames.is_initialised:
		var environment = JavaScriptBridge.eval("window.CrazyGames && window.CrazyGames.SDK ? window.CrazyGames.SDK.environment : 'disabled'")
		sdk_environment = str(environment) if environment != null else "disabled"
		if sdk_environment in ["local", "crazygames"]:
			sdk_state = "ready"
			_sync_gameplay()
		else:
			sdk_state = "unavailable"
		_refresh_provider()
	elif _elapsed >= INIT_TIMEOUT:
		sdk_state = "unavailable"
		_refresh_provider()

func set_gameplay_active(active: bool) -> void:
	if gameplay_active == active: return
	gameplay_active = active
	_sync_gameplay()

func _sync_gameplay() -> void:
	if sdk_state != "ready" or gameplay_active == _sent_gameplay: return
	if gameplay_active: CrazyGames.Game.gameplay_start()
	else: CrazyGames.Game.gameplay_stop()
	_sent_gameplay = gameplay_active

func rewarded_available() -> bool:
	return OS.has_feature("web") and OS.has_feature("crazygames_rewarded") and sdk_state == "ready" and sdk_environment in ["local", "crazygames"] and adblock_checked and not adblock_present and not ads_disabled and ad_state not in ["requested", "started"]

func request_rescue(session: String, owner: Node) -> String:
	if not rewarded_available() or session.is_empty() or not is_instance_valid(owner): return ""
	transaction_id = Crypto.new().generate_random_bytes(16).hex_encode()
	transaction_session = session
	transaction_owner = weakref(owner)
	ad_state = "requested"
	_ad_elapsed = 0.0
	_was_tree_paused = get_tree().paused
	var audio := get_node_or_null("/root/AudioManager")
	_audio_was_paused = audio.ad_audio_paused if audio else false
	_audio_suspended = false
	if owner.has_method("cancel_for_ad"): owner.cancel_for_ad()
	get_tree().paused = true
	_make_blocker()
	# The official Godot wrapper's global ad signals are not transaction-tagged.
	# Use the documented official HTML5 SDK callback API through its same SDK,
	# with per-request closures. Only adFinished yields a successful result.
	var js := """
	(function(){const tx=%s, session=%s;
	 const emit=(state,error)=>queueMicrotask(()=>window.mergeRescueAdCallback(JSON.stringify({tx:tx,session:session,state:state,error:error||''})));
	 try {window.CrazyGames.SDK.ad.requestAd('rewarded',{
	   adStarted:()=>emit('started',''),
	   adFinished:()=>emit('finished',''),
	   adError:(error)=>emit('error',String((error&&error.code)||'other'))
	 });} catch(e) {emit('error','exception');}
	})()
	""" % [JSON.stringify(transaction_id), JSON.stringify(transaction_session)]
	var issued := transaction_id
	JavaScriptBridge.eval(js)
	return issued

func _on_web_ad_callback(args: Array) -> void:
	if args.is_empty() or typeof(args[0]) != TYPE_STRING: return
	var data = JSON.parse_string(args[0])
	if not data is Dictionary: return
	if str(data.get("tx", "")) != transaction_id or str(data.get("session", "")) != transaction_session or ad_state not in ["requested", "started"]:
		print("AD_CALLBACK ignored stale or duplicate")
		return
	var owner = transaction_owner.get_ref() if transaction_owner else null
	if not is_instance_valid(owner) or str(owner.get("session_id")) != transaction_session:
		_finish_ad("owner_gone", false)
		return
	match str(data.get("state", "")):
		"started":
			if ad_state != "requested": return
			ad_state = "started"
			_ad_elapsed = 0.0
			var audio := get_node_or_null("/root/AudioManager")
			if audio:
				audio.set_ad_audio_paused(true)
				_audio_suspended = true
			print("AD_STATE started tx=%s session=%s" % [transaction_id, transaction_session])
		"finished": _finish_ad("finished", true)
		"error":
			ads_disabled = true # do not show an ineffective offer after unfilled/adblock/disabled
			_finish_ad("error:" + str(data.get("error", "other")), false)

func _finish_ad(outcome: String, earned: bool) -> void:
	if ad_state not in ["requested", "started"]: return
	var id := transaction_id
	var session := transaction_session
	var owner = transaction_owner.get_ref() if transaction_owner else null
	ad_state = outcome
	transaction_id = ""
	transaction_session = ""
	transaction_owner = null
	if is_instance_valid(_blocker): _blocker.queue_free()
	_blocker = null
	if _audio_suspended and not _audio_was_paused:
		var audio := get_node_or_null("/root/AudioManager")
		if audio: audio.set_ad_audio_paused(false)
	_audio_suspended = false
	get_tree().paused = _was_tree_paused
	print("AD_STATE %s tx=%s session=%s" % [outcome, id, session])
	_refresh_provider()
	if is_instance_valid(owner) and str(owner.get("session_id")) == session:
		rescue_result.emit(session, id, earned, outcome)

func _make_blocker() -> void:
	_blocker = CanvasLayer.new()
	_blocker.layer = 1000
	_blocker.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_blocker)
	var cover := ColorRect.new()
	cover.color = Color(0, 0, 0, 0.55)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.add_child(cover)
	var label := Label.new()
	label.text = "Advertisement…"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(label)

func _input(_event: InputEvent) -> void:
	if ad_state in ["requested", "started"]: get_viewport().set_input_as_handled()
