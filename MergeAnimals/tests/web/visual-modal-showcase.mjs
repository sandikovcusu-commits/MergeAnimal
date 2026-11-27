// Private QA: actual release Web export, scripted mouse navigation, silent video.
// This is not a human playtest and does not demonstrate Game Over/Rescue.
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
const out=process.env.WEB_QA_DIR||'/tmp/web-qa',url=process.env.WEB_URL||'http://127.0.0.1:8765/';
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({headless:false,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']});
const context=await browser.newContext({viewport:{width:720,height:1280},recordVideo:{dir:out,size:{width:720,height:1280}}});
const page=await context.newPage();const video=page.video();let errors=[];
page.on('pageerror',e=>errors.push(String(e)));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
try {
 await page.goto(url,{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(16000);
 await page.mouse.click(360,1123);await sleep(3500);await page.screenshot({path:path.join(out,'modal-showcase-settings.png')});
 await page.mouse.click(150,605);await sleep(1800);await page.screenshot({path:path.join(out,'modal-showcase-mute-on.png')});await page.mouse.click(150,605);await sleep(1400);await page.screenshot({path:path.join(out,'modal-showcase-mute-off.png')});
 await page.mouse.click(360,805);await sleep(2500);await page.screenshot({path:path.join(out,'modal-showcase-language-popup.png')});
 await page.keyboard.press('Escape');await sleep(800);await page.mouse.click(360,965);await sleep(2500);
 await page.mouse.click(360,600);await sleep(6000);await page.mouse.click(565,520);await sleep(1200);
 await page.mouse.click(600,58);await sleep(3000);await page.screenshot({path:path.join(out,'modal-showcase-pause.png')});
 await page.mouse.click(360,840);await sleep(2500);await page.screenshot({path:path.join(out,'modal-showcase-pause-settings.png')});
 await page.mouse.click(360,965);await sleep(1200);await page.mouse.click(360,690);await sleep(2200);
 if(errors.length)throw Error('browser errors: '+JSON.stringify(errors));
 console.log('MODAL_SHOWCASE: scripted Web mouse; menu settings, toggle twice, language popup, gameplay pause/settings/resume; silent; no Game Over');
} finally {
 await context.close();const source=await video.path();fs.renameSync(source,path.join(out,'modal-showcase.webm'));await browser.close();
}
