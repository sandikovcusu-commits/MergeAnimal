// Real exported game in browsers. Screenshot-based smoke only; no debug API,
// injected progression or fake ad results. All coordinates are in pixels at
// the 720x1280 viewport and require explicit visual review.
import { chromium, firefox } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
const base = process.env.WEB_URL || 'http://127.0.0.1:8765/';
const out = process.env.WEB_QA_DIR || '/tmp/web-qa';
fs.mkdirSync(out, {recursive:true});
let failures=0;
function ok(value, label) { console.log(`${value ? 'PASS' : 'FAIL'}: ${label}`); if (!value) failures++; }
for (const [name, engine] of [['chromium', chromium], ['firefox', firefox]]) {
  const profile = path.join(out, name + '-profile');
  const events = [];
  let context;
  try {
    context = await engine.launchPersistentContext(profile, {
      headless: false, viewport:{width:720,height:1280},
      args: name === 'chromium' ? ['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader'] : [],
      firefoxUserPrefs: {'webgl.force-enabled':true, 'webgl.disabled':false},
    });
    const page = context.pages()[0] || await context.newPage();
    page.on('console', msg => events.push({type:'console:'+msg.type(), text:msg.text()}));
    page.on('pageerror', error => events.push({type:'pageerror', text:String(error)}));
    page.on('requestfailed', req => events.push({type:'network', text:req.url()+' '+req.failure()?.errorText}));
    const start = Date.now();
    const response = await page.goto(base, {waitUntil:'domcontentloaded', timeout:120000});
    ok(response?.ok(), `${name} serves index.html over HTTP`);
    await page.waitForSelector('canvas', {timeout:120000});
    await page.waitForTimeout(20000);
    await page.screenshot({path:path.join(out, `${name}-menu.png`)});
    const dims = await page.locator('canvas').boundingBox();
    ok(!!dims && dims.width > 0 && dims.height > 0, `${name} creates a visible canvas (${JSON.stringify(dims)})`);
    console.log(`${name} first capture elapsed_ms=${Date.now()-start}`);
    // A real click, followed by a screenshot; until image inspection this is
    // a requested interaction, not evidence that New Game/merge/save passed.
    await page.mouse.click(360, 600); await page.waitForTimeout(7000);
    await page.screenshot({path:path.join(out, `${name}-after-play.png`)});
    const canvasInfo = await page.evaluate(() => {
      const c=document.querySelector('canvas');
      return {width:c?.width, height:c?.height, webgl2:!!c?.getContext('webgl2'),
        databases:typeof indexedDB.databases === 'function'};
    });
    console.log(`${name} canvas_info ${JSON.stringify(canvasInfo)}`);
    console.log(`${name} events ${JSON.stringify(events)}`);
    fs.writeFileSync(path.join(out, `${name}-events.json`), JSON.stringify(events,null,2));
    ok(!events.some(e=>e.type === 'pageerror' || e.type === 'network'), `${name} no page exceptions or network failures`);
  } catch (err) {
    ok(false, `${name} browser run completed: ${err.stack || err}`);
    fs.writeFileSync(path.join(out, `${name}-events.json`), JSON.stringify(events,null,2));
  } finally { if (context) await context.close(); }
}
console.log(`WEB_BROWSER_SMOKE failures=${failures}`);
process.exitCode = failures ? 1 : 0;
