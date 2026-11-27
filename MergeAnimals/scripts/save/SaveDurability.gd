extends Node
## Web checkpoint confirmation is a read-back of the exact committed IDBFS
## entry, NOT an fsync, a guarantee against eviction, or a cross-tab lock.
## Only the Classic session and power-up checkpoint paths are observed.
const TRACKED := ["wild_garden_session.json", "wild_garden_powerup.json"]
var initialized := false
var available := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"): return
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
	      prev && prev.state !== 'verified' ? prev.since : now};
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
	  tracker.status = () => {
	    const entries = Object.values(tracker.records);
	    if (!entries.length) return 'idle';
	    if (entries.some(x => x.state === 'unconfirmed')) return 'unconfirmed';
	    if (entries.some(x => x.state === 'pending')) return 'pending';
	    return 'verified';
	  };
	  window.__wildGardenCheckpoint = tracker;
	})();
	""")
	initialized = true

func track(path: String, content: String) -> void:
	if not OS.has_feature("web") or path.get_file() not in TRACKED: return
	if not initialized or not available: return
	var absolute := ProjectSettings.globalize_path(path)
	if not absolute.begins_with("/userfs/"):
		available = false
		return
	JavaScriptBridge.eval("window.__wildGardenCheckpoint.track(%s,%s)" % [JSON.stringify(absolute), JSON.stringify(content)])

func state() -> String:
	if not OS.has_feature("web"): return "native"
	if not initialized or not available: return "unconfirmed"
	var result: Variant = JavaScriptBridge.eval("window.__wildGardenCheckpoint ? window.__wildGardenCheckpoint.status() : 'unconfirmed'")
	return str(result) if result in ["idle", "pending", "verified", "unconfirmed"] else "unconfirmed"
