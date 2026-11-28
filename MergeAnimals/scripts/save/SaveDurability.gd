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
	    // A new immutable envelope is a new request, not the continuation of
	    // an older request's deadline. Superseded callbacks may never verify it.
	    const record = {id: ++tracker.next, state:'pending', expected,
	      since:Date.now(), attempts:0, retries:0};
	    tracker.records[path] = record;
	    let timer = null;
	    const current = () => tracker.records[path] === record;
	    const recover = () => {
	      if (!current() || record.state === 'verified' || timer !== null) return;
	      record.state = 'unconfirmed';
	      // Bounded read-only retry after transient errors or the normal 12s
	      // deadline; never rewrite a snapshot or claim a verification.
	      if (record.retries >= 3) return;
	      const delay = 1000 * Math.pow(2, record.retries++);
	      timer = setTimeout(() => { timer = null; check(); }, delay);
	    };
	    const check = () => {
	      if (!current() || record.state === 'verified' || record.state === 'failed') return;
	      if (record.state === 'pending' && Date.now() - record.since > 12000) { recover(); return; }
	      record.attempts++;
	      let req, tx, settled = false;
	      let watchdog;
	      const fail = () => {
	        if (settled) return;
	        settled = true; clearTimeout(watchdog);
	        if (tx) { try { tx.abort(); } catch (_) {} }
	        if (current()) recover();
	      };
	      // A blocked readonly transaction may not emit any callback while a
	      // writer holds the store. Bound each attempt without extending the
	      // original 12 second confirmation deadline.
	      const wait = record.state === 'pending' ? Math.max(0, 12000 - (Date.now() - record.since)) : 12000;
	      watchdog = setTimeout(fail, wait);
	      try { req = indexedDB.open('/userfs'); } catch (_) { fail(); return; }
	      req.onupgradeneeded = () => { try { req.transaction.abort(); } catch (_) {} };
	      req.onerror = fail;
	      req.onblocked = fail;
	      req.onsuccess = () => {
	        const db = req.result;
	        if (settled || !current()) { clearTimeout(watchdog); db.close(); return; }
	        try {
	          tx = db.transaction('FILE_DATA','readonly');
	          const get = tx.objectStore('FILE_DATA').get(path);
	          let matches = false;
	          get.onsuccess = () => {
	            try { const contents = get.result && get.result.contents;
	              matches = !!contents && new TextDecoder().decode(contents) === expected;
	            } catch (_) { matches = false; }
	          };
	          tx.oncomplete = () => {
	            db.close();
	            if (settled || !current()) { clearTimeout(watchdog); return; }
	            settled = true; clearTimeout(watchdog);
	            if (matches) record.state='verified';
	            else if (record.state === 'pending') setTimeout(check,250);
	            else recover();
	          };
	          tx.onabort = tx.onerror = () => { db.close(); fail(); };
	        } catch (_) { db.close(); fail(); }
	      };
	    };
	    setTimeout(check,0);
	  };
	  tracker.fail = path => { tracker.records[path] = {id: ++tracker.next, state:'failed', since:Date.now()}; };
	  // Only the exact tracked envelope for this path may confirm a revision.
	  tracker.statusFor = (path, expected) => {
	    const record = tracker.records[path];
	    if (!record) return 'unconfirmed';
	    if (record.state === 'failed') return 'failed';
	    return record.expected === expected ? record.state : 'unconfirmed';
	  };
	  tracker.status = () => {
	    const entries = Object.values(tracker.records);
	    if (!entries.length) return 'idle';
	    if (entries.some(x => x.state === 'failed')) return 'failed';
	    if (entries.some(x => x.state === 'unconfirmed')) return 'unconfirmed';
	    if (entries.some(x => x.state === 'pending')) return 'pending';
	    return 'verified';
	  };
	  // Aggregate only the files that make up one checkpoint commit. An
	  // unrelated file (settings, achievements, ...) must not block the
	  // session checkpoint status, and a stale record for a required file
	  // still blocks it until its own latest write verifies.
	  tracker.statusForFiles = (paths) => {
	    const entries = paths.map(p => tracker.records[p]).filter(Boolean);
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

func state_for(path: String, expected: String) -> String:
	if not OS.has_feature("web"): return "native"
	if not initialized or not available: return "unavailable"
	if expected.is_empty(): return "unconfirmed"
	var absolute := ProjectSettings.globalize_path(path)
	var result: Variant = JavaScriptBridge.eval("window.__wildGardenCheckpoint ? window.__wildGardenCheckpoint.statusFor(%s,%s) : 'unconfirmed'" % [JSON.stringify(absolute), JSON.stringify(expected)])
	return str(result) if result in ["pending", "verified", "unconfirmed", "failed"] else "unconfirmed"

func state() -> String:
	if not OS.has_feature("web"): return "native"
	if not initialized or not available: return "unavailable"
	var result: Variant = JavaScriptBridge.eval("window.__wildGardenCheckpoint ? window.__wildGardenCheckpoint.status() : 'unconfirmed'")
	return str(result) if result in ["idle", "pending", "verified", "unconfirmed", "failed"] else "unavailable"

func state_for_files(paths: Array) -> String:
	if not OS.has_feature("web"): return "native"
	if not initialized or not available: return "unavailable"
	var absolute: Array = []
	for path in paths:
		var candidate := ProjectSettings.globalize_path(str(path))
		if candidate.begins_with("/userfs/"):
			absolute.append(candidate)
	if absolute.is_empty(): return "unavailable"
	var result: Variant = JavaScriptBridge.eval("window.__wildGardenCheckpoint ? window.__wildGardenCheckpoint.statusForFiles(%s) : 'unconfirmed'" % JSON.stringify(absolute))
	return str(result) if result in ["idle", "pending", "verified", "unconfirmed", "failed"] else "unavailable"
