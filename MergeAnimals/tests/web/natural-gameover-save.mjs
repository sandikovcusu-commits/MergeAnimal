// Real mouse input, no saved-board edits. natural-gameover uses production export;
// natural-observe uses the separately instrumented passive QA export.
// Automated gameplay, not human play. Stops only on visible Game Over or cap.
import {chromium,firefox} from 'playwright';import fs from 'node:fs';import path from 'node:path';import {execFileSync} from 'node:child_process';
const name=process.env.UI_BROWSER||'chromium', url=process.env.WEB_URL, out=process.env.WEB_QA_DIR||'/tmp/web-qa';
const engine=name==='firefox'?firefox:chromium,sleep=ms=>new Promise(r=>setTimeout(r,ms));let page,ctx,checks=0,errors=[],browser,seq=0;
async function passive(){if(process.env.UI_MODE!=='natural-observe')return null;const id=++seq;await page.evaluate(id=>{window.__qualityReply=null;window.__qualityCommand={id,op:'inspect'}},id);await page.waitForFunction(id=>window.__qualityReply?.id===id,id,{timeout:30000});const r=await page.evaluate(()=>window.__qualityReply);return {live:r.live,observer:r.observer,can_write:r.can_write,document_status:r.document.status,generation:r.document.data?.generation,checkpoint_score:r.document.data?.score};}
async function snapshot(){return page.evaluate(async()=>{let all=[];for(const info of await indexedDB.databases()){const db=await new Promise((ok,no)=>{let r=indexedDB.open(info.name);r.onsuccess=()=>ok(r.result);r.onerror=()=>no(r.error)});for(const store of db.objectStoreNames)await new Promise((ok,no)=>{let r=db.transaction(store,'readonly').objectStore(store).openCursor();r.onsuccess=()=>{let c=r.result;if(!c)return ok();if(/wild_garden_(session|powerup)\.json$/.test(String(c.key))&&c.value?.contents)try{all.push(JSON.parse(JSON.parse(new TextDecoder().decode(c.value.contents)).payload))}catch{}c.continue()};r.onerror=()=>no(r.error)});db.close()}return all.sort((a,b)=>(b.generation||0)-(a.generation||0))[0]||null})}
async function shot(label){let file=path.join(out,`${name}-natural-${label}.png`);await page.screenshot({path:file});return execFileSync('tesseract',[file,'stdout'],{encoding:'utf8',stdio:['ignore','pipe','ignore']})}
try{
 browser=await engine.launch({headless:false,args:name==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']:[],firefoxUserPrefs:{'webgl.force-enabled':true}});ctx=await browser.newContext({viewport:{width:720,height:1280}});page=await ctx.newPage();page.on('pageerror',e=>errors.push(String(e)));
 await page.goto(url,{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(16000);await page.mouse.click(360,600);await sleep(5000);await page.mouse.click(565,520);await sleep(1800);
 let found=false,s=null,ocr='';
 for(let i=0;i<120;i++){
  let x=[130,245,360,475,590,130,360,590][i%8];await page.mouse.click(x,700);await sleep(1700);
  if(i%5===4){s=await snapshot();console.log('NATURAL_PROGRESS',JSON.stringify({input:i+1,spawn:s?.spawn_count,merges:s?.merge_count,score:s?.score,pending:s?.game_over_pending,generation:s?.generation,passive:await passive()}));
   if(s?.game_over_pending)found=true;
   if(!found){ocr=await shot('latest');if(/game\s*over/i.test(ocr))found=true}
   if(found)break;
  }
 }
 await sleep(8000);s=await snapshot();ocr=await shot('gameover');console.log('NATURAL_GAMEOVER',JSON.stringify({found,snapshot:s,ocr,observer:await page.evaluate(()=>window.__wildGardenCheckpoint?.status())}));
 if(!found||!s?.game_over_pending||!/game\s*over/i.test(ocr)||/save failed/i.test(ocr))throw Error('natural Game Over not reached or checkpoint/status invalid');
 checks++;await page.waitForFunction(()=>window.__wildGardenCheckpoint?.status()==='verified',null,{timeout:60000});checks++;
 const session=s.session_id,generation=s.generation;await page.reload({waitUntil:'domcontentloaded',timeout:120000});await sleep(16000);let restored=await snapshot();if(!restored?.game_over_pending||restored.session_id!==session||restored.generation!==generation)throw Error('refresh checkpoint mismatch');checks++;
 await page.mouse.click(360,700);await sleep(7000);const continued=await shot('continue');console.log('NATURAL_CONTINUE_OCR',JSON.stringify(continued));if(!/game\s*over/i.test(continued))throw Error('Continue did not show Game Over');checks++;
 if(errors.length)throw Error('page errors '+JSON.stringify(errors));checks++;
 console.log(`NATURAL_GAMEOVER browser=${name} checks=${checks} failures=0`);
}catch(e){console.error('NATURAL_GAMEOVER_ERROR',e.stack||e);console.log(`NATURAL_GAMEOVER browser=${name} checks=${checks} failures=1`);process.exitCode=1}
finally{if(ctx)await ctx.close();if(browser)await browser.close()}
