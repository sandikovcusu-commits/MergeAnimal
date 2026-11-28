# V0.8.1.3 — Web Audio compatibility (partial acceptance)

## Scope and implementation

Based on `4700dd78c2d1528c4b26cec94e20f0ee9d2a2e42`, preserving earlier font, Challenge export, touchcancel, resize, Remove, Rescue and Tutorial fixes. The 20 existing SFX WAVs and three existing music WAVs are byte-for-byte unchanged relative to that base. No new sound pack, gameplay mechanic, sprite, physics change or ad SDK was added.

Godot 4.7.2 Web's default sample playback reported active players but our two browser graph probes measured zero game signal. A diagnostic Firefox test forcing the same players to stream produced non-zero output ([45892593791](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45892593791)). `AudioManager` therefore selects `AudioServer.PLAYBACK_TYPE_STREAM` for its eight SFX players and single music player on Web only. Native playback selection is unchanged. Input unlock remains gesture gated. Theme changes reuse the same player. Existing impact threshold and cooldown remain.

`set_ad_audio_paused(bool)` is an idempotent integration hook, not an ad SDK: it pauses currently playing audio, rejects new one-shots while suspended, preserves settings and restores the prior player pause states. It also holds a theme change paused until resume. Integration with any real ad lifecycle is untested.

With Godot's global mouse-from-touch emulation disabled for gameplay, Settings sliders did not respond to simulated browser touch. They now track a single finger, preview drag and commit on release; canceled touch, browser focus loss or resize rolls back the preview. Mouse behavior and the existing DOM touchcancel workaround remain. Chromium tap and cancellation were tested; drag and physical device behavior are not established by these results.

## Actual CI evidence

Godot 4.7.2 release Web export, Playwright browser processes on Linux/Xvfb, software WebGL, PulseAudio null sink. These are real Chromium/Firefox WASM executions, not native or Android tests. `audio-web.mjs` injects a **test-only** probe into a separate export to inspect buses/player state and initiate fixtures; the shipped Web-Test ZIP is the uninstrumented production export. The browser graph tap and AudioWorklet measure samples independently of Godot's `playing` property. A calibration oscillator validates the tap, and an analyser is also used. `AudioContext` can be running while game output is silent; context state, player state and non-zero output are reported separately. Browser graph output is not proof of a physical speaker being audible.

| Run | Result | Coverage |
|---|---|---|
| [45896227797](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45896227797) | Chromium 47/47 | Instrumented desktop suite |
| [45896197633](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45896197633) | Firefox 47/47 | Instrumented desktop suite |
| [45896231926](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45896231926) | Chromium 48/48 | Instrumented simulated touch, including sliders and touchcancel |
| [45897295912](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45897295912) | Chromium 6/6 | Uninstrumented production export: pre-gesture silence, click, graph output, real UI mute/unmute, gameplay and captured errors |
| [45896968215](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45896968215) | Firefox 6/6 | Same production smoke |
| [45895377486](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45895377486) | Chromium 12/12 | Previous simulated touch regression after slider change |
| [45896964351](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45896964351) | success | Native Game Feel regression with dummy audio; not a browser audio or listening test |

The other ten native workflows on `0e7f7f2` also succeeded. Earlier Chromium runs [45895366528](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45895366528) and [45895373609](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45895373609) failed intermittent short analyser windows. A continuous audio-render-thread worklet addressed missed transients; failures are retained as history, not erased. An initial production Chromium attempt [45896964587](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45896964587) failed in dependency installation before export/test; retry above passed.

Instrumented checks observed pre-gesture zero output, user gesture unlock, non-zero graph output; Settings sliders and Master/Music/SFX bus values (for Chromium desktop 0.4/0.6/0.8), Master mute zero and unmute non-zero; save reload and complete browser-process close/reopen after a 10-second flush wait. They ran all 20 cues as isolated test-triggered resources with Music effectively at 0.0001 linear, and confirmed accepted event plus non-zero graph samples; this is **fixture-assisted**, not end-to-end natural gameplay for every cue. Real UI click and natural drop, landing and first matching merge dispatch were observed. The Forest, Sunset and Snow eight-second WAVs each output samples and had an observed playback-position wrap on the same singleton player. This does not prove a perceptually seamless loop or absence of every transient. Pool size eight and collision threshold/cooldown were checked. Ad hook, scene transition and in-game Pause/Resume passed. The browser console/page/request error assertion passed; routine software-WebGL performance warnings are in event logs.

Initial output RMS was approximately 0.034 in both browsers and zero while muted; the Chromium desktop graph measured about 0.0064 after the actual slider changes and unmute. These are sampled graph measurements, not calibrated loudness or a quality judgment. Web `Performance.MEMORY_STATIC` reported 0 in the probe; memory growth/leak, long-session performance, codec/mobile latency, and professional mixing have not been validated. The Chromium WebM is a graph-side recording (not a human listening verdict); Firefox's recorder MIME was empty and is not claimed usable.

## Open acceptance gaps

- CI attempted tab switch but produced `TAB_LIFECYCLE []`; actual blur/hidden, OS interruption, return audio and real tab-switch behavior are **not tested**. Real Android/iOS, Firefox touch and real audio hardware also remain untested.
- Full natural end-to-end trigger paths for collision, each merge size/combo/golden, discovery, achievement, challenge outcomes, undo/remove/rescue, Game Over/danger, menu back and theme unlock are not individually proven by the cue fixture. Restart/Continue/Game Over audio behavior was not independently verified here; earlier UI-navigation evidence is not an audio test.
- Save persistence after waiting is not a durability guarantee. IndexedDB sync is asynchronous; closing the page/process immediately can still lose the final write. No storage eviction or crash guarantee.
- No human listening or full quality, loudness, clipping, stereo/device or seamless-loop review. The instrumentation is test-only; graph measurements cannot substitute for listening. Not ready to claim complete release acceptance.

The requested evidence ZIP includes browser logs, transport checksums, screenshots, production export logs and the Chromium graph-side recording. CI links provide full run status. SHA-256 is supplied alongside packaged deliverables.
