// Isolated instrumented build. Fault injections patch browser APIs only in
// this profile; they are not real quota, permissions, or OS failure tests.
import {chromium,firefox} from 'playwright';
import fs from 'node:fs'; import path from 'node:path';
const name=process.env.UI_BROWSER||'chromium', base=process.env.WEB_URL, out=process.env.WEB_QA_DIR||'/tmp/web-qa';
const engine=name==='chromium'?chromium:firefox, sleep=ms=>new Promise(r=>setTimeout(r,ms));
let ctx,page,id=0,checks=0,failures=0,events=[];
function check(ok,label,data=''){checks++;console.log(`${ok?'PASS':'FAIL'} ${label} ${typeof data==='string'?data:JSON.stringify(data)}`);if(!ok){failures++;throw Error(label)}}
async function start(suffix="main"){ctx=await engine.launchPersistentContext(path.join(out,`${name}-save-integrity-${suffix}-profile`),{headless:false,viewport:{width:360,height:640},args:name==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']:[],firefoxUserPrefs:{'webgl.force-enabled':true}});page=ctx.pages()[0]||await ctx.newPage();page.on('pageerror',e=>events.push(String(e)));await page.goto(base,{waitUntil:'domcontentloaded'});await page.waitForSelector('canvas',{timeout:120000});await page.waitForFunction(()=>!!window.__wildGardenCheckpoint,{timeout:120000});await sleep(8000)}
async function qa(op='read',extra={}){const command={id:++id,op,...extra};await page.evaluate(c=>window.__saveQACommand=c,command);await page.waitForFunction(id=>window.__saveQAResult?.id===id,command.id,{timeout:120000});return page.evaluate(()=>window.__saveQAResult)}
async function state(expected,timeout=50000){await page.waitForFunction(s=>window.__wildGardenCheckpoint?.status()===s,expected,{timeout});return page.evaluate(()=>window.__wildGardenCheckpoint.status())}
try{
 await start();
 let last=0;
 for(const count of [10,50,100]){
  const r=await qa('burst',{count});const g=r.result.generations;
  check(r.result.errors.every(x=>x===0)&&g.length===count,`burst ${count} synchronous save calls complete`);
  check(g.every((x,i)=>x===last+i+1),`burst ${count} generations strictly increase`,{first:g[0],last:g.at(-1)}); last=g.at(-1);
  await state('verified');check(true,`burst ${count} final exact IDB entries verified`);
 }
 let r=await qa('other_stores');check(r.result.every(x=>x===0),'fixture separate stores saved');await state('verified');
 r=await qa();check(r.document.data.generation===last && r.progress.best_score===599 && r.progress.animals.mouse.count===3 && r.progress.total_merges===7,'score collection statistics read before restart');
 check(r.settings.language==='az'&&Math.abs(r.settings.music-0.35)<0.001&&r.settings.mute,'language and audio settings before restart');
 check(r.challenges.data.entries[0].completed&&r.theme.data.selected==='sunset'&&r.achievements.data.entries.A01.unlocked,'challenge theme achievement before restart');
 await ctx.close();ctx=null;await start();r=await qa();
 check(r.document.data.generation===last&&r.progress.best_score===599&&r.progress.animals.mouse.count===3&&r.progress.total_merges===7,'confirmed latest checkpoint survives browser restart');
 check(r.settings.language==='az'&&Math.abs(r.settings.music-0.35)<0.001&&r.settings.mute&&r.challenges.data.entries[0].completed&&r.theme.data.selected==='sunset'&&r.achievements.data.entries.A01.unlocked,'separate fixture stores survive restart');
 r=await qa('local_failure');check(r.result!==0&&r.observer==='failed','injected local write failure is surfaced without blocking main loop');
 await qa('other_stores');await state('verified');check(true,'successful later write clears local failure');
 // Hold a real readwrite transaction open for a bounded interval. IDBFS
 // and the read-back must queue behind it, not claim an uncommitted revision.
 await page.evaluate(async()=>{
  const db=await new Promise((resolve,reject)=>{const q=indexedDB.open('/userfs');q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error)});
  const tx=db.transaction('FILE_DATA','readwrite'), store=tx.objectStore('FILE_DATA'), until=performance.now()+5000;
  const pump=()=>{if(performance.now()>=until)return;const q=store.get('/userfs');q.onsuccess=pump};pump();
  tx.oncomplete=()=>db.close();tx.onabort=()=>db.close();
 });
 await qa('burst',{count:1});await sleep(500);
 check((await page.evaluate(()=>window.__wildGardenCheckpoint.status()))==='pending','delayed write stays pending while transaction is held');
 await state('verified');check(true,'delayed transaction confirms only after release');
 // Force only read transactions to throw, after boot, on actual browser APIs.
 await page.evaluate(()=>{window.__origTx=IDBDatabase.prototype.transaction;IDBDatabase.prototype.transaction=function(s,m,...args){if(m==='readonly')throw new DOMException('injected read denial','SecurityError');return window.__origTx.call(this,s,m,...args)}});
 await qa('burst',{count:1});await state('unconfirmed');check(true,'injected IDB read denial never reports verified');
 await page.evaluate(()=>IDBDatabase.prototype.transaction=window.__origTx);await qa('burst',{count:1});await state('verified');check(true,'observer recovers after read access restored');
 // SecurityError is synthetic, not a real browser permission policy.
 await page.evaluate(()=>{window.__origOpen=indexedDB.open;indexedDB.open=function(){throw new DOMException('injected denial','SecurityError')}});
 await qa('burst',{count:1});await state('unconfirmed');check(true,'injected storage permission denial remains unconfirmed');
 await page.evaluate(()=>indexedDB.open=window.__origOpen);await qa('burst',{count:1});await state('verified');check(true,'confirmation resumes when injected denial removed');
 // Abort actual IDBFS readwrite transactions before they commit.
 await page.evaluate(()=>{window.__origTx=IDBDatabase.prototype.transaction;window.__aborts=0;IDBDatabase.prototype.transaction=function(s,m,...args){const tx=window.__origTx.call(this,s,m,...args);if(m==='readwrite'){window.__aborts++;queueMicrotask(()=>{try{tx.abort()}catch{}})}return tx}});
 await qa('burst',{count:1});await state('unconfirmed',45000);check((await page.evaluate(()=>window.__aborts))>0,'injected readwrite transaction abort never confirmed');
 await page.evaluate(()=>IDBDatabase.prototype.transaction=window.__origTx);
 let abortRecovery=false;
 for(let retry=0;retry<3&&!abortRecovery;retry++){
  await qa('burst',{count:1});
  try{await state('verified',20000);abortRecovery=true}catch{console.log('ABORT_RECOVERY_RETRY',retry,await page.evaluate(()=>window.__wildGardenCheckpoint.status()))}
 }
 checks++;if(abortRecovery)console.log('PASS later save confirmed after abort injection removed');else{failures++;console.log('FAIL later save not confirmed after abort injection removed')}

 r=await qa('corrupt_primary');check(r.result===true,'corrupt session primary fixture created');r=await qa();check(r.document.status==='recovered'&&r.document.data.generation>last,'power-up checkpoint recovers corrupt primary in running game');
 // Replay captured, checksum-valid older save bytes; do not fabricate data or
 // interpret versions which are not present in the archived evidence.
 await ctx.close();ctx=null;
 for(const version of ['v0.6.1','v0.7.0','v0.8.0','v0.9.0.2']){
  const fixture=JSON.parse(fs.readFileSync(new URL(`./fixtures/${version}-captured.json`,import.meta.url),'utf8'));
  await start(version);let seeded=await qa('seed_capture',{files:fixture.files});
  check(seeded.result.length===Object.keys(fixture.files).length,`${version} captured files staged`);
  const before=seeded.document;check(['ok','recovered'].includes(before.status),`${version} captured session accepted`,{generation:before.data?.generation,score:before.data?.score});
  // Observe every staged byte in IDBFS before closing, not just MEMFS.
  let matches=false;const deadline=Date.now()+45000;
  while(Date.now()<deadline&&!matches){
   matches=await page.evaluate(async files=>{const db=await new Promise((resolve,reject)=>{const q=indexedDB.open('/userfs');q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error)});try{const base='/userfs/godot/app_userdata/Merge Animals- Wild Garden/';const tx=db.transaction('FILE_DATA','readonly'),store=tx.objectStore('FILE_DATA');let ok=true;for(const [name,text] of Object.entries(files)){const entry=await new Promise((resolve,reject)=>{const q=store.get(base+name);q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error)});if(!entry||new TextDecoder().decode(entry.contents)!==text)ok=false}return ok}finally{db.close()}},fixture.files);
   if(!matches)await sleep(500);
  }
  check(matches,`${version} captured files committed to IndexedDB`);
  await ctx.close();ctx=null;await start(version);const after=await qa();
  check(['ok','recovered'].includes(after.document.status)&&after.document.data.generation===before.data.generation&&after.document.data.score===before.data.score&&JSON.stringify(after.document.data.bodies)===JSON.stringify(before.data.bodies),`${version} score board and generation survive restart`);
  check((await qa('continue')).result===true,`${version} Continue scene launched`);
  await sleep(1500);let migrated=await qa('save_live');
  for(let retry=0;retry<10&&migrated.result!==0;retry++){await sleep(1000);migrated=await qa('save_live')}
  check(migrated.result===0&&migrated.document.data.session_version===3&&migrated.document.data.score>=before.data.score,`${version} resumed and rewritten as current schema`,{result:migrated.result,old:before.data.session_version,new:migrated.document.data.session_version,oldScore:before.data.score,newScore:migrated.document.data.score});
  await state('verified');
  await ctx.close();ctx=null;
 }
 check(events.length===0,'no uncaught page errors',events);
}catch(e){console.error('SAVE_INTEGRITY_ERROR',e.stack||e);if(!failures)failures++}finally{if(ctx)await ctx.close();fs.writeFileSync(path.join(out,`${name}-save-integrity.json`),JSON.stringify({browser:name,checks,failures,events},null,2));console.log(`SAVE_INTEGRITY browser=${name} checks=${checks} failures=${failures}`);process.exitCode=failures?1:0}
