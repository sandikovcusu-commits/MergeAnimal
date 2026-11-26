# V0.8.1.2 — Web QA summary

**Partial / not accepted.** See `WEB_UI_REPORT.md` and `MOBILE_TOUCH_REPORT.md` for precise coverage, browser-run links and omissions. Evidence includes actual browser screenshots, DOM event/console logs, layout metrics and failing intermediate runs; CI uses Linux/Playwright software rendering and simulated touch, not a physical Android device.

Production changes are limited to Web touch-cancellation handling and canceling held input on resize. No SDK, audio, sprite, gameplay mechanic or physics tuning was added. The final build is exported by Godot 4.7.2 at commit f16e908; documentation-only commits may follow. Screen checks were run on e3d9f13 and matrix checks on 2c4f8d7; those had identical UI layout but predate the resize fix. Touch checks were rerun after both changes.

Open acceptance work: all requested screens/states including Continue, Challenge success/failure and Game Over on this version; all languages and themes; visual inspection for every requested viewport and screen; scrolling, Rescue, Restart, focus/tab/fullscreen/orientation; Firefox touch and real Android hardware. Prior V0.8.1.1 browser tests do not constitute V0.8.1.2 acceptance. No commercial or release-readiness claim is made.
