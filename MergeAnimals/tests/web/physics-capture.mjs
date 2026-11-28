// Private CI capture from an instrumented build. Inputs are normal gameplay;
// the probe only draws the existing debug collision outlines.
import {chromium} from 'playwright';import fs from 'node:fs';import path from 'node:path';
const out=process.env.WEB_QA_DIR||'/tmp/web-qa', url=process.env.WEB_URL, sleep=ms=>new Promise(r=>setTimeout(r,ms));
let browser,ctx,page,video;const errors=[];
try{
 browser=await chromium.launch({headless:false,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']});
 ctx=await browser.newContext({viewport:{width:720,height:1280},recordVideo:{dir:out,size:{width:720,height:1280}}});page=await ctx.newPage();video=page.video();
 page.on('pageerror',e=>errors.push(String(e)));await page.goto(url,{waitUntil:'domcontentloaded'});await page.waitForSelector('canvas');await sleep(16000);
 await page.mouse.click(360,600);await sleep(5000);await page.evaluate(()=>window.__enablePhysicsOutlines=true);await page.waitForFunction(()=>window.__physicsOutlinesEnabled===true,{timeout:20000});
 await page.mouse.click(565,520);await sleep(1500);
 for(const x of [360,360,310,390,260,440]){await page.mouse.click(x,700);await sleep(3800)}
 await page.screenshot({path:path.join(out,'collision-debug-natural-play.png')});await sleep(2500);
 if(errors.length)throw Error(JSON.stringify(errors));
 await ctx.close();ctx=null;await video.saveAs(path.join(out,'physics-gameplay.webm'));
 console.log('PHYSICS_CAPTURE PASS: real clicks, debug outlines; merges and visuals require independent inspection');
}catch(e){console.error('PHYSICS_CAPTURE FAIL',e.stack||e);process.exitCode=1}finally{if(ctx)await ctx.close();if(browser)await browser.close()}
