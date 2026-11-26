// Real browser WASM test. 'real' uses the official remote SDK; 'blocked' aborts its URL.
import {chromium,firefox} from 'playwright';
import fs from 'node:fs';import path from 'node:path';
const browser=process.env.UI_BROWSER||'chromium',mode=process.env.SDK_CASE||'blocked',base=process.env.WEB_URL,out=process.env.WEB_QA_DIR||'/tmp/web-qa';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));let checks=0,failures=0;const messages=[];
function check(ok,label,detail=''){checks++;console.log(`${ok?'PASS':'FAIL'} ${label} ${detail}`);if(!ok)failures++}
let b;
try{
 b=await (browser==='chromium'?chromium:firefox).launch({headless:false,args:browser==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']:[],firefoxUserPrefs:{'webgl.force-enabled':true}});
 const context=await b.newContext({viewport:{width:360,height:640}}),page=await context.newPage();page.on('console',m=>messages.push({type:'console:'+m.type(),text:m.text()}));page.on('pageerror',e=>messages.push({type:'pageerror',text:String(e)}));
 if(mode==='blocked') await page.route('**/crazygames-sdk-v3.js',r=>r.abort('blockedbyclient'));
 await page.goto(base+(mode==='mute'?'?muteAudio=true':''),{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await page.waitForFunction(()=>window.__sdkProbe && window.__sdkProbe.sdk_state!=='initializing',{timeout:45000});await sleep(1500);
 let initial=await page.evaluate(()=>window.__sdkProbe);console.log('SDK_INITIAL',JSON.stringify(initial));
 check(mode!=='blocked'?(initial.sdk_state==='ready'&&initial.environment==='local'):initial.sdk_state==='unavailable',`${mode} SDK initialization`,JSON.stringify(initial));
 if(mode==='mute') check(initial.platform_muted&&initial.master_muted,'SDK platform mute applies to Master',JSON.stringify(initial));
 check(initial.provider==='local'&&initial.rewards_available===false,'ads unavailable without verified reward integration');
 await page.mouse.click(180,300);await sleep(4000);let game=await page.evaluate(()=>window.__sdkProbe);check(game.playing===true,'no-ads gameplay starts',JSON.stringify(game));
 await page.mouse.click(300,29);await sleep(1000);let paused=await page.evaluate(()=>window.__sdkProbe);check(paused.playing===false,'pause stops gameplay event',JSON.stringify(paused));
 await page.mouse.click(180,357);await sleep(1000);let resumed=await page.evaluate(()=>window.__sdkProbe);check(resumed.playing===true,'resume starts gameplay event',JSON.stringify(resumed));
 await page.screenshot({path:path.join(out,`${browser}-sdk-${mode}.png`)});
 if(mode!=='blocked') {const starts=messages.filter(e=>e.text.includes('Requesting gameplay start')).length,stops=messages.filter(e=>e.text.includes('Requesting gameplay stop')).length;check(starts===2&&stops===1,'official SDK receives start-stop-start once each',JSON.stringify({starts,stops}));}
 let errors=messages.filter(e=>e.type==='pageerror'||e.type==='console:error').filter(e=>mode!=='blocked'||!e.text.includes('ERR_BLOCKED_BY_CLIENT'));check(errors.length===0,'no unexpected captured browser errors',JSON.stringify(errors));
}catch(e){check(false,'SDK browser harness exception',String(e.stack||e))}finally{fs.writeFileSync(path.join(out,`${browser}-sdk-${mode}-events.json`),JSON.stringify(messages,null,2));if(b)await b.close()}
console.log(`SDK_SMOKE browser=${browser} case=${mode} checks=${checks} failures=${failures}`);process.exitCode=failures?1:0;
