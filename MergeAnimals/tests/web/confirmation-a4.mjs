// A.4 aggregate observer regression (SAVE-AGGREGATE-OBSERVER-005).
// QA-only terminal fixture. Asserts the scoped aggregate: session verified
// alone must NOT report verified while the power-up commit record is pending.
import {chromium,firefox} from 'playwright';import fs from 'node:fs';import path from 'node:path';
const name=process.env.UI_BROWSER||'chromium',engine=name==='firefox'?firefox:chromium,url=process.env.WEB_URL,out=process.env.WEB_QA_DIR||'/tmp/web-qa',sleep=ms=>new Promise(r=>setTimeout(r,ms));let browser,ctx,page,id=0,checks=0,failures=0,errors=[];
function check(v,label,data={}){checks++;console.log(`${v?'PASS':'FAIL'} ${label} ${JSON.stringify(data)}`);if(!v)failures++}
async function cmd(op){let n=++id;await page.evaluate(c=>{window.__verifyReply=null;window.__verifyCommand=c},{id:n,op});await page.waitForFunction(n=>window.__verifyReply?.id===n,n,{timeout:120000});let r=await page.evaluate(()=>window.__verifyReply);if(r.error)throw Error(r.error);return r}
async function info(){return page.evaluate(()=>{const t=window.__wildGardenCheckpoint;return {aggregate:t.status(),scoped:t.statusForFiles? t.statusForFiles(Object.keys(t.records)):null,records:Object.fromEntries(Object.entries(t.records).map(([p,r])=>[p,{id:r.id,state:r.state,since:r.since,attempts:r.attempts,retries:r.retries}]))}})}
async function recState(suffix){const inf=await info();return Object.entries(inf.records).find(([p])=>p.endsWith(suffix))?.[1]?.state||'missing'}
async function waitState(suffix,want,timeout=60000){const end=Date.now()+timeout;while(Date.now()<end){if(await recState(suffix)===want)return true;await sleep(400)}return false}
async function waitDetails(want,timeout=60000){const end=Date.now()+timeout;let r;while(Date.now()<end){r=await cmd('details');if(r.details.status===want)return r;await sleep(400)}return r}
async function blockReads(suffix){await page.evaluate(s=>{const orig=IDBObjectStore.prototype.get;window.__origGet=orig;IDBObjectStore.prototype.get=function(k,...a){if(String(k).endsWith(s))throw new DOMException('QA injected read denial','SecurityError');return orig.call(this,k,...a)};const t=window.__wildGardenCheckpoint,p=Object.keys(t.records).find(x=>x.endsWith(s));t.track(p,t.records[p].expected)},suffix)}
async function unblockReads(){await page.evaluate(()=>{IDBObjectStore.prototype.get=window.__origGet})}
try{browser=await engine.launch({headless:false,args:name==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']:[],firefoxUserPrefs:{'webgl.force-enabled':true}});ctx=await browser.newContext({viewport:{width:720,height:1280}});page=await ctx.newPage();page.on('pageerror',e=>errors.push(String(e)));await page.goto(url,{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(15000);
 let r=await cmd('setup');check(r.result===0,'fixture initial session saved',r.details);
 check(await waitState('wild_garden_session.json','verified'),'session record verified');
 check(await waitState('wild_garden_powerup.json','verified'),'power-up record verified');
 r=await waitDetails('verified');check(r.details.status==='verified'&&r.details.scoped==='verified'&&r.details.powerup_status==='verified','scoped aggregate verified only when both required files verify',r.details);
 // Power-up fault: session stays verified, aggregate must stay pending/unconfirmed.
 await blockReads('wild_garden_powerup.json');
 check(await waitState('wild_garden_powerup.json','unconfirmed',30000),'power-up read fault becomes unconfirmed');
 r=await cmd('details');check(r.details.readback==='verified'&&r.details.status!=='verified'&&r.details.powerup_status!=='verified','session verified with power-up pending is not reported verified',r.details);
 await unblockReads();
 r=await waitDetails('verified');check(r.details.status==='verified'&&r.details.powerup_status==='verified','aggregate recovers to verified after power-up fault clears',r.details);
 // Session fault: symmetric check.
 await blockReads('wild_garden_session.json');
 check(await waitState('wild_garden_session.json','unconfirmed',30000),'session read fault becomes unconfirmed');
 r=await cmd('details');check(r.details.status!=='verified','session pending is not reported verified',r.details);
 await unblockReads();
 r=await waitDetails('verified');check(r.details.status==='verified','aggregate recovers after session fault clears',r.details);
 // Stale revision: newest write wins; older revision never reported as current.
 await cmd('score_427');await cmd('score_587');r=await cmd('save');check(r.result===0,'newest snapshot written',r.details);
 r=await waitDetails('verified');check(r.details.verified_revision===r.details.written_revision&&r.details.written_revision===r.details.current_revision&&r.details.verified_score===587,'verified revision is the newest write, not a stale one',r.details);
 // Duplicate track of identical bytes: still verified, no error.
 await page.evaluate(()=>{const t=window.__wildGardenCheckpoint,p=Object.keys(t.records).find(x=>x.endsWith('wild_garden_session.json'));t.track(p,t.records[p].expected)});
 r=await waitDetails('verified');check(r.details.status==='verified','duplicate track of identical bytes stays verified',r.details);
 // Delayed transaction: writer lock must keep aggregate pending, then verify.
 await page.evaluate(async()=>{const db=await new Promise((ok,no)=>{const rq=indexedDB.open('/userfs');rq.onsuccess=()=>ok(rq.result);rq.onerror=()=>no(rq.error)});const tx=db.transaction('FILE_DATA','readwrite'),store=tx.objectStore('FILE_DATA'),end=performance.now()+6000;function pump(){if(performance.now()>=end)return;const q=store.get('/userfs');q.onsuccess=pump}pump();tx.oncomplete=()=>db.close();tx.onabort=()=>db.close()});
 r=await cmd('save');check(r.result===0,'write queued behind held IDB transaction',r.details);await sleep(2000);
 r=await cmd('details');check(r.details.status!=='verified','held writer lock keeps aggregate pending',r.details);
 r=await waitDetails('verified');check(r.details.status==='verified','aggregate verifies after writer lock releases',r.details);
 check(errors.length===0,'no uncaught browser errors',errors);
}catch(e){failures++;console.error('CONFIRM_A4_ERROR',e.stack||e)}finally{console.log(`CONFIRM_A4 browser=${name} checks=${checks} failures=${failures}`);fs.writeFileSync(path.join(out,`${name}-confirmation-a4.json`),JSON.stringify({checks,failures,errors},null,2));if(ctx)await ctx.close();if(browser)await browser.close();if(failures)process.exitCode=1}
