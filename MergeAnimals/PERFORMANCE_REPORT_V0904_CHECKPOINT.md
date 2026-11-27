# V0.9.0.4 checkpoint — performance

Development targets are not measured guarantees. Chromium WebAssembly, 120 Hz, 360×640 software-rendered fixture, fixed body counts, merge disabled; 15 seconds, one repeat each. Baseline commit `5a50de4`, after `a72b511`; independent GitHub runners. Results are real observations, not controlled hardware comparison.

| Bodies | Before mean FPS / 1% low / median ms / p95 ms | After mean FPS / 1% low / median ms / p95 ms | Mean draw calls before / after |
|---:|---|---|---:|
| 10 | 59.80 / 44.82 / 16.7 / 16.7 | 37.45 / 29.91 / 33.3 / 33.4 | 62 / 62.4 |
| 20 | 50.62 / 29.94 / 16.7 / 33.4 | 56.48 / 29.94 / 16.7 / 33.3 | 62 / 62.64 |
| 40 | 50.15 / 29.94 / 16.7 / 33.4 | 35.62 / 22.45 / 33.3 / 33.4 | 62 / 62.86 |

10 and 40 samples differ by more than 5%. Investigation: single-repetition software renderer on different VMs, 20 moves in the opposite direction, and separate 3-repeat 10-body after run produced 52.35/60.00/60.00 FPS; these observations establish variability, not an explanation or absence of regression. Same-runner paired test was added and attempted; first 3 runs [46051119502](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46051119502), [46051123018](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46051123018), [46051126597](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46051126597) failed with exit 128 after after-samples, before baseline, so are not paired comparisons. Full baseline SHA fetch correction was made and runs retried; no definitive attribution without valid paired evidence and physical devices.

Baseline standard export total uncompressed 41,352,456 bytes, PCK 1,502,928, WASM 39,514,754; after current 42,001,248 bytes, PCK 2,151,720, WASM 39,514,754. PCK +648,792 bytes (~43.2%); total +648,792 (~1.57%). Earlier 43.11 MB is historical, not this baseline. ZIP network transfer/compression, texture memory, reliable node/particle counts, Reduced Effects comparison and actual physical mobile/Desktop performance were not established. Browser CPU aggregate can exceed 100%, RAM includes shared process mappings. `static_bytes` monitor was zero in these Web fixtures and is not a texture-memory measurement. Hardware/power/battery/thermal variance, 1% low stability and scene/gameplay behavior remain open.

## Same-runner sequential retry (three × 15 s, Chromium software renderer)

Current build measured first, then `5a50de4` baseline on the same runner; each count uses a separate runner. No alternating order or device controls, so warm-up/order and VM variance remain. Raw JSON: `docs/visual/v0904/performance/`; CI [10](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46051633901), [20](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46051637961), [40](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46051641367).

| Bodies | Before FPS, 3 repeats | After FPS, 3 repeats | Difference of means | Draw calls (before → after) |
|---:|---|---|---:|---|
| 10 | 44.77, 45.27, 45.40 | 40.62, 44.84, 45.15 | −3.6% | 62 → 62.4–62.7 |
| 20 | 59.94, 59.67, 59.80 | 56.01, 58.61, 58.74 | −3.4% | 62 → 62.7–63.5 |
| 40 | 45.63, 45.77, 45.88 | 34.90, 45.57, 46.14 | −7.8% | 62 → 64.0–64.3 |

The 40-body mean exceeds the 5% investigation threshold; first after repetition accounts for most of the difference, but the reason is not established. Intermittent extra draw calls are consistent with separate expression textures interrupting batching, but this is a hypothesis, not a causal measurement. Investigate alternating order, longer warm-up and an atlas/layer approach before claiming acceptance. 40-body p95 was 33.4 ms in all repeats; after median 33.3/16.7/16.7 ms. Cold-start after/before 10: 1492/1475 ms, 20: 1150/1168 ms, 40: 1537/1554 ms; these are software-runner observations, not user device launch times.
