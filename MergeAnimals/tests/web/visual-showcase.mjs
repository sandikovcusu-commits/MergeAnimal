// Uninstrumented single-threaded Web export. Automated real mouse clicks,
// not human play and not a seeded board. Playwright video has no audio track.
import {chromium} from 'playwright';
import fs from 'node:fs';import path from 'node:path';
const out=process.env.WEB_QA_DIR||'/tmp/web-qa', url=process.env.WEB_URL;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
fs.mkdirSync(out,{recursive:true});let browser,context,video;const errors=[];
async function session(page){return page.evaluate(async()=>{
 let matches=[];
 for(const info of await indexedDB.databases()){
  const db=await new Promise((resolve,reject)=>{let r=indexedDB.open(info.name);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});
  for(const store of db.objectStoreNames){
   await new Promise((resolve,reject)=>{let r=db.transaction(store,'readonly').objectStore(store).openCursor();r.onsuccess=()=>{let c=r.result;if(!c)return resolve();if(/wild_garden_session\.json$/.test(String(c.key))&&c.value?.contents){try{const envelope=JSON.parse(new TextDecoder().decode(c.value.contents));matches.push(JSON.parse(envelope.payload))}catch{}}c.continue()};r.onerror=()=>reject(r.error)});
  }db.close();
 }return matches.sort((a,b)=>(b.generation||0)-(a.generation||0))[0]||null;
})}
try{
 browser=await chromium.launch({headless:false,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']});
 context=await browser.newContext({viewport:{width:720,height:1280},recordVideo:{dir:out,size:{width:720,height:1280}}});
 const page=await context.newPage();video=page.video();page.on('pageerror',e=>errors.push(String(e)));
 await page.goto(url,{waitUntil:'domcontentloaded'});await page.waitForSelector('canvas');await sleep(16000);
 await page.mouse.click(360,600);await sleep(5000);await page.mouse.click(565,520);await sleep(1800);
 const start=Date.now(), positions=[360,360,290,430,235,485,335,390,265,455,310,415,200,520,340,380,250,470,300,420,360,360];
 for(const x of positions){await page.mouse.click(x,700);await sleep(3100)}
 const elapsed=(Date.now()-start)/1000, snapshot=await session(page);
 await page.screenshot({path:path.join(out,'visual-gameplay.png')});
 if(elapsed<60 || !snapshot || snapshot.spawn_count<1 || errors.length)throw Error(JSON.stringify({elapsed,snapshot,errors}));
 console.log('VISUAL_SHOWCASE',JSON.stringify({automation:'unseeded mouse',silent:true,gameplay_seconds:elapsed,spawn_count:snapshot.spawn_count,merges:snapshot.merge_count,score:snapshot.score,game_over_pending:snapshot.game_over_pending}));
 await context.close();context=null;await video.saveAs(path.join(out,'visual-gameplay.webm'));
}catch(e){console.error('VISUAL_SHOWCASE FAIL',e.stack||e);process.exitCode=1}finally{if(context)await context.close();if(browser)await browser.close()}
