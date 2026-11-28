V0.9.1-B.3 evidence directory
============================

Everything here was produced by the B.3 automated suites on the recorded runs.
Automated gameplay is never human play; no session in this directory is a
human-recorded session.

Files
-----
native-<run>.log          Raw "Godot runtime tests" log for the native suite, as
                          transported by the workflow (NATIVE_EVIDENCE blob).
NATURAL_MATRIX_native.csv One row per natural session played by the native
                          suite: seed, input policy result, accepted and rejected
                          inputs, merges, cancelled merges, retries, score, best,
                          highest level, max bodies, max combo, danger metrics,
                          simulated and wall seconds, session id.

Protocol notes
--------------
* Every board state in a B.3 session is produced by real input events pushed
  through the production input path. No debug spawn, no direct animal creation,
  no score write, no forced Game Over, no forced merge, no forced rescue.
* The input policy is a fixed eight-lane cycle (130, 245, 360, 475, 590, 245,
  475, 360), rotated per session, at 1.25 s between inputs, with a 260 input
  guard. The guard is a maximum, not a target; when it is the reason a session
  did not end, the log prints NATURAL_NOT_REACHED with that reason.
* Danger is measured with the production rule (above the Danger Line AND
  settled AND physically supported), the same predicate DangerMonitor uses.
