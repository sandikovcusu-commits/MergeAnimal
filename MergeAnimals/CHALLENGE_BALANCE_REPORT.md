# V0.6.4.2-dev — Balance and completion evidence (WIP)

The per-level table and Godot run are in `CHALLENGE_REPORT.md`. This is deterministic solvability, not a statistically representative balance study or human difficulty certification. In 06–10 the harness selects `animals[4]` for every drop; real gameplay uses its ordinary random source. Thus their logged times/drop counts are **not** normal-spawn estimates. 01–05's independent fixture selects a fixed animal index as well. No body is removed or repositioned by these natural tests; 01 has its danger monitor disabled. Other legacy tests use reposition/cleanup and are not presented as balance evidence.

11–20 use resource-defined board/spawn and real physics. Spawn sequences loop. 11 starts raccoon and spawns raccoon; 12 koala/koala; 13 lion/lion; 14 empty/dog; 15 panda/panda; 16–17 empty/dog; 18 bear/bear; 19 lion/lion; 20 bear / bear,lion,lion,lion. Animals are not removed by the stage tests. Starter pieces do not increment target counts. Configured advanced objectives 11,12,15,18,19 complete with one aligned drop and 20 with four; **Expert does not mean demonstrated human challenge**. 20 fulfils actual Golden Merge but the user's requirement that it be difficult remains unverified and may not be satisfied. 17 x5 required 32 drops in this fixture and is physically achievable. No claims about ordinary player success rates or mobile skill balance are made.

Time limit 07 expired after 60 simulated seconds; pause stopped elapsed time; 16 success occurred before 90 seconds. In a distinct controlled queue test for 10, 20 real drops left score 28, a 21st was refused, and failure followed settling. In another intentionally high-tier, fixture-selected sequence, after 19 real drops the score was 41; drop 20 caused a real bear merge to score 261, with no early failure and success after settling. This edge case injects a test-selected animal outside 10's ordinary random queue to reliably exercise the rules; it is not the ordinary balance path. A blocked real spawn attempt left the count unchanged.

Future work: human playtests with ordinary queues, evidence across seeds/devices, tune challenge ramp and especially Golden Garden for satisfying difficulty while retaining real solvability; retest any tuning. Do not use these scripted times as claims about player experience.

---
## Historical balance report
# Challenge balance — NOT TESTED

The 20 requested challenge definitions, controlled boards, spawn sequences, scoring/drop/time limits, real completion and failure tests and balance report are not yet implemented. No claim of challenge completion or balance is made. Daily Challenge stays disabled until the prerequisite systems are complete and stable.
