// QA-only WebAssembly. Frozen dense board; MergeManager scheduler enabled.
// The merge must happen without any explicit re-request after blockers move.
import {chromium,firefox} from 'playwright';import fs from 'node:fs';import path from 'node:path';
const browserName=process.env.UI_BROWSER||'chromium',engine=browserName==='firefox'?firefox:chromium,url=process.env.WEB_URL,out=process.env.WEB_QA_DIR||'/tmp/web-qa';let browser,ctx,page,id=0,checks=0,failures=0,rows=[],errors=[];const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function check(v,label,obj={}){checks++;console.log(`${v?'PASS':'FAIL'} ${label} ${JSON.stringify(obj)}`);if(!v)failures++}
async function cmd(op){let n=++id;await page.evaluate(v=>{window.__verifyReply=null;window.__verifyCommand=v},{id:n,op});await page.waitForFunction(n=>window.__verifyReply?.id===n,n,{timeout:120000});let r=await page.evaluate(()=>window.__verifyReply);if(r.error)throw Error(r.error);return r}
try{browser=await engine.launch({headless:false,args:browserName==='chromium'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader-webgl','--enable-unsafe-swiftshader']:[],firefoxUserPrefs:{'webgl.force-enabled':true}});ctx=await browser.newContext({viewport:{width:720,height:1280}});page=await ctx.newPage();page.on('pageerror',e=>errors.push(String(e)));await page.goto(url,{waitUntil:'domcontentloaded',timeout:120000});await page.waitForSelector('canvas',{timeout:120000});await sleep(15000);
 let r=await cmd('contact_retry');console.log('CONTACT_RETRY_A4_MAIN',JSON.stringify(r));
 check(r.reserved===true,'dense pair reserves',r.cancelled);
 check(r.cancelled.failed===1&&r.cancelled.cancelled===1&&r.cancelled.attempts===0,'cancellation tracked, no retry yet',r.cancelled);
 check(r.static_state.attempts===0&&r.static_state.failed===1,'static blocker produces no automatic retry',r.static_state);
 check(r.merged===true&&r.final.merges===1&&r.final.score===4&&r.final.pending===0,'blocker movement triggers automatic retry without explicit re-request',r.final);
 check(r.final.retry.successes===1&&r.final.retry.attempts>=1&&r.final.retry.failed===0,'automatic retry reserved exactly once',r.final.retry);
 check(r.saved===0&&r.final.snapshot_empty===false,'save snapshot valid after automatic retry',r.final);
 r=await cmd('contact_retry_matrix');rows=r.rows;for(const x of rows)console.log('CONTACT_RETRY_A4_ROW',JSON.stringify(x));
 check(rows.length===30&&rows.every(x=>x.ok),'10 seeds per 10/20/40 synthetic bodies preserve invariants',{cases:rows.length,cancelled:rows.reduce((a,x)=>a+x.cancelled,0),auto_successes:rows.reduce((a,x)=>a+x.successes,0),max_ms:Math.max(...rows.map(x=>x.pending_ms))});
 check(errors.length===0,'no page errors',errors);
}catch(e){failures++;console.error('CONTACT_RETRY_A4_ERROR',e.stack||e)}finally{fs.writeFileSync(path.join(out,`${browserName}-contact-retry-a4.json`),JSON.stringify({rows,checks,failures,errors},null,2));console.log(`CONTACT_RETRY_A4 browser=${browserName} checks=${checks} failures=${failures} cases=${rows.length}`);if(ctx)await ctx.close();if(browser)await browser.close();if(failures)process.exitCode=1}
