// Release Web build only. Browser interactions are real mouse/touch events;
// screenshots and OCR are evidence, not a complete visual accessibility audit.
import {chromium,firefox} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {execFileSync,spawnSync} from 'node:child_process';
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
 const menu=await shot('menu');check(menu.includes('best score')&&menu.includes('garden'),`${browser} menu visible (OCR)`);
 for(const [name,y,pattern,back] of [['collection',766,/discovered|collection/,1190],['statistics',837,/statistics|total games/,1190],['achievements',907,/achievements|locked/,1152],['themes',978,/themes|forest/,1138],['challenges',1045,/challenges|friend/,1118],['settings',1123,/settings|volume/,965]]){
  await tap(360,y);await sleep(3500);const text=await shot(name);check(pattern.test(text),`${browser} ${name} opened via menu (OCR)`);await tap(360,back);await sleep(2500);let returned=await shot(`${name}-back`);check(returned.includes('best score'),`${browser} ${name} Back returns to menu`);
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
async function localeTest(){
 const locale=process.env.UI_LOCALE||'en', locales=['en','az','tr','ru'];if(!locales.includes(locale))throw Error('unsupported locale');
 await tap(360,1123);await sleep(1500);await tap(360,805);await sleep(700);await shot('language-options');
 if(locale==='en'){await tap(160,856);await sleep(1800);await tap(360,805);await sleep(500)}
 await tap(160,833+23*locales.indexOf(locale));await sleep(4500);await shot('selected-language');
 const saved=await page.evaluate(async()=>{for(const info of await indexedDB.databases()){let db=await new Promise((res,rej)=>{let r=indexedDB.open(info.name);r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});for(const n of db.objectStoreNames){let result=await new Promise((res,rej)=>{let r=db.transaction(n).objectStore(n).openCursor();r.onsuccess=()=>{let c=r.result;if(!c)return res(null);if(String(c.key).endsWith('/wild_garden_settings.json'))return res(JSON.parse(JSON.parse(new TextDecoder().decode(c.value.contents)).payload));c.continue()};r.onerror=()=>rej(r.error)});if(result)return result}db.close()}return null});
 console.log('LOCALE_STATE',JSON.stringify(saved));check(saved?.language===locale,`settings persisted requested locale ${locale}`);if(saved?.language!==locale)throw Error('locale selection failed');
 await tap(360,965);await sleep(1200);
 const sizes=[[360,640],[393,873],[540,1170],[720,1280],[1366,768],[1920,1080]];
 const screens=[['menu',0,0],['collection',766,1190],['statistics',837,1190],['achievements',907,1152],['themes',978,1138],['challenges',1045,1118],['settings',1123,965]];
 for(const [name,y,back] of screens){await page.setViewportSize({width:720,height:1280});await sleep(700);if(y){await tap(360,y);await sleep(1400)}
 for(const [w,h] of sizes){await page.setViewportSize({width:w,height:h});await sleep(500);const file=path.join(out,`${browser}-${locale}-${name}-${w}x${h}.png`);await page.screenshot({path:file});console.log(`CAPTURE ${browser} ${locale} ${name} ${w}x${h} ${file}`)}
 await page.setViewportSize({width:720,height:1280});await sleep(700);if(back){await tap(360,back);await sleep(1200)}
 }
}
// Explicit isolated IDB fixture: cosmetic unlocks only, never claim natural unlock.
async function themeTest(){
 await tap(360,1123);await sleep(1000);await tap(360,805);await sleep(500);await tap(160,856);await sleep(4000);
 await context.close();
 const profile=path.join(out,`${browser}-${mode}-profile`);
 context=await engine.launchPersistentContext(profile,{headless:false,viewport:{width:720,height:1280},args:flags,firefoxUserPrefs:{'webgl.force-enabled':true,'webgl.disabled':false}});
 page=context.pages()[0]||await context.newPage();await page.route('**/__test_storage__',r=>r.fulfill({status:200,contentType:'text/html',body:'<!doctype html><title>isolated theme fixture</title>'}));await page.goto(new URL('__test_storage__',base).href);
 const data={version:1,selected:'forest',unlocked:['forest','sunset','snow']},payload=JSON.stringify(data),encoded=JSON.stringify({version:1,payload,checksum:crypto.createHash('sha256').update(payload).digest('hex')});
 let fixture=await page.evaluate(async encoded=>{for(const info of await indexedDB.databases()){let db=await new Promise((res,rej)=>{let r=indexedDB.open(info.name);r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});for(const n of db.objectStoreNames){let found=await new Promise((res,rej)=>{let r=db.transaction(n).objectStore(n).openCursor();r.onsuccess=()=>{let c=r.result;if(!c)return res(null);if(String(c.key).endsWith('/wild_garden_settings.json'))return res({key:String(c.key),value:c.value});c.continue()};r.onerror=()=>rej(r.error)});if(!found)continue;let key=found.key.replace('wild_garden_settings.json','wild_garden_themes.json');found.value.contents=new TextEncoder().encode(encoded);found.value.timestamp=new Date();await new Promise((res,rej)=>{let tx=db.transaction(n,'readwrite');tx.objectStore(n).put(found.value,key);tx.oncomplete=res;tx.onerror=()=>rej(tx.error)});db.close();return key}db.close()}return null},encoded);
 check(!!fixture,'isolated cosmetic unlock fixture installed');if(!fixture)throw Error('fixture target missing');console.log('THEME_FIXTURE',fixture,JSON.stringify(data));await context.close();await launch(false);
 // Restore English using actual UI (fixture setup changed language).
 await tap(360,1123);await sleep(1000);await tap(360,805);await sleep(500);await tap(160,833);await sleep(2000);await tap(360,965);await sleep(1000);
 for(const [theme,y] of [['sunset',580],['snow',860],['forest',300]]){
  await tap(360,978);await sleep(1600);await tap(420,y);await sleep(3500);await shot(`${theme}-selected`);
  const selected=await page.evaluate(async()=>{for(const info of await indexedDB.databases()){let db=await new Promise((res,rej)=>{let r=indexedDB.open(info.name);r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});for(const n of db.objectStoreNames){let result=await new Promise((res,rej)=>{let r=db.transaction(n).objectStore(n).openCursor();r.onsuccess=()=>{let c=r.result;if(!c)return res(null);if(String(c.key).endsWith('/wild_garden_themes.json'))return res(JSON.parse(JSON.parse(new TextDecoder().decode(c.value.contents)).payload));c.continue()};r.onerror=()=>rej(r.error)});if(result)return result}db.close()}return null});
  check(selected?.selected===theme,`apply ${theme} persists selected theme`);if(selected?.selected!==theme)throw Error('theme selection failed');await tap(360,1138);await sleep(1200);
  for(const [name,my,back] of [['menu',0,0],['collection',766,1190],['statistics',837,1190],['achievements',907,1152],['challenges',1045,1118],['settings',1123,965]]){
   if(my){await tap(360,my);await sleep(1100)}await page.screenshot({path:path.join(out,`${browser}-theme-${theme}-${name}.png`)});console.log(`CAPTURE theme=${theme} screen=${name} size=720x1280`);if(back){await tap(360,back);await sleep(1000)}
  }
  for(const [w,h] of [[360,640],[393,873],[540,1170],[720,1280],[1366,768],[1920,1080]]){await page.setViewportSize({width:w,height:h});await sleep(400);await page.screenshot({path:path.join(out,`${browser}-theme-${theme}-menu-${w}x${h}.png`)})}
  await page.setViewportSize({width:720,height:1280});await sleep(600);
 }
}
async function touchTest(){
 if(browser!=='chromium')throw Error('CDP touch uses Chromium only');
 await page.evaluate(()=>{window.__touches=[];for(let k of ['touchstart','touchmove','touchend','touchcancel','pointercancel'])document.addEventListener(k,e=>window.__touches.push({type:k,count:e.touches?.length??null}),true)});
 await shot('menu');
 await tap(360,766,true);await sleep(2000);await shot('collection-before-scroll');
 const scrollCdp=await context.newCDPSession(page), from=point(340,950),to=point(340,370);
 await scrollCdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:from.x,y:from.y,id:30}]});
 for(let i=1;i<=8;i++){await scrollCdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:from.x,y:from.y+(to.y-from.y)*i/8,id:30}]});await sleep(60)}
 await scrollCdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await sleep(2000);await shot('collection-after-scroll');
 const before=path.join(out,`${browser}-${mode}-collection-before-scroll.png`),after=path.join(out,`${browser}-${mode}-collection-after-scroll.png`);
 const cropBefore=path.join(out,'scroll-before-crop.png'),cropAfter=path.join(out,'scroll-after-crop.png');
 for(const [input,output] of [[before,cropBefore],[after,cropAfter]])execFileSync('convert',[input,'-crop','330x500+30+200','+repage',output]);
 const diff=spawnSync('compare',['-fuzz','15%','-metric','AE',cropBefore,cropAfter,'null:'],{encoding:'utf8'});const pixels=Number(diff.stderr.trim());console.log('SCROLL_CHANGED_PIXELS',pixels);
 check(Number.isFinite(pixels)&&pixels>5000,'Collection swipe changes substantial content, beyond button highlighting');await tap(360,1190,true);await sleep(1500);
 await tap(360,600,true);await sleep(4500);await shot('play-tapped');
 await tap(565,275,true);await sleep(1500);await tap(260,700,true);await sleep(6500);
 let s=await waitState(d=>d.active&&d.spawn_count>=1,'touch drop');check(s.spawn_count===1,`one touch creates exactly one drop`);console.log('TOUCH_FIRST',JSON.stringify({spawn_count:s.spawn_count,bodies:s.bodies}));await shot('first-drop');
 let old=s.spawn_count;await tap(600,58,true);await sleep(3000);await shot('pause');s=await state();check(s.spawn_count===old,'Pause UI touch does not create a drop');
 await tap(360,715,true);await sleep(2500);
 let cdp=await context.newCDPSession(page);let a=point(220,700),b=point(450,700);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:a.x,y:a.y,id:1}]});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:a.x,y:a.y,id:1},{x:b.x,y:b.y,id:2}]});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});await sleep(6000);s=await state();check(s.spawn_count===old,'multi-touch cancel does not drop');
 await tap(500,700,true);await sleep(6500);s=await waitState(d=>d.spawn_count===old+1,'post-cancel touch');check(s.spawn_count===old+1,'post-cancel touch creates one drop');await shot('post-cancel');
 old=s.spawn_count;
 let first=point(180,700),second=point(550,700);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:first.x,y:first.y,id:41}]});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:first.x,y:first.y,id:41},{x:second.x,y:second.y,id:42}]});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[{x:second.x,y:second.y,id:42}]});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await sleep(6500);s=await state();
 check(s.spawn_count===old+1,'two overlapping touches produce exactly one drop');await shot('multitouch-release');old=s.spawn_count;
 const hold=point(300,700);await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:hold.x,y:hold.y,id:4}]});
 await page.setViewportSize({width:540,height:1170});await sleep(1500);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await sleep(7000);s=await state();
 check(s.spawn_count===old,'resize during active touch does not produce a drop');await shot('after-resize-hold');
 await tap(360,238,true);await sleep(4500);s=await state();check(s.undo_remaining===0,'touch Undo spends one use');await shot('undo');
 let count=s.bodies.length, spawns=s.spawn_count;let target=s.bodies[0];await tap(175,238,true);await sleep(1000);
 let victim=point(target.x,target.y);await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:victim.x,y:victim.y,id:12}]});await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});await sleep(4000);s=await state();
 check(s.remove_remaining===1&&s.bodies.length===count&&s.spawn_count===spawns,'cancelled Remove selection does not spend use or delete animal');await shot('remove-cancel');
 if(s.remove_remaining===1){await tap(target.x,target.y,true);await sleep(5000);s=await state();}
 check(s.remove_remaining===0&&s.bodies.length===count-1&&s.spawn_count===spawns,'touch Remove and animal selection spend use without drop');await shot('remove');
 console.log('TOUCH_EVENTS',JSON.stringify(await page.evaluate(()=>window.__touches)));
}
// Unlock prerequisite challenges in an isolated profile, not an organic playthrough.
async function outcomesTest(){
 await tap(360,1123);await sleep(1000);await tap(360,805);await sleep(500);await tap(160,856);await sleep(4000);await context.close();
 const profile=path.join(out,`${browser}-${mode}-profile`);context=await engine.launchPersistentContext(profile,{headless:false,viewport:{width:720,height:1280},args:flags,firefoxUserPrefs:{'webgl.force-enabled':true,'webgl.disabled':false}});page=context.pages()[0]||await context.newPage();await page.route('**/__test_storage__',r=>r.fulfill({status:200,contentType:'text/html',body:'<!doctype html><title>challenge fixture</title>'}));await page.goto(new URL('__test_storage__',base).href);
 const data={version:2,entries:Array.from({length:20},(_,i)=>({completed:i<10,best:0,attempts:0,best_time:-1}))},payload=JSON.stringify(data),encoded=JSON.stringify({version:1,payload,checksum:crypto.createHash('sha256').update(payload).digest('hex')});
 let fixture=await page.evaluate(async encoded=>{for(const info of await indexedDB.databases()){let db=await new Promise((res,rej)=>{let r=indexedDB.open(info.name);r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});for(const n of db.objectStoreNames){let found=await new Promise((res,rej)=>{let r=db.transaction(n).objectStore(n).openCursor();r.onsuccess=()=>{let c=r.result;if(!c)return res(null);if(String(c.key).endsWith('/wild_garden_settings.json'))return res({key:String(c.key),value:c.value});c.continue()};r.onerror=()=>rej(r.error)});if(!found)continue;let key=found.key.replace('wild_garden_settings.json','wild_garden_challenges.json');found.value.contents=new TextEncoder().encode(encoded);found.value.timestamp=new Date();await new Promise((res,rej)=>{let tx=db.transaction(n,'readwrite');tx.objectStore(n).put(found.value,key);tx.oncomplete=res;tx.onerror=()=>rej(tx.error)});db.close();return key}db.close()}return null},encoded);
 check(!!fixture,'isolated prerequisite completion fixture installed');if(!fixture)throw Error('fixture missing');console.log('CHALLENGE_FIXTURE',JSON.stringify(data));await context.close();await launch(false);
 await tap(360,1123);await sleep(1000);await tap(360,805);await sleep(400);await tap(160,833);await sleep(2000);await tap(360,965);await sleep(1000);
 await tap(360,1045);await sleep(1400);await page.mouse.move(350,750);await page.mouse.wheel(0,100);await sleep(1600);await shot('selection-scroll-seven');
 async function clickWord(label,filename){const f=path.join(out,`${browser}-${mode}-${filename}.png`);let tsv=execFileSync('tesseract',[f,'stdout','--psm','11','tsv'],{encoding:'utf8',stdio:['ignore','pipe','ignore']});let rows=tsv.trim().split('\n').slice(1).map(x=>x.split('\t'));let r=rows.find(x=>x[11]?.toLowerCase()===label.toLowerCase());if(!r)throw Error(`OCR word ${label} not found in ${filename}`);await page.mouse.click(Number(r[6])+Number(r[8])/2,Number(r[7])+Number(r[9])/2)}
 await clickWord('Quick','selection-scroll-seven');await sleep(4000);await shot('challenge-seven-start');
 let fail='';for(let i=0;i<12;i++){await sleep(15000);fail=await shot(`challenge-fail-wait-${i}`);if(fail.includes('challenge failed'))break}
 check(fail.includes('challenge failed'),'timed challenge reaches failed overlay without drops');if(!fail.includes('challenge failed'))throw Error('failure overlay not observed');
 await tap(360,865);await sleep(2500);await page.mouse.move(350,750);await page.mouse.wheel(0,220);await sleep(1600);await shot('selection-scroll-eleven');await clickWord('Koala','selection-scroll-eleven');await sleep(3500);await shot('challenge-eleven-start');
 await tap(360,700);await sleep(12000);let success=await shot('challenge-success');check(success.includes('challenge success'),'fixture-unlocked Challenge 11 reaches success via actual drop');
}
async function lifecycleTest(){
 if(browser!=='chromium')throw Error('CDP lifecycle uses Chromium only');
 await page.evaluate(()=>{window.__lifecycle=[];for(const event of ['visibilitychange','blur','focus']){const target=event==='visibilitychange'?document:window;target.addEventListener(event,()=>window.__lifecycle.push({event,hidden:document.hidden,focus:document.hasFocus(),time:Date.now()}),true)}});
 await tap(360,600,true);await sleep(3500);await tap(565,275,true);await sleep(1000);await tap(260,700,true);await sleep(6500);
 let s=await waitState(d=>d.active&&d.spawn_count===1,'lifecycle baseline');let old=s.spawn_count;
 const cdp=await context.newCDPSession(page), p=point(350,700);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:p.x,y:p.y,id:21}]});
 const second=await context.newPage();await second.goto('about:blank');await second.bringToFront();await sleep(1800);await page.bringToFront();await sleep(1200);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await sleep(5000);s=await state();await shot('tab-return');
 const observed=await page.evaluate(()=>window.__lifecycle);console.log('LIFECYCLE_EVENTS',JSON.stringify(observed));
 if(observed.some(e=>e.event==='blur'||(e.event==='visibilitychange'&&e.hidden)))check(s.spawn_count===old,'held touch across an observed tab loss does not drop');else console.log('SKIP tab switch: browser emitted no blur or hidden event');
 old=s.spawn_count;await second.close();
 const p2=point(220,700);await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:p2.x,y:p2.y,id:22}]});
 await page.evaluate(()=>{const el=document.createElement('input');el.id='qa-focus';document.body.appendChild(el);el.focus()});await sleep(700);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await sleep(5000);s=await state();console.log('FOCUS_EVENTS',JSON.stringify(await page.evaluate(()=>window.__lifecycle)));check(s.spawn_count===old,'held touch after DOM focus leaves canvas does not drop');await shot('focus-loss');
 await page.evaluate(()=>{document.querySelector('#qa-focus').remove();document.querySelector('canvas').focus()});
 // Request/exit fullscreen via a real user click on a temporary test-page button.
 await page.evaluate(()=>{let b=document.createElement('button');b.id='qa-fullscreen';b.textContent='QA fullscreen';Object.assign(b.style,{position:'fixed',zIndex:'99999',top:'0',left:'0'});b.onclick=()=>document.documentElement.requestFullscreen();document.body.appendChild(b)});
 await page.locator('#qa-fullscreen').click();await sleep(1500);check(await page.evaluate(()=>!!document.fullscreenElement),'fullscreen entered');await shot('fullscreen');
 await page.evaluate(()=>document.exitFullscreen());await sleep(1500);check(await page.evaluate(()=>!document.fullscreenElement),'fullscreen exited');await page.locator('#qa-fullscreen').evaluate(e=>e.remove());await shot('fullscreen-exit');
 s=await state();check(s.spawn_count===old,'fullscreen enter and exit do not drop');
}
try{await launch(mode==='touch'||mode==='lifecycle');if(mode==='screens')await screens();else if(mode==='matrix')await matrix();else if(mode==='touch')await touchTest();else if(mode==='locale')await localeTest();else if(mode==='theme')await themeTest();else if(mode==='lifecycle')await lifecycleTest();else if(mode==='outcomes')await outcomesTest();else throw Error('unknown mode');let bad=events.filter(e=>['pageerror','console:error','requestfailed','http_error'].includes(e.type));check(!bad.length,`${browser} ${mode} no observed console/page/network errors`)}catch(e){check(false,`${browser} ${mode}: ${e.stack||e}`);if(page)try{await shot('error')}catch{}}
finally{fs.writeFileSync(path.join(out,`${browser}-${mode}-events.json`),JSON.stringify(events,null,2));if(context)await context.close()}
console.log(`WEB_UI mode=${mode} browser=${browser} checks=${checks} failures=${errors}`);process.exitCode=errors?1:0;
