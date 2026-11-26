// Release Web build only. Browser interactions are real mouse/touch events;
// screenshots and OCR are evidence, not a complete visual accessibility audit.
import {chromium,firefox} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
const out=process.env.WEB_QA_DIR||'/tmp/web-ui';const base=process.env.WEB_URL||'http://127.0.0.1:8765/';
const mode=process.env.UI_MODE||'screens',browser=process.env.UI_BROWSER||'chromium';
fs.mkdirSync(out,{recursive:true});let errors=0,checks=0;
function check(ok,label){checks++;console.log(`${ok?'PASS':'FAIL'} ${label}`);if(!ok)errors++;}
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const flags=browser==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']:[];
const engine=browser==='chromium'?chromium:firefox;
let context,page;const events=[];
function bind(p){p.on('console',m=>events.push({type:'console:'+m.type(),text:m.text()}));p.on('pageerror',e=>events.push({type:'pageerror',text:String(e)}));p.on('requestfailed',r=>events.push({type:'requestfailed',text:r.url()+' '+r.failure()?.errorText}));p.on('response',r=>{if(r.status()>=400)events.push({type:'http_error',text:r.url()+' '+r.status()})});}
async function launch(touch=false){context=await engine.launchPersistentContext(path.join(out,`${browser}-${mode}-profile`),{headless:false,viewport:touch?{width:393,height:873}:{width:720,height:1280},...(touch?{hasTouch:true,isMobile:true,deviceScaleFactor:1}:{}),args:flags,firefoxUserPrefs:{'webgl.force-enabled':true,'webgl.disabled':false}});page=context.pages()[0]||await context.newPage();bind(page);await page.goto(base,{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(15000)}
function point(x,y){let {width:w,height:h}=page.viewportSize();let s=Math.min(w/720,h/1280);return {x:(w-720*s)/2+x*s,y:(h-1280*s)/2+y*s}}
async function tap(x,y,touch=false){let p=point(x,y);if(touch)await page.touchscreen.tap(p.x,p.y);else await page.mouse.click(p.x,p.y)}
async function shot(label){let file=path.join(out,`${browser}-${mode}-${label}.png`);await page.screenshot({path:file});let text='';try{text=execFileSync('tesseract',[file,'stdout','--psm','11'],{encoding:'utf8',timeout:30000,stdio:['ignore','pipe','ignore']})}catch(e){console.log('OCR_UNAVAILABLE',String(e))}fs.writeFileSync(file+'.txt',text);console.log(`OCR ${label} ${JSON.stringify(text.replace(/\s+/g,' ').trim())}`);return text.toLowerCase()}
async function reset(){await page.goto(base,{waitUntil:'domcontentloaded',timeout:120000});await sleep(12000)}
async function state(){return await page.evaluate(async()=>{let out=[];for(const info of await indexedDB.databases()){let db=await new Promise((res,rej)=>{let r=indexedDB.open(info.name);r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});for(const n of db.objectStoreNames){let tx=db.transaction(n,'readonly');await new Promise((res,rej)=>{let r=tx.objectStore(n).openCursor();r.onsuccess=()=>{let c=r.result;if(!c)return res();if(/wild_garden_(session|powerup)\.json(\.bak)?$/.test(String(c.key))&&c.value?.contents){try{let e=JSON.parse(new TextDecoder().decode(c.value.contents));out.push(JSON.parse(e.payload))}catch{}}c.continue()};r.onerror=()=>rej(r.error)})}db.close()}return out.sort((a,b)=>(b.generation||0)-(a.generation||0))[0]||null})}
async function waitState(predicate,what,limit=30000){let s;let t=Date.now();while(Date.now()-t<limit){s=await state();if(s&&predicate(s))return s;await sleep(800)}throw Error(`${what}: ${JSON.stringify(s)}`)}
async function screens(){
 const menu=await shot('menu');check(menu.includes('play')&&menu.includes('collection'),`${browser} menu visible (OCR)`);
 for(const [name,y,pattern] of [['collection',766,/discovered|collection/],['statistics',837,/statistics|total games/],['achievements',907,/achievements|locked/],['themes',978,/themes|forest/],['challenges',1045,/challenges|friend/],['settings',1123,/settings|volume/]]){
  await tap(360,y);await sleep(3500);const text=await shot(name);check(pattern.test(text),`${browser} ${name} opened via menu (OCR)`);await reset();
 }
 await tap(360,600);await sleep(3500);let t=await shot('tutorial');check(/drag|skip/.test(t),`${browser} Play opens tutorial`);await tap(565,275);await sleep(700);await tap(360,700);await sleep(5000);await shot('gameplay');
 await tap(600,58);await sleep(2500);t=await shot('pause');check(/resume|pause/.test(t),`${browser} Pause opens`);
}
async function matrix(){
 let viewports=[[360,640],[393,873],[540,1170],[720,1280],[1366,768],[1920,1080]];
 for(let [w,h] of viewports){await page.setViewportSize({width:w,height:h});await sleep(2500);
  let info=await page.evaluate(()=>({width:innerWidth,height:innerHeight,scrollWidth:document.documentElement.scrollWidth,scrollHeight:document.documentElement.scrollHeight,canvas:(()=>{let c=document.querySelector('canvas'),r=c.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,backWidth:c.width,backHeight:c.height}})()}));console.log(`LAYOUT ${w}x${h} ${JSON.stringify(info)}`);
  check(info.width===w&&info.height===h&&info.scrollWidth<=w&&info.scrollHeight<=h&&info.canvas.width>0&&info.canvas.height>0,`${browser} ${w}x${h} canvas visible, no DOM overflow`);await shot(`${w}x${h}-menu`);
 }
 await page.setViewportSize({width:720,height:1280});await sleep(2000);await tap(360,600);await sleep(3500);await tap(565,275);await sleep(1000);
 for(let [w,h] of viewports){await page.setViewportSize({width:w,height:h});await sleep(2500);await shot(`${w}x${h}-game`)}
}
async function touchTest(){
 if(browser!=='chromium')throw Error('CDP touch uses Chromium only');
 await page.evaluate(()=>{window.__touches=[];for(let k of ['touchstart','touchmove','touchend','touchcancel','pointercancel'])document.addEventListener(k,e=>window.__touches.push({type:k,count:e.touches?.length??null}),true)});
 await shot('menu');await tap(360,600,true);await sleep(4500);await shot('play-tapped');
 await tap(565,275,true);await sleep(1500);await tap(260,700,true);await sleep(6500);
 let s=await waitState(d=>d.active&&d.spawn_count>=1,'touch drop');check(s.spawn_count===1,`one touch creates exactly one drop`);console.log('TOUCH_FIRST',JSON.stringify({spawn_count:s.spawn_count,bodies:s.bodies}));await shot('first-drop');
 let old=s.spawn_count;await tap(600,58,true);await sleep(3000);await shot('pause');s=await state();check(s.spawn_count===old,'Pause UI touch does not create a drop');
 await tap(360,715,true);await sleep(2500);
 let cdp=await context.newCDPSession(page);let a=point(220,700),b=point(450,700);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:a.x,y:a.y,id:1}]});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:a.x,y:a.y,id:1},{x:b.x,y:b.y,id:2}]});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});await sleep(6000);s=await state();check(s.spawn_count===old,'multi-touch cancel does not drop');
 await tap(500,700,true);await sleep(6500);s=await waitState(d=>d.spawn_count===old+1,'post-cancel touch');check(s.spawn_count===old+1,'post-cancel touch creates one drop');await shot('post-cancel');
 console.log('TOUCH_EVENTS',JSON.stringify(await page.evaluate(()=>window.__touches)));
}
try{await launch(mode==='touch');if(mode==='screens')await screens();else if(mode==='matrix')await matrix();else if(mode==='touch')await touchTest();else throw Error('unknown mode');let bad=events.filter(e=>['pageerror','console:error','requestfailed','http_error'].includes(e.type));check(!bad.length,`${browser} ${mode} no observed console/page/network errors`)}catch(e){check(false,`${browser} ${mode}: ${e.stack||e}`);if(page)try{await shot('error')}catch{}}
finally{fs.writeFileSync(path.join(out,`${browser}-${mode}-events.json`),JSON.stringify(events,null,2));if(context)await context.close()}
console.log(`WEB_UI mode=${mode} browser=${browser} checks=${checks} failures=${errors}`);process.exitCode=errors?1:0;
