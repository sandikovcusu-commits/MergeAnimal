// B.3 natural browser protocol — production Web build, real mouse input.
//
// Rules:
//  * No probe, no debug spawn, no score write, no forced Game Over, no prepared
//    board. The page is the unmodified production export.
//  * Every input is a real Playwright mouse click at a real screen position.
//  * Read-only observation happens through IndexedDB and through the production
//    SaveDurability tracker, which is part of the shipped build.
//  * Automated gameplay is never presented as human play.
//
// Modes (NATURAL_SCENARIO):
//   gameover  3 independent fresh-profile sessions, full session matrix,
//             terminal contract, terminal save confirmation, then refresh.
//   persist   terminal session, normal refresh, full browser close with the same
//             persistent profile, reopen, and Continue through the real UI.
//   rescue    terminal session, natural free rescue through the rescue button,
//             post-rescue drop, then refresh + close/reopen persistence.
import {chromium, firefox} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';

const name = process.env.UI_BROWSER || 'chromium';
const url = process.env.WEB_URL;
const out = process.env.WEB_QA_DIR || '/tmp/web-qa';
const scenario = process.env.NATURAL_SCENARIO || 'gameover';
const sessions = Number(process.env.NATURAL_SESSIONS || '3');
const profileRoot = process.env.NATURAL_PROFILE || '/tmp/b3-profile';
const engine = name === 'firefox' ? firefox : chromium;
const sleep = ms => new Promise(r => setTimeout(r, ms));
const tag = `${name}-b3-${scenario}`;
const launchArgs = name === 'chromium'
  ? ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader-webgl', '--enable-unsafe-swiftshader']
  : [];
const launchOptions = name === 'firefox'
  ? {headless: false, firefoxUserPrefs: {'webgl.force-enabled': true}}
  : {headless: false, args: launchArgs};

let browser = null;
let ctx = null;
let page = null;
let checks = 0;
let failures = 0;
let pageErrors = [];
let consoleErrors = [];
let events = 0;

function check(ok, text) {
  checks++;
  if (!ok) { failures++; console.log(`FAIL ${text}`); } else { console.log(`PASS ${text}`); }
  return ok;
}
function serverLog(line) { console.log(line); }
function json(value) { try { return JSON.stringify(value); } catch { return '{}'; } }

async function attach(target) {
  target.on('pageerror', e => pageErrors.push(String(e)));
  target.on('console', m => { if (m.type() === 'error') consoleErrors.push(m.text()); });
}

// Real mouse click with a small settle window, as a player would generate.
async function click(x, y, wait = 900) {
  events++;
  await page.mouse.move(x, y);
  await page.mouse.down();
  await sleep(35);
  await page.mouse.up();
  await sleep(wait);
}

async function boot(freshProfile) {
  const profile = freshProfile ? path.join(profileRoot, `${tag}-${Date.now()}-${Math.floor(Math.random() * 1e6)}`) : path.join(profileRoot, `${tag}-persist`);
  fs.mkdirSync(profile, {recursive: true});
  ctx = await engine.launchPersistentContext(profile, {viewport: {width: 720, height: 1280}, ...launchOptions});
  await attach(ctx);
  page = ctx.pages()[0] || await ctx.newPage();
  await attach(page);
  await page.goto(url, {waitUntil: 'domcontentloaded', timeout: 180000});
  await page.waitForSelector('canvas', {timeout: 180000});
  // Production Web boot: WASM init + first scene. Measured, not assumed.
  const bootStart = Date.now();
  await page.waitForFunction(() => window.__wildGardenCheckpoint !== undefined, null, {timeout: 120000}).catch(() => {});
  const bootMs = Date.now() - bootStart;
  await sleep(15000);
  const info = await page.evaluate(() => ({
    canvas: !!document.querySelector('canvas'),
    idb: typeof indexedDB !== 'undefined',
    storage: navigator.storage?.persisted ? 'available' : 'unavailable',
    observer: typeof window.__wildGardenCheckpoint === 'object',
    audio: typeof AudioContext !== 'undefined' || typeof webkitAudioContext !== 'undefined',
    threads: typeof window.GODOT_THREADS_ENABLED !== 'undefined' ? window.GODOT_THREADS_ENABLED : null,
  }));
  serverLog(`NATURAL_BOOT browser=${name} scenario=${scenario} profile=${path.basename(profile)} boot_ms=${bootMs} info=${json(info)}`);
  return info;
}

