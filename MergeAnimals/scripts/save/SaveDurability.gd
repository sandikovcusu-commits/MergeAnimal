extends Node
## Web checkpoint confirmation is a read-back of the exact committed IDBFS
## entry, NOT an fsync, a guarantee against eviction, or a cross-tab lock.
## Track project-owned primary and checkpoint files, not their backup copies.
## This does not make multiple files an atomic transaction.
const TRACKED := ["wild_garden_session.json", "wild_garden_powerup.json", "wild_garden_progress.json", "wild_garden_settings.json", "wild_garden_themes.json", "wild_garden_challenges.json", "wild_garden_achievements.json", "wild_garden_achievement_checkpoint.json"]
var initialized := false
var available := false
var global_indicator: Label
var status_poll := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"): return
	_create_indicator()
	available = OS.is_userfs_persistent()
	if not available: return
	JavaScriptBridge.eval("""
	(() => {
	  if (window.__wildGardenCheckpoint) return;
	  const tracker = { records: Object.create(null), next: 0 };
	  tracker.track = (path, expected) => {
	    const prev = tracker.records[path];
	    const now = Date.now();
	    const record = {id: ++tracker.next, state:'pending', since:
	      prev && prev.state === 'pending' ? prev.since : now};
	    tracker.records[path] = record;
	    const check = () => {
	      if (tracker.records[path] !== record || record.state !== 'pending') return;
	      if (Date.now() - record.since > 12000) { record.state='unconfirmed'; return; }
	      let req;
	      try { req = indexedDB.open('/userfs'); } catch (_) { record.state='unconfirmed'; return; }
	      req.onupgradeneeded = () => { try { req.transaction.abort(); } catch (_) {} };
	      req.onerror = () => { if (tracker.records[path] === record) record.state='unconfirmed'; };
	      req.onblocked = () => { if (tracker.records[path] === record) record.state='unconfirmed'; };
	      req.onsuccess = () => {
	        const db = req.result;
	        if (tracker.records[path] !== record) { db.close(); return; }
	        try {
	          const tx = db.transaction('FILE_DATA','readonly');
	          const get = tx.objectStore('FILE_DATA').get(path);
	          let matches = false;
	          get.onsuccess = () => {
	            try { const contents = get.result && get.result.contents;
	              matches = !!contents && new TextDecoder().decode(contents) === expected;
	            } catch (_) { matches = false; }
	          };
	          tx.oncomplete = () => {
	            db.close();
	            if (tracker.records[path] !== record) return;
	            if (matches) record.state='verified'; else setTimeout(check,250);
	          };
	          tx.onabort = tx.onerror = () => { db.close();
	            if (tracker.records[path] === record) record.state='unconfirmed'; };
	        } catch (_) { db.close(); if (tracker.records[path] === record) record.state='unconfirmed'; }
	      };
	    };
	    setTimeout(check,0);
	  };
	  tracker.fail = path => { tracker.records[path] = {id: ++tracker.next, state:'failed', since:Date.now()}; };
	  tracker.status = () => {
	    const entries = Object.values(tracker.records);
	    if (!entries.length) return 'idle';
	    if (entries.some(x => x.state === 'failed')) return 'failed';
	    if (entries.some(x => x.state === 'unconfirmed')) return 'unconfirmed';
	    if (entries.some(x => x.state === 'pending')) return 'pending';
	    return 'verified';
	  };
	  window.__wildGardenCheckpoint = tracker;
	})();
	""")
	initialized = true

func _create_indicator() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	global_indicator = Label.new()
	global_indicator.name = "SaveIndicator"
	global_indicator.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	global_indicator.offset_left = -300
	global_indicator.offset_right = -12
	global_indicator.offset_top = -42
	global_indicator.offset_bottom = -10
	global_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	global_indicator.add_theme_font_size_override("font_size", 15)
	global_indicator.add_theme_color_override("font_color", Color("31513d"))
	global_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	global_indicator.visible = false
	overlay.add_child(global_indicator)

func _process(delta: float) -> void:
	if not OS.has_feature("web") or not is_instance_valid(global_indicator): return
	status_poll += delta
	if status_poll < 0.25: return
	status_poll = 0.0
	# Classic and Challenge scenes provide their own context-specific status.
	var scene := get_tree().current_scene
	if scene and scene.has_method("save_session") and (bool(scene.get("persist_best")) or bool(scene.get("result_finished"))):
		global_indicator.visible = false
		return
	var status := state()
	global_indicator.visible = status != "idle"
	match status:
		"pending": global_indicator.text = tr("CHECKPOINT_SAVING")
		"verified": global_indicator.text = tr("CHECKPOINT_SAVED")
		"failed": global_indicator.text = tr("CHECKPOINT_FAILED")
		"unavailable": global_indicator.text = tr("CHECKPOINT_UNAVAILABLE")
		_: global_indicator.text = tr("CHECKPOINT_UNCONFIRMED")

func track(path: String, content: String) -> void:
	if not OS.has_feature("web") or path.get_file() not in TRACKED: return
	if not initialized or not available: return
	var absolute := ProjectSettings.globalize_path(path)
	if not absolute.begins_with("/userfs/"):
		available = false
		return
	JavaScriptBridge.eval("window.__wildGardenCheckpoint.track(%s,%s)" % [JSON.stringify(absolute), JSON.stringify(content)])

func failed(path: String) -> void:
	if not OS.has_feature("web") or path.get_file() not in TRACKED: return
	if not initialized or not available: return
	var absolute := ProjectSettings.globalize_path(path)
	if absolute.begins_with("/userfs/"):
		JavaScriptBridge.eval("window.__wildGardenCheckpoint.fail(%s)" % JSON.stringify(absolute))

func state() -> String:
	if not OS.has_feature("web"): return "native"
	if not initialized or not available: return "unavailable"
	var result: Variant = JavaScriptBridge.eval("window.__wildGardenCheckpoint ? window.__wildGardenCheckpoint.status() : 'unconfirmed'")
	return str(result) if result in ["idle", "pending", "verified", "unconfirmed", "failed"] else "unavailable"
