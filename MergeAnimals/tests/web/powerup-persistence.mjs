// V0.8.1.1: real release PCK/WASM, browser input and isolated persistent
// profiles. No JS bridge to Godot, injected board, mocked physics or save writes.
import { chromium, firefox } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const base=process.env.WEB_URL || 'http://127.0.0.1:8765/';
const out=process.env.WEB_QA_DIR || '/tmp/web-qa';
const scenarios=(process.env.WEB_SCENARIOS || 'undo,remove,rescue,immediate').split(',');
const engines=(process.env.WEB_BROWSERS || 'chromium,firefox').split(',');
fs.mkdirSync(out,{recursive:true});
let failures=0, checks=0;
function check(v, label) { checks++; console.log(`${v?'PASS':'FAIL'} ${label}`); if(!v) failures++; }
function assert(v,label) { check(v,label); if(!v) throw new Error(label); }
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
function options(name) {return {headless:false,viewport:{width:720,height:1280},args:name==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']:[],firefoxUserPrefs:{'webgl.force-enabled':true,'webgl.disabled':false}};}
function attach(page,events,stage) {
 page.on('console',m=>events.push({stage,type:`console:${m.type()}`,text:m.text()}));
 page.on('pageerror',e=>events.push({stage,type:'pageerror',text:String(e)}));
 page.on('requestfailed',r=>events.push({stage,type:'requestfailed',text:`${r.url()} ${r.failure()?.errorText}`}));
 page.on('response',r=>{if(r.status()>=400)events.push({stage,type:'http_error',text:`${r.status()} ${r.url()}`});});
}
async function start(engine,name,profile,events,stage) {
 const ctx=await engine.launchPersistentContext(profile,options(name));
 const page=ctx.pages()[0]||await ctx.newPage(); attach(page,events,stage);
 const response=await page.goto(base,{waitUntil:'domcontentloaded',timeout:120000});
 assert(response?.ok(),`${name}/${stage} HTTP entry point`);
 await page.waitForSelector('canvas',{timeout:120000}); await delay(15000); return {ctx,page};
}
async function evidence(page,prefix,suffix) {await page.screenshot({path:path.join(out,`${prefix}-${suffix}.png`)});}
// Inspect only: read IDBFS entries as bytes. Never edit browser storage.
async function files(page) {
 return await page.evaluate(async()=>{
  if(!indexedDB.databases) throw Error('indexedDB.databases unavailable');
  const found={};
  for(const info of await indexedDB.databases()) {
   const db=await new Promise((resolve,reject)=>{const q=indexedDB.open(info.name);q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error)});
   for(const s of db.objectStoreNames) {
    const tx=db.transaction(s,'readonly'), store=tx.objectStore(s);
    await new Promise((resolve,reject)=>{const q=store.openCursor();q.onsuccess=()=>{const c=q.result;if(!c)return resolve(); const key=String(c.key); if(/wild_garden_(session|powerup)\.json(\.bak)?$/.test(key) && c.value?.contents)found[key.split('/').pop()]=new TextDecoder().decode(c.value.contents);c.continue()};q.onerror=()=>reject(q.error)});
   } db.close();
  } return found;
 });
}
async function documentState(page) {
 const f=await files(page), entries=[];
 for(const [name,text] of Object.entries(f)) {
  try {const e=JSON.parse(text);if(crypto.createHash('sha256').update(e.payload).digest('hex')!==e.checksum)throw Error('checksum');entries.push({name,data:JSON.parse(e.payload)});}
  catch(e){throw Error(`IDB ${name} invalid: ${e}`);}
 }
 entries.sort((a,b)=>(b.data.generation||0)-(a.data.generation||0));
 return {files:f,selected:entries[0]||null};
}
async function waitState(page, predicate, label, timeout=35000) {
 let last; const start=Date.now();
 while(Date.now()-start<timeout) {last=await documentState(page);if(last.selected&&predicate(last.selected.data))return last;await delay(750);}
 throw Error(`${label}: timed out; last=${JSON.stringify(last?.selected)}`);
}
function simple(d) {return {score:d.score,spawn_count:d.spawn_count,merge_count:d.merge_count,undo_remaining:d.undo_remaining,remove_remaining:d.remove_remaining,rescue_remaining:d.rescue_remaining,game_over_pending:d.game_over_pending,bodies:d.bodies?.map(x=>({id:x.id,uid:x.uid,x:Math.round(x.x),y:Math.round(x.y)}))};}
async function enterGame(page,prefix) {
 await page.mouse.click(360,600); await delay(3000); await page.mouse.click(565,275); await delay(1000);
 await page.mouse.click(360,700); await delay(4500); await page.mouse.click(360,700); await delay(7500);
 const saved=await waitState(page,d=>d.active && d.spawn_count===2 && d.merge_count>=1,'real tutorial drops/merge');
 await evidence(page,prefix,'merge');
 assert(saved.selected.data.score>0 && saved.selected.data.bodies.some(b=>b.id==='hamster'),`${prefix} two real tutorial drops physically merge`);
 return saved.selected.data;
}
function equalRestored(a,b) {
 return a.score===b.score && a.spawn_count===b.spawn_count && a.merge_count===b.merge_count &&
 a.undo_remaining===b.undo_remaining && a.remove_remaining===b.remove_remaining && a.rescue_remaining===b.rescue_remaining &&
 JSON.stringify(a.bodies.map(x=>[x.uid,x.id]).sort())===JSON.stringify(b.bodies.map(x=>[x.uid,x.id]).sort());
}
async function reloadContinue(page,prefix,before,stage) {
 const gen=before.generation; await page.reload({waitUntil:'domcontentloaded',timeout:120000});await delay(15000);
 await evidence(page,prefix,`${stage}-menu`); await page.mouse.click(360,690); await delay(7000);
 const state=await waitState(page,d=>d.active && d.generation>gen && equalRestored(d,before),`${prefix} ${stage} live continue`);
 assert(equalRestored(state.selected.data,before),`${prefix} ${stage} Continue autosaves restored score, bodies and limits`);
 await evidence(page,prefix,`${stage}-continue`); return state.selected.data;
}
async function run(name,engine,scenario) {
 const prefix=`${name}-${scenario}`, profile=path.join(out,`${prefix}-profile`), events=[];
 let ctx,page;
 try {
  ({ctx,page}=await start(engine,name,profile,events,`${scenario}-new`));
  let before=await enterGame(page,prefix);
  console.log(`${prefix} BEFORE ${JSON.stringify(simple(before))}`);
  if(scenario==='undo') {
   await page.mouse.click(360,238);
   before=(await waitState(page,d=>d.active&&d.undo_remaining===0,'undo commit')).selected.data;
   assert(before.score===0 && before.spawn_count===1 && before.merge_count===0 && before.bodies.length===1 && before.bodies[0].id==='mouse',`${prefix} undo restores pre-drop board and spends one use`);
  } else if(scenario==='remove') {
   const target=before.bodies.find(b=>b.id==='hamster');
   await page.mouse.click(175,238);await delay(600);await page.mouse.click(target.x,target.y);
   before=(await waitState(page,d=>d.active&&d.remove_remaining===0,'remove commit')).selected.data;
   assert(before.score>0 && before.bodies.length===0 && before.undo_remaining===1,`${prefix} remove consumes use and deletes target without changing score`);
  } else if(scenario==='rescue') {
   // Natural input-only attempts. No prepared board, no injected game over.
   let pending=null;
   for(let i=0;i<230;i++) {
    const x=[140,220,300,380,460,540,600][i%7];
    await page.mouse.click(x,700);await delay(700);
    if(i%8===7){const s=await documentState(page);if(s.selected?.data.game_over_pending){pending=s.selected.data;break;}console.log(`${prefix} drops_attempted=${i+1} state=${JSON.stringify(s.selected&&simple(s.selected.data))}`);}
   }
   if(!pending) {try{pending=(await waitState(page,d=>d.game_over_pending,'natural game over',15000)).selected.data;}catch{}}
   await evidence(page,prefix,'game-over-attempt');
   assert(!!pending,`${prefix} natural danger overflow produces persisted Game Over`);
   assert(pending.rescue_remaining===1,`${prefix} rescue initially available`);
   await page.mouse.click(360,792);
   before=(await waitState(page,d=>d.active&&!d.game_over_pending&&d.rescue_remaining===0,'rescue commit',45000)).selected.data;
   assert(before.score===pending.score && before.bodies.length<pending.bodies.length,`${prefix} Rescue spends one use, removes bodies and preserves score`);
  } else if(scenario==='immediate') {
   // Deliberately close immediately after input: no wait for deferred Godot
   // commit or IndexedDB acknowledgement. Outcome is observational, not PASS.
   await page.mouse.click(360,238); await ctx.close(); ctx=null;
   ({ctx,page}=await start(engine,name,profile,events,`${scenario}-immediate-reopen`));
   let state=await documentState(page);console.log(`${prefix} immediate close observation ${JSON.stringify(state.selected&&simple(state.selected.data))}`);
   await evidence(page,prefix,'immediate-reopen-menu');
   if(state.selected?.data?.active){await page.mouse.click(360,690);await delay(7000);await evidence(page,prefix,'immediate-reopen-continue');}
   fs.writeFileSync(path.join(out,`${prefix}-immediate-observation.json`),JSON.stringify(state,null,2));
   return;
  }
  await delay(5000); await evidence(page,prefix,'after-use');
  console.log(`${prefix} AFTER ${JSON.stringify(simple(before))}`);
  before=await reloadContinue(page,prefix,before,'refresh');
  await ctx.close();ctx=null;
  ({ctx,page}=await start(engine,name,profile,events,`${scenario}-reopen`));
  const disk=await waitState(page,d=>d.active&&equalRestored(d,before),`${prefix} reopened indexeddb`);
  assert(equalRestored(disk.selected.data,before),`${prefix} full browser close/reopen retains checkpoint`);
  await evidence(page,prefix,'reopen-menu');await page.mouse.click(360,690);await delay(7000);
  const restored=await waitState(page,d=>d.active&&d.generation>disk.selected.data.generation&&equalRestored(d,before),`${prefix} reopened Continue autosave`);
  assert(equalRestored(restored.selected.data,before),`${prefix} reopened Continue preserves score, animals and consumed limit`);
  await evidence(page,prefix,'reopen-continue');
  const final=await documentState(page);fs.writeFileSync(path.join(out,`${prefix}-final-idb.json`),JSON.stringify(final,null,2));
  const bad=events.filter(e=>['pageerror','requestfailed','http_error','console:error'].includes(e.type));
  check(bad.length===0,`${prefix} no captured console errors, page errors or failed requests`);
 } catch(e) {check(false,`${prefix} scenario completed: ${e.stack||e}`);if(page)try{await evidence(page,prefix,'failure')}catch{}}
 finally {if(ctx)await ctx.close();fs.writeFileSync(path.join(out,`${prefix}-events.json`),JSON.stringify(events,null,2));}
}
for(const name of engines) for(const scenario of scenarios) await run(name,name==='chromium'?chromium:firefox,scenario);
console.log(`WEB_POWERUP checks=${checks} failures=${failures}`);process.exitCode=failures?1:0;