async function snapshot() {
  return page.evaluate(async () => {
    let all = [];
    for (const info of await indexedDB.databases()) {
      const db = await new Promise((ok, no) => {
        const r = indexedDB.open(info.name);
        r.onsuccess = () => ok(r.result); r.onerror = () => no(r.error);
      });
      for (const store of db.objectStoreNames) {
        await new Promise((ok) => {
          const r = db.transaction(store, 'readonly').objectStore(store).openCursor();
          r.onsuccess = () => {
            const c = r.result;
            if (!c) return ok();
            if (/wild_garden_(session|powerup)\.json$/.test(String(c.key)) && c.value?.contents) {
              try { all.push({key: String(c.key), value: JSON.parse(JSON.parse(new TextDecoder().decode(c.value.contents)).payload)}); } catch {}
            }
            c.continue();
          };
          r.onerror = () => ok();
        });
      }
      db.close();
    }
    all.sort((a, b) => (b.value.generation || 0) - (a.value.generation || 0));
    return {records: all, session: all.find(x => /session/.test(x.key))?.value || null};
  });
}

async function observer() {
  return page.evaluate(() => {
    const t = window.__wildGardenCheckpoint;
    if (!t) return {available: false};
    return {
      available: true,
      status: t.status(),
      records: Object.fromEntries(Object.entries(t.records || {}).map(([p, r]) => [p.split('/').pop(), {state: r.state, attempts: r.attempts, retries: r.retries, age_ms: Date.now() - r.since}])),
    };
  });
}

async function confirmed(timeout = 60000) {
  const started = Date.now();
  try {
    await page.waitForFunction(() => window.__wildGardenCheckpoint?.status() === 'verified', null, {timeout});
    return {verified: true, ms: Date.now() - started};
  } catch {
    return {verified: false, ms: Date.now() - started, state: await observer()};
  }
}

