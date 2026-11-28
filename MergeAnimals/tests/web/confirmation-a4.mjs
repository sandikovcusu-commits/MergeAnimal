// A.4 aggregate observer regression (SAVE-AGGREGATE-OBSERVER-005).
// QA-only terminal fixture. The power-up record only exists after a real
// power-up checkpoint commit, so the fixture commits through the production
// path (power-up record first, then the session primary) instead of assuming
// an ordinary autosave creates it.
// Asserts: the scoped aggregate reports verified only when both required
// files verify; session verified alone (power-up pending/unconfirmed) must
// never be reported as verified.
import {chromium,firefox} from 'playwright';import fs from 'node:fs';import path from 'node:path';
const name=process.env.UI_BROWSER||'chromium',engine=name==='firefox'?firefox:chromium,url=process.env.WEB_URL,out=process.env.WEB_QA_DIR||'/tmp/web-qa',sleep=ms=>new Promise(r=>setTimeout(r,ms));let browser,ctx,page,id=0,checks=0,failures=0,errors=[];
function check(v,label,data={}){checks++;console.log(`${v?'PASS':'FAIL'} ${label} ${JSON.stringify(data)}`);if(!v)failures++}
async function cmd(op){let n=++id;await page.evaluate(c=>{window.__verifyReply=null;window.__verifyCommand=c},{id:n,op});await page.waitForFunction(n=>window.__verifyReply?.id===n,n,{timeout:120000});let r=await page.evaluate(()=>window.__verifyReply);if(r.error)throw Error(r.error);return r}
async function info(){return page.evaluate(()=>{const t=window.__wildGardenCheckpoint;return {aggregate:t.status(),records:Object.fromEntries(Object.entries(t.records).map(([p,r])=>[p,{id:r.id,state:r.state,since:r.since,attempts:r.attempts,retries:r.retries}]))}})}
function recPath(inf,suffix){return Object.keys(inf.records).find(p=>p.endsWith(suffix))}
async function recState(suffix){const inf=await info();const p=recPath(inf,suffix);return p?inf.records[p].state:'missing'}
async function waitState(suffix,want,timeout=60000){const end=Date.now()+timeout;while(Date.now()<end){if(await recState(suffix)===want)return true;await sleep(400)}return false}
async function waitDetails(want,timeout=60000){const end=Date.now()+timeout;let r;while(Date.now()<end){r=await cmd('details');if(r.details.status===want)return r;await sleep(400)}return r}
// Force the tracked record for one required file back into its read loop
// without touching the other file: the injected read denial is cleared and a
// fresh track of the same expected envelope restarts confirmation.
async function denyReads(suffix){return page.evaluate(s=>{const t=window.__wildGardenCheckpoint,p=Object.keys(t.records).find(x=>x.endsWith(s));if(!p)return false;const orig=IDBObjectStore.prototype.get;window.__origGet=window.__origGet||orig;IDBObjectStore.prototype.get=function(k,...a){if(String(k).endsWith(s))throw new DOMException('QA injected read denial','SecurityError');return orig.call(this,k,...a)};return true},suffix)}
async function allowReads(){await page.evaluate(()=>{if(window.__origGet)IDBObjectStore.prototype.get=window.__origGet})}
try{browser=await engine.launch({headless:false,args:name==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']:[],firefoxUserPrefs:{'webgl.force-enabled':true}});ctx=await browser.newContext({viewport:{width:720,height:1280}});page=await ctx.newPage();page.on('pageerror',e=>errors.push(String(e)));await page.goto(url,{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(15000);
 let r=await cmd('setup');check(r.result===0,'fixture initial session saved',r.details);
 check(await waitState('wild_garden_session.json','verified'),'session record verified');
 // Ordinary autosave writes only the session file: no power-up record exists
 // yet, and that must never be reported as a verified checkpoint commit.
 let inf=await info();
 check(!recPath(inf,'wild_garden_powerup.json'),'autosave did not create a power-up record',inf.records);
 r=await waitDetails('verified');check(r.details.status==='verified'&&r.details.requires_powerup===false,'session-only autosave verifies against its own required set',r.details);
 // Real power-up checkpoint commit: both required files must verify.
 r=await cmd('checkpoint_powerup');check(r.result===0,'power-up checkpoint commit written',r.details);
 check(await waitState('wild_garden_session.json','verified'),'session record verified after power-up commit');
 check(await waitState('wild_garden_powerup.json','verified'),'power-up record verified after power-up commit');
 r=await waitDetails('verified');check(r.details.status==='verified'&&r.details.scoped==='verified'&&r.details.powerup_status==='verified'&&r.details.requires_powerup===true&&r.details.powerup_generation>=0,'scoped aggregate verified only when both required files verify',r.details);
 // A required file with no tracked record can never confirm a commit.
 await page.evaluate(()=>{const t=window.__wildGardenCheckpoint,p=Object.keys(t.records).find(x=>x.endsWith('wild_garden_powerup.json'));delete t.records[p]});
 r=await cmd('details');check(r.details.status!=='verified'&&r.details.scoped!=='verified','untracked required power-up record is not reported verified',r.details);
 r=await cmd('checkpoint_powerup');check(r.result===0,'fresh power-up commit restores tracking',r.details);
 r=await waitDetails('verified');check(r.details.status==='verified','aggregate verifies again after a fresh power-up commit',r.details);
 // Power-up read fault: session stays verified, aggregate must not verify.
 check(await denyReads('wild_garden_powerup.json'),'power-up record present for fault injection');
 r=await cmd('checkpoint_powerup');check(r.result===0,'second power-up checkpoint written under read fault',r.details);
 let sawNonVerified=false;
 for(let i=0;i<40;i++){r=await cmd('details');if(r.details.status!=='verified'){sawNonVerified=true;check(r.details.readback==='verified'||r.details.status!=='verified','session verified with power-up pending is not reported verified',r.details);break}await sleep(250)}
 check(sawNonVerified,'power-up read fault kept the aggregate from verifying',{status:r.details.status,powerup:r.details.powerup_status});
 await allowReads();
 r=await waitDetails('verified');check(r.details.status==='verified'&&r.details.scoped==='verified'&&r.details.powerup_status==='verified','aggregate recovers after power-up fault clears',r.details);
 // Stale revision: the newest commit wins; older bytes never confirm it.
 await cmd('score_427');r=await cmd('checkpoint_powerup');check(r.result===0,'checkpoint at score 427',r.details);
 await cmd('score_587');r=await cmd('checkpoint_powerup');check(r.result===0,'checkpoint at score 587',r.details);
 r=await waitDetails('verified');check(r.details.verified_score===587&&r.details.verified_revision===r.details.written_revision&&r.details.written_revision===r.details.current_revision,'verified revision is the newest write, not a stale one',r.details);
 // Duplicate track of identical bytes: same envelope, still one verified state.
 const before=await info();await page.evaluate(()=>{const t=window.__wildGardenCheckpoint,p=Object.keys(t.records).find(x=>x.endsWith('wild_garden_session.json'));t.track(p,t.records[p].expected)});
 const after=await info();check(after.records[recPath(before,'wild_garden_session.json')].id>before.records[recPath(before,'wild_garden_session.json')].id,'duplicate track supersedes the older record',{before:before.records,after:after.records});
 r=await waitDetails('verified');check(r.details.status==='verified','duplicate track of identical bytes stays verified',r.details);
 // Delayed transaction: a held writer lock must keep the aggregate pending,
 // then verify after release (no timeout increase, no weakened assertion).
 await page.evaluate(async()=>{const db=await new Promise((ok,no)=>{const rq=indexedDB.open('/userfs');rq.onsuccess=()=>ok(rq.result);rq.onerror=()=>no(rq.error)});const tx=db.transaction('FILE_DATA','readwrite'),store=tx.objectStore('FILE_DATA'),end=performance.now()+6000;function pump(){if(performance.now()>=end)return;const q=store.get('/userfs');q.onsuccess=pump}pump();tx.oncomplete=()=>db.close();tx.onabort=()=>db.close()});
 r=await cmd('checkpoint_powerup');check(r.result===0,'write queued behind held IDB transaction',r.details);await sleep(2000);
 r=await cmd('details');check(r.details.status!=='verified','held writer lock keeps aggregate pending',r.details);
 r=await waitDetails('verified');check(r.details.status==='verified','aggregate verifies after writer lock releases',r.details);
 check(errors.length===0,'no uncaught browser errors',errors);
}catch(e){failures++;console.error('CONFIRM_A4_ERROR',e.stack||e)}finally{console.log(`CONFIRM_A4 browser=${name} checks=${checks} failures=${failures}`);fs.writeFileSync(path.join(out,`${name}-confirmation-a4.json`),JSON.stringify({checks,failures,errors},null,2));if(ctx)await ctx.close();if(browser)await browser.close();if(failures)process.exitCode=1}
