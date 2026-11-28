// Instrumented QA export; no probe is packaged in the production Web release.
import {chromium} from 'playwright';import fs from 'node:fs';import path from 'node:path';
const base=process.env.WEB_URL||'http://127.0.0.1:8765/',out=process.env.WEB_QA_DIR||'/tmp/web-qa';fs.mkdirSync(out,{recursive:true});
const sleep=ms=>new Promise(r=>setTimeout(r,ms)), sizes=[[360,640],[393,873],[540,1170],[1920,1080]], locales=['az','en','tr','ru'],themes=['forest','sunset','snow'];
let errors=[],records=[],seq=0;const browser=await chromium.launch({headless:false,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']});
const context=await browser.newContext({viewport:{width:720,height:1280}});const page=await context.newPage();
page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
async function cmd(payload){const id=++seq;await page.evaluate(x=>{window.__qualityReply=null;window.__qualityCommand=x},{...payload,id});await page.waitForFunction(id=>window.__qualityReply?.id===id,id,{timeout:45000});let r=await page.evaluate(()=>window.__qualityReply);if(r.error)throw Error(JSON.stringify(r));return r}
try{
 await page.goto(base,{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(15000);
 for(const locale of locales)for(let ti=0;ti<themes.length;ti++){
  const theme=themes[ti];let start=await cmd({op:'setup',locale,theme});if(start.locale!==locale||start.theme!==ti||start.bodies!==12)throw Error('wrong fixture '+JSON.stringify(start));
  for(const screen of ['gameplay','gameover']){
   let result=screen==='gameover'?await cmd({op:'gameover'}):start;
   if(screen==='gameover'&&(!result.game_over||!result.fits||!result.glyphs))throw Error('bad game-over geometry '+JSON.stringify(result));
   for(const [w,h] of sizes){
    await page.setViewportSize({width:w,height:h});await sleep(650);
    let canvas=await page.evaluate(()=>{let c=document.querySelector('canvas'),r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height,scrollWidth:document.documentElement.scrollWidth,scrollHeight:document.documentElement.scrollHeight}});
    if(canvas.w<=0||canvas.h<=0||canvas.scrollWidth>w||canvas.scrollHeight>h)throw Error('invalid canvas '+JSON.stringify(canvas));
    const file=`web-${screen}-${locale}-${theme}-${w}x${h}.png`;await page.screenshot({path:path.join(out,file)});
    const scale=Math.min(w/720,h/1280),touch=screen==='gameplay'?[start.pause_width*scale,start.pause_height*scale]:[result.action_width*scale,result.action_height*scale];
    let record={screen,locale,theme,width:w,height:h,canvas,touch_px:touch,geometry:result,file};records.push(record);console.log('WEB_MATRIX '+JSON.stringify(record));
   }
  }
 }
 if(errors.length)throw Error('browser errors '+JSON.stringify(errors));
 if(records.length!==96)throw Error(`wrong capture count ${records.length}`);
 console.log('PASS 96 web screenshots and limited geometry checks; no human visual approval');
}catch(e){console.error('FAIL '+e.stack);process.exitCode=1}
finally{fs.writeFileSync(path.join(out,'quality-matrix.json'),JSON.stringify({records,errors},null,2));await context.close();await browser.close()}