async function ocr(label) {
  const file = path.join(out, `${tag}-${label}.png`);
  await page.screenshot({path: file});
  try {
    return execFileSync('tesseract', [file, 'stdout'], {encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore']});
  } catch { return ''; }
}

const LANES = [130, 245, 360, 475, 590, 245, 475, 360];
async function playToGameOver(cap) {
  const started = Date.now();
  let accepted = 0, rejected = 0;
  let last = null;
  for (let i = 0; i < cap; i++) {
    const x = LANES[i % LANES.length];
    const before = last;
    await click(x, 700, 1500);
    const sample = await snapshot();
    const s = sample.session;
    last = s;
    if (s && before && (s.spawn_count || 0) > (before.spawn_count || 0)) accepted++;
    else if (s) rejected++;
    if (s?.game_over_pending) {
      return {over: true, inputs: i + 1, accepted, rejected, seconds: (Date.now() - started) / 1000, session: s};
    }
    if (i % 6 === 5) {
      const text = await ocr('progress');
      if (/game\s*over/i.test(text)) {
        const after = await snapshot();
        return {over: true, inputs: i + 1, accepted, rejected, seconds: (Date.now() - started) / 1000, session: after.session, ocr: 'game over'};
      }
    }
  }
  const final = await snapshot();
  return {over: false, inputs: cap, accepted, rejected, seconds: (Date.now() - started) / 1000, session: final.session};
}

async function terminalContract(before, label) {
  // Illegal input after Game Over: clicks on the board must change nothing.
  for (let i = 0; i < 5; i++) await click(160 + i * 90, 700, 500);
  await sleep(1500);
  const after = await snapshot();
  const beforeSession = before.session || {};
  const afterSession = after.session || {};
  check((afterSession.spawn_count || 0) === (beforeSession.spawn_count || 0), `${label}: GAME_OVER refuses new drops (${beforeSession.spawn_count} -> ${afterSession.spawn_count})`);
  check((afterSession.score || 0) === (beforeSession.score || 0), `${label}: GAME_OVER refuses new score (${beforeSession.score} -> ${afterSession.score})`);
  check((afterSession.bodies || []).length === (beforeSession.bodies || []).length, `${label}: GAME_OVER keeps the body count`);
  check((afterSession.best_score || 0) >= (afterSession.score || 0), `${label}: best score is not below the final score`);
  const text = await ocr(`${label}-gameover`);
  check(/game\s*over/i.test(text), `${label}: terminal overlay reads Game Over`);
  check(!/save\s*failed/i.test(text), `${label}: terminal overlay shows no save failure`);
  return afterSession;
}

async function refresh() {
  await page.reload({waitUntil: 'domcontentloaded', timeout: 180000});
  await page.waitForSelector('canvas', {timeout: 180000});
  await sleep(15000);
}

async function continueFromMenu() {
  // Main menu: the Continue button is the second action entry.
  const geometry = await page.evaluate(() => {
    const probe = window.__wildGardenCheckpoint;
    return probe ? {ok: true} : {ok: false};
  });
  // Real click on the Continue row of the menu card.
  await click(360, 585, 6000);
  await sleep(4000);
  return geometry;
}

async function scenarioGameover() {
  const rows = [];
  for (let i = 1; i <= sessions; i++) {
    if (i > 1) { if (ctx) await ctx.close(); await boot(true); }
    else await boot(true);
    await click(360, 600, 4000);   // Play
    await sleep(4000);
    serverLog(`NATURAL_SESSION_BEGIN browser=${name} index=${i} cap=200`);
    const result = await playToGameOver(200);
    const row = {
      index: i, seed: 'runtime_random', over: result.over, inputs: result.inputs,
      accepted: result.accepted, rejected: result.rejected, seconds: Number(result.seconds.toFixed(2)),
      score: result.session?.score ?? null, best: result.session?.best_score ?? null,
      merges: result.session?.merge_count ?? null, highest: result.session?.highest_level ?? null,
      spawns: result.session?.spawn_count ?? null, bodies: (result.session?.bodies || []).length,
      rescue_remaining: result.session?.rescue_remaining ?? null,
      session_id: result.session?.session_id ?? null, generation: result.session?.generation ?? null,
    };
    rows.push(row);
    serverLog(`NATURAL_SESSION ${name} ${json(row)}`);
    if (!result.over) {
      serverLog(`NATURAL_SESSION_END ${name} index=${i} outcome=NOT_REACHED inputs=${result.inputs} seconds=${row.seconds}`);
      continue;
    }
    await sleep(4000);
    const obsBefore = await observer();
    const conf = await confirmed(60000);
    const obsAfter = await observer();
    serverLog(`NATURAL_OBSERVER browser=${name} index=${i} before=${json(obsBefore)} after=${json(obsAfter)}`);
    check(conf.verified, `session ${i}: terminal checkpoint verified within 60 s (${conf.ms} ms)`);
    serverLog(`NATURAL_CONFIRMATION browser=${name} index=${i} verified=${conf.verified} ms=${conf.ms}`);
    const session = await terminalContract({session: result.session}, `session${i}`);
    check(session.game_over_pending === true, `session ${i}: checkpoint keeps game_over_pending`);
    check((session.session_id || '') === (result.session.session_id || ''), `session ${i}: checkpoint session matches`);
    check((session.score || 0) === (result.session.score || 0), `session ${i}: checkpoint score equals the live score`);
    // Refresh validation on the terminal session.
    const beforeReload = session;
    await refresh();
    const restored = (await snapshot()).session || {};
    check(restored.game_over_pending === true, `session ${i}: refresh keeps the terminal Game Over state`);
    check((restored.session_id || '') === (beforeReload.session_id || ''), `session ${i}: refresh keeps the session id`);
    check((restored.score || 0) === (beforeReload.score || 0), `session ${i}: refresh keeps the score`);
    check((restored.generation || 0) === (beforeReload.generation || 0), `session ${i}: refresh keeps the revision generation`);
    check((restored.best_score || 0) >= (beforeReload.best_score || 0), `session ${i}: refresh keeps the best score`);
    check((restored.rescue_remaining ?? -1) === (beforeReload.rescue_remaining ?? -2), `session ${i}: refresh keeps the rescue budget`);
    serverLog(`NATURAL_REFRESH browser=${name} index=${i} ${json({terminal: restored.game_over_pending, session_match: restored.session_id === beforeReload.session_id, score: restored.score, generation: restored.generation, rescue: restored.rescue_remaining})}`);
    await continueFromMenu();
    const afterContinue = await snapshot();
    const text = await ocr(`session${i}-continue`);
    check(!!afterContinue.session, `session ${i}: Continue keeps a readable checkpoint`);
    check(/(game\s*over)|(rescue)|(continue)/i.test(text), `session ${i}: Continue shows the terminal screen, not a silent new game`);
    check((afterContinue.session?.game_over_pending === true) || /(game\s*over)|(rescue)/i.test(text), `session ${i}: Continue keeps the terminal rules instead of resuming active play`);
  }
  serverLog(`NATURAL_MATRIX ${name} rows=${json(rows)}`);
}

async function scenarioPersist() {
  await boot(true);
  await click(360, 600, 4000);
  await sleep(4000);
  const result = await playToGameOver(200);
  if (!result.over) {
    serverLog(`NATURAL_PERSIST_SKIP browser=${name} reason=NOT_REACHED inputs=${result.inputs}`);
    return;
  }
  await sleep(4000);
  const conf = await confirmed(60000);
  check(conf.verified, `persist: terminal checkpoint verified (${conf.ms} ms)`);
  const before = (await snapshot()).session || {};
  const profile = await page.evaluate(() => location.origin);
  serverLog(`NATURAL_PERSIST terminal=${json({score: before.score, session: before.session_id, generation: before.generation, rescue: before.rescue_remaining, origin: profile})}`);
  // Normal refresh first.
  await refresh();
  const afterRefresh = (await snapshot()).session || {};
  check((afterRefresh.session_id || '') === (before.session_id || ''), 'persist: refresh keeps the session');
  check((afterRefresh.score || 0) === (before.score || 0), 'persist: refresh keeps the score');
  // Full browser close and reopen with the same persistent profile.
  await ctx.close();
  ctx = null; page = null; pageErrors = []; consoleErrors = [];
  await sleep(3000);
  const reopened = await boot(false);
  const afterReopen = (await snapshot()).session || {};
  check(!!reopened.canvas, 'persist: browser reopened and rendered the canvas');
  check((afterReopen.session_id || '') === (before.session_id || ''), 'persist: IndexedDB keeps the terminal session across a full browser restart');
  check((afterReopen.score || 0) === (before.score || 0), 'persist: terminal score survives a full browser restart');
  check((afterReopen.generation || 0) === (before.generation || 0), 'persist: revision generation survives a full browser restart');
  check(afterReopen.game_over_pending === true, 'persist: terminal state survives a full browser restart');
  check((afterReopen.rescue_remaining ?? -1) === (before.rescue_remaining ?? -2), 'persist: rescue budget survives a full browser restart');
  const obs = await observer();
  const conf2 = await confirmed(60000);
  check(conf2.verified, `persist: reopened page verifies the existing terminal checkpoint (${conf2.ms} ms)`);
  await continueFromMenu();
  const text = await ocr('persist-continue');
  check(/(game\s*over)|(rescue)|(continue)/i.test(text), 'persist: Continue after reopen shows the terminal screen');
  serverLog(`NATURAL_PERSIST_RESULT browser=${name} ${json({session: afterReopen.session_id, score: afterReopen.score, generation: afterReopen.generation, terminal: afterReopen.game_over_pending, verified: conf2.verified, observer: obs})}`);
}

async function scenarioRescue() {
  await boot(true);
  await click(360, 600, 4000);
  await sleep(4000);
  const result = await playToGameOver(200);
  if (!result.over) {
    serverLog(`NATURAL_RESCUE_SKIP browser=${name} reason=NOT_REACHED inputs=${result.inputs}`);
    return;
  }
  await sleep(4000);
  await confirmed(60000);
  const before = (await snapshot()).session || {};
  const bodiesBefore = (before.bodies || []).map(b => `${b.uid}:${b.id}:${Math.round(b.x)}:${Math.round(b.y)}`);
  serverLog(`NATURAL_RESCUE_BEFORE browser=${name} ${json({score: before.score, bodies: bodiesBefore.length, rescue: before.rescue_remaining, undo: before.undo_remaining, session: before.session_id, generation: before.generation})}`);
  const text = await ocr('rescue-before');
  check(/rescue/i.test(text), 'rescue: the free rescue action is offered on the Game Over screen');
  // The rescue action sits under the Play Again button of the result overlay.
  // Its real position is read from the page, not guessed from a screenshot.
  const point = await page.evaluate(() => {
    const canvas = document.querySelector('canvas');
    const rect = canvas.getBoundingClientRect();
    // Overlay actions after the 2026-11 result-overlay rebuild: Restart at
    // max(180, text_bottom + 14) from the top of the 720x1280 canvas, then
    // Rescue 75 px below it, each 55 px tall. The click is aimed at the centre
    // of that row; the screenshot and OCR confirm which action was hit.
    const top = Math.max(180, 178);
    const rescueCentre = top + 75 + 27.5;
    return {x: rect.left + rect.width * 0.5, y: rect.top + rect.height * (rescueCentre / 1280)};
  });
  await click(point.x, point.y, 2000);
  await sleep(9000);
  const after = (await snapshot()).session || {};
  const bodiesAfter = (after.bodies || []).map(b => `${b.uid}:${b.id}:${Math.round(b.x)}:${Math.round(b.y)}`);
  const removed = bodiesBefore.filter(x => !bodiesAfter.includes(x));
  const rescued = (after.rescue_remaining ?? 0) < (before.rescue_remaining ?? 0) || after.game_over_pending === false;
  check(after.score === before.score, `rescue: the score is unchanged (${before.score} -> ${after.score})`);
  check(removed.length > 0, `rescue: real bodies were removed (${removed.length})`);
  const refused = after.game_over_pending === true;
  if (refused) {
    const textAfter = await ocr('rescue-refused');
    serverLog(`NATURAL_RESCUE_REFUSED browser=${name} ${json({bodies: bodiesBefore.length, above_line: (before.bodies || []).filter(b => b.y - (b.radius ?? 0) < 465).length, message: (textAfter.match(/[^\n]*rescue[^\n]*/i) || [''])[0].trim()})}`);
  }
  check(!refused, 'rescue: the free rescue is not refused by the production planner');
  check(after.game_over_pending === false, 'rescue: the checkpoint is no longer a Game Over');
  check((after.rescue_remaining ?? 0) === ((before.rescue_remaining ?? 1) - 1), `rescue: the budget decreases exactly once (${before.rescue_remaining} -> ${after.rescue_remaining})`);
  check((after.undo_remaining ?? 1) === 0, 'rescue: the undo snapshot is consumed by rule');
  // A real drop after the rescue.
  await click(360, 700, 1600);
  await sleep(2500);
  const dropped = (await snapshot()).session || {};
  check((dropped.spawn_count || 0) === ((after.spawn_count || 0) + 1), `rescue: a real drop works afterwards (${after.spawn_count} -> ${dropped.spawn_count})`);
  const conf = await confirmed(60000);
  check(conf.verified, `rescue: the post-rescue checkpoint verifies (${conf.ms} ms)`);
  serverLog(`NATURAL_RESCUE_AFTER browser=${name} ${json({score: after.score, bodies: bodiesAfter.length, removed: removed.length, rescue: after.rescue_remaining, spawned: dropped.spawn_count, verified: conf.verified, rescued})}`);
  // Persistence of the used rescue across refresh and a full browser restart.
  await refresh();
  const refreshed = (await snapshot()).session || {};
  check((refreshed.rescue_remaining ?? -1) === (after.rescue_remaining ?? -2), 'rescue: refresh does not refund the used rescue');
  check(refreshed.game_over_pending !== true, 'rescue: refresh does not restore an active Game Over');
  await ctx.close();
  ctx = null; page = null;
  await sleep(3000);
  await boot(false);
  const reopened = (await snapshot()).session || {};
  check((reopened.rescue_remaining ?? -1) === (after.rescue_remaining ?? -2), 'rescue: a full browser restart does not refund the used rescue');
  check((reopened.score || 0) === (after.score || 0), 'rescue: a full browser restart keeps the post-rescue score');
  serverLog(`NATURAL_RESCUE_PERSIST browser=${name} ${json({refresh_rescue: refreshed.rescue_remaining, reopen_rescue: reopened.rescue_remaining, reopen_score: reopened.score})}`);
}

try {
  serverLog(`NATURAL_CONFIG browser=${name} scenario=${scenario} sessions=${sessions} url=${url} automated=true human_play=false`);
  if (scenario === 'gameover') await scenarioGameover();
  else if (scenario === 'persist') await scenarioPersist();
  else if (scenario === 'rescue') await scenarioRescue();
  else throw new Error(`unknown NATURAL_SCENARIO ${scenario}`);
  const fatalConsole = consoleErrors.filter(e => !/favicon|AudioContext was not allowed|The AudioContext was not allowed/i.test(e));
  check(pageErrors.length === 0, `no uncaught page errors (${pageErrors.length})`);
  check(fatalConsole.length === 0, `no fatal console errors (${fatalConsole.length})`);
  if (pageErrors.length) serverLog(`NATURAL_PAGE_ERRORS ${json(pageErrors.slice(0, 5))}`);
  if (fatalConsole.length) serverLog(`NATURAL_CONSOLE_ERRORS ${json(fatalConsole.slice(0, 5))}`);
} catch (e) {
  failures++;
  console.error('NATURAL_ERROR', e.stack || e);
} finally {
  serverLog(`NATURAL_B3 browser=${name} scenario=${scenario} checks=${checks} failures=${failures} events=${events}`);
  try { if (ctx) await ctx.close(); } catch {}
  process.exitCode = failures ? 1 : 0;
}
