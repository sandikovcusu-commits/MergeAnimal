extends Node
## SDK integration is opt-in via the experimental Web export feature. Until
## reward persistence/UI are verified, Local/No Ads is the only provider.
signal provider_changed(provider: String)
const INIT_TIMEOUT := 8.0
var provider := "local"
var sdk_state := "unavailable"
var sdk_environment := "disabled"
var platform_muted := false
var gameplay_active := false
var _sent_gameplay := false
var _elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web") and OS.has_feature("crazygames"):
		sdk_state = "initializing"

func _process(delta: float) -> void:
	if sdk_state == "ready":
		# The platform's mute setting takes precedence over the local setting.
		var muted = JavaScriptBridge.eval("!!(window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.game && window.CrazyGames.SDK.game.settings && window.CrazyGames.SDK.game.settings.muteAudio)")
		if typeof(muted) == TYPE_BOOL and muted != platform_muted:
			platform_muted = muted
			# Resolve lazily: autoloads compile before imported fonts exist in
			# a fresh project/editor import.
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
		provider_changed.emit(provider)
	elif _elapsed >= INIT_TIMEOUT:
		sdk_state = "unavailable"
		provider_changed.emit(provider)

# Idempotence avoids duplicate platform events. Local/no-SDK stays a no-op.
func set_gameplay_active(active: bool) -> void:
	if gameplay_active == active: return
	gameplay_active = active
	_sync_gameplay()

func _sync_gameplay() -> void:
	if sdk_state != "ready" or gameplay_active == _sent_gameplay: return
	if gameplay_active: CrazyGames.Game.gameplay_start()
	else: CrazyGames.Game.gameplay_stop()
	_sent_gameplay = gameplay_active

# Explicitly fail closed until the reward checkpoint, UI and Web callback tests
# are complete. No ad button should be shown based merely on SDK initialization.
func rewarded_available() -> bool:
	return false
