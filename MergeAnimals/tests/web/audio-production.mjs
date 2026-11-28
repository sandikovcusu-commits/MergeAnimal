// Test the uninstrumented release export, observing browser WebAudio only.
import {chromium,firefox} from 'playwright';
import fs from 'node:fs';import path from 'node:path';
const browser=process.env.UI_BROWSER||'chromium',base=process.env.WEB_URL,out=process.env.WEB_QA_DIR||'/tmp/web-qa';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));let checks=0,failures=0,context,page;const events=[];
function check(ok,label,detail=''){checks++;console.log(`${ok?'PASS':'FAIL'} ${label} ${detail}`);if(!ok)failures++}
async function mark(){return page.evaluate(()=>performance.now())}
async function metrics(t){return page.evaluate(t=>{let a=window.__samples.filter(x=>x.t>=t);return {samples:a.length,maxRms:Math.max(0,...a.map(x=>x.rms)),contexts:window.__contexts.map(x=>x.state),taps:window.__taps.length}},t)}
async function positive(timeout=12000){let t=await mark(),r;const deadline=Date.now()+timeout;do{await sleep(500);r=await metrics(t)}while(r.maxRms<0.00001&&Date.now()<deadline);return r}
try{
 const engine=browser==='chromium'?chromium:firefox;
 context=await engine.launchPersistentContext(path.join(out,`${browser}-audio-production-profile`),{headless:false,viewport:{width:360,height:640},...(browser==='chromium'?{ignoreDefaultArgs:['--mute-audio']}:{}),args:browser==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader','--autoplay-policy=document-user-activation-required']:[],firefoxUserPrefs:{'webgl.force-enabled':true,'webgl.disabled':false,'media.autoplay.default':1,'media.autoplay.block-webaudio':true}});
 await context.addInitScript(()=>{
  window.__contexts=[];window.__taps=[];window.__samples=[];const Original=window.AudioContext||window.webkitAudioContext;if(Original){const Wrap=new Proxy(Original,{construct(t,a){let c=Reflect.construct(t,a);window.__contexts.push(c);return c}});window.AudioContext=Wrap;window.webkitAudioContext=Wrap}
  const original=AudioNode.prototype.connect;AudioNode.prototype.connect=function(dest,...rest){let result=original.call(this,dest,...rest);if(dest===this.context.destination){try{let old=window.__taps.filter(t=>t.src===this);old.forEach(t=>{t.analyser.disconnect();t.sink.disconnect()});window.__taps=window.__taps.filter(t=>t.src!==this);let analyser=this.context.createAnalyser();analyser.fftSize=2048;let sink=this.context.createMediaStreamDestination();original.call(this,analyser);original.call(analyser,sink);window.__taps.push({src:this,analyser,sink})}catch(e){console.warn('production audio tap',String(e))}}return result};
  setInterval(()=>{for(const t of window.__taps){try{original.call(t.src,t.analyser)}catch{}let a=new Float32Array(t.analyser.fftSize);t.analyser.getFloatTimeDomainData(a);let sum=0;for(const x of a)sum+=x*x;window.__samples.push({t:performance.now(),rms:Math.sqrt(sum/a.length)})}if(window.__samples.length>20000)window.__samples.splice(0,5000)},20);
 });
 page=context.pages()[0]||await context.newPage();page.on('console',m=>events.push({type:'console:'+m.type(),text:m.text()}));page.on('pageerror',e=>events.push({type:'pageerror',text:String(e)}));page.on('requestfailed',r=>events.push({type:'requestfailed',text:r.url()+' '+r.failure()?.errorText}));await page.goto(base,{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(15000);
 let t=await mark();await sleep(1000);let before=await metrics(t);check(before.maxRms<0.00001,'production has no output before first gesture',JSON.stringify(before));
 await page.mouse.click(180,561.5);await sleep(1800);let after=await positive();check(after.contexts.includes('running')&&after.maxRms>0.00001,'production user gesture starts nonzero WebAudio output',JSON.stringify(after));await page.screenshot({path:path.join(out,`${browser}-audio-production-settings.png`)});
 await page.mouse.click(180,295);await sleep(1800);t=await mark();await sleep(1000);let muted=await metrics(t);check(muted.maxRms<0.0001,'production real Mute UI silences graph',JSON.stringify(muted));
 await page.mouse.click(180,295);await sleep(1200);let unmuted=await positive();check(unmuted.maxRms>0.00001,'production real Unmute UI restores graph',JSON.stringify(unmuted));
 await page.mouse.click(180,482.5);await sleep(1000);await page.mouse.click(180,300);await sleep(3500);await page.mouse.click(282.5,260);await sleep(1000);await page.mouse.click(180,350);await sleep(3500);let playing=await positive();check(playing.maxRms>0.00001,'production WebAudio output persists into gameplay',JSON.stringify(playing));await page.screenshot({path:path.join(out,`${browser}-audio-production-gameplay.png`)});
 const bad=events.filter(e=>['pageerror','console:error','requestfailed'].includes(e.type));check(bad.length===0,'production has no captured page/console/request errors',JSON.stringify(bad));
}catch(e){check(false,'production audio harness exception',String(e.stack||e));if(page)try{await page.screenshot({path:path.join(out,`${browser}-audio-production-error.png`)})}catch{}}
finally{fs.writeFileSync(path.join(out,`${browser}-audio-production-events.json`),JSON.stringify(events,null,2));if(context)await context.close()}
console.log(`WEB_AUDIO_PRODUCTION browser=${browser} checks=${checks} failures=${failures}`);process.exitCode=failures?1:0;
