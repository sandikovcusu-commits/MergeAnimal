// V0.9.1 QA-only instrumented build. Each case uses a separate ephemeral profile.
// No debug probe or forced fixture is shipped in the production PCK.
import {chromium, firefox} from 'playwright';
import fs from 'node:fs'; import path from 'node:path';
const name=process.env.UI_BROWSER||'chromium', base=process.env.WEB_URL, out=process.env.WEB_QA_DIR||'/tmp/web-qa';
const engine=name==='firefox'?firefox:chromium;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
let checks=0, failures=0, id=0, errors=[];
function check(ok,label,details={}) {checks++; console.log(`${ok?'PASS':'FAIL'} ${label} ${JSON.stringify(details)}`); if(!ok)throw Error(label)}
async function cmd(page,command){const n=++id; await page.evaluate(x=>{window.__qualityReply=null;window.__qualityCommand=x},{...command,id:n}); await page.waitForFunction(n=>window.__qualityReply?.id===n,n,{timeout:60000});return page.evaluate(()=>window.__qualityReply)}
const browser=await engine.launch({headless:false,args:name==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']:[],firefoxUserPrefs:{'webgl.force-enabled':true}});
try{
 for(const old of [true,false]){
  const kind=old?'old-invalid':'corrected';
  const context=await browser.newContext({viewport:{width:360,height:640}});const page=await context.newPage();page.on('pageerror',e=>errors.push(String(e)));
  try{
   await page.goto(base,{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(15000);
   let setup=await cmd(page,{op:'setup',locale:'en',theme:'forest'});check(setup.bodies===12,`${kind} twelve fixture bodies`,setup);
   const result=await cmd(page,{op:old?'gameover-invalid':'gameover'});
   console.log('GAMEOVER_RESULT '+JSON.stringify({kind,...result}));
   check(result.game_over && result.can_write,`${kind} Game Over and storage available`,{can_write:result.can_write});
   if(old){
    check(result.score===124 && result.best===0 && !result.valid && result.valid_with_best_fixed, 'old snapshot rejected solely by restoring score/best invariant', {score:result.score,best:result.best,valid:result.valid,repaired:result.valid_with_best_fixed});
    check(result.save_status!==0 && result.message==='Save failed','old fixture reproduces actual save failure',{save_status:result.save_status,message:result.message});
   }else{
    check(result.score===124 && result.best>=124 && result.valid && result.save_status===0 && result.message==='','corrected fixture checkpoint succeeds', {score:result.score,best:result.best,valid:result.valid,status:result.save_status,message:result.message});
    check(['ok','recovered'].includes(result.document.status) && result.document.data.game_over_pending===true && result.document.data.score===124 && result.document.data.session_id===result.session_id,'Game Over checkpoint includes score, session and pending state',result.document);
    await page.waitForFunction(()=>window.__wildGardenCheckpoint?.status()==='verified',null,{timeout:60000});
    let before=await cmd(page,{op:'inspect'});check(before.observer==='verified','exact tracked IndexedDB read-back verified',{observer:before.observer,generation:before.document.data.generation});
    await page.screenshot({path:path.join(out,`${name}-${kind}-gameover.png`)});
    await page.reload({waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(15000);
    let after=await cmd(page,{op:'inspect'});check(['ok','recovered'].includes(after.document.status) && after.document.data.game_over_pending && after.document.data.score===124 && after.document.data.session_id===result.session_id && after.document.data.generation===before.document.data.generation,'refresh restores same pending checkpoint',{status:after.document.status,generation:after.document.data?.generation,session:after.document.data?.session_id});
   }
   if(old)await page.screenshot({path:path.join(out,`${name}-${kind}-gameover.png`)});
  }finally{await context.close()}
 }
 check(errors.length===0,'no uncaught page errors',errors);
}catch(e){failures++;console.error('INVESTIGATION_ERROR',e.stack||e)}
finally{await browser.close();fs.writeFileSync(path.join(out,`${name}-gameover-investigation.json`),JSON.stringify({browser:name,checks,failures,errors},null,2));console.log(`GAMEOVER_INVESTIGATION browser=${name} checks=${checks} failures=${failures}`);process.exitCode=failures?1:0}
