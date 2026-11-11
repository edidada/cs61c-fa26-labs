const {chromium} = require('playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');
(async () => {
  fs.mkdirSync('output/playwright', {recursive:true});
  const browser = await chromium.launch({headless:true});
  const page = await browser.newPage({viewport:{width:1440,height:1000}});
  const result = {url:'https://venus.cs61c.org/', states:[]};
  try {
    await page.goto(result.url, {waitUntil:'networkidle',timeout:90000});
    await page.waitForFunction(() => typeof codeMirror !== 'undefined', {timeout:60000});
    await page.locator('#editor-tab').click();
    await page.locator('.CodeMirror').click();
    await page.keyboard.press('ControlOrMeta+A');
    await page.keyboard.insertText(fs.readFileSync('lab03/fib.s','utf8'));
    await page.locator('#simulator-tab').click();
    await page.locator('#simulator-assemble-simulator').click();
    const snapshot = async (name) => {
      const state = {name, sp:await page.locator('#reg-2-val').inputValue(),
        t0:await page.locator('#reg-5-val').inputValue(),t1:await page.locator('#reg-6-val').inputValue(),
        t3:await page.locator('#reg-28-val').inputValue(),
        rows:await page.locator('#program-listing-body tr').evaluateAll(rows => rows.map(r=>({text:r.innerText,html:r.outerHTML})))};
      result.states.push(state);
      return state;
    };
    const initial = await snapshot('initial');
    await page.screenshot({path:'output/playwright/lab03-initial.png',fullPage:true});
    await page.locator('#simulator-step').click();
    await snapshot('step-once');
    await page.locator('#simulator-undo').click();
    const undone = await snapshot('prev');
    assert.equal(undone.t0,initial.t0);
    assert.equal(undone.t1,initial.t1);
    await page.locator('#simulator-step').click();
    await page.locator('#simulator-step').click();
    await snapshot('t1-changed');
    await page.locator('#simulator-step').click();
    await page.locator('#simulator-step').click();
    await snapshot('la-completed');
    await page.locator('#memory-tab').click();
    await page.locator('#memMove').fill('0x10000000');
    await page.locator('#memMove').press('Enter');
    result.memory = await page.locator('#memory-table tbody tr').evaluateAll(rows=>rows.map(r=>({address:r.cells[0].innerText,bytes:[...r.querySelectorAll('input')].map(i=>i.value)})));
    const word = result.memory.find(r=>Number(r.address) === 0x10000000);
    assert.ok(word,'data memory row visible');
    assert.equal(parseInt(word.bytes.at(-1),16),12);
    await page.locator('#register-tab').click();
    await page.locator('#instruction-40 td').first().click();
    result.breakpoints=[];
    for(let i=0;i<7;i++) {
      await page.locator('#simulator-run').click();
      await page.waitForTimeout(100);
      await page.waitForFunction(()=>document.querySelector('#instruction-40').classList.contains('is-selected'));
      result.breakpoints.push(await snapshot('breakpoint-'+(i+1)));
    }
    assert.equal(Number(result.breakpoints[0].t0),1);
    assert.equal(Number(result.breakpoints[6].t0),13);
    await page.locator('#display-settings').selectOption({label:'Decimal'});
    const decimal=await page.locator('#reg-5-val').inputValue();
    assert.equal(decimal,'13');
    result.decimal=decimal;
    await page.screenshot({path:'output/playwright/lab03-breakpoint.png',fullPage:true});
    await page.locator('#display-settings').selectOption({label:'Hex'});
    await page.locator('#instruction-40 td').first().click();
    await page.locator('#simulator-run').click();
    await page.waitForFunction(() => document.querySelector('#console-output').value.includes('144'));
    result.output=await page.locator('#console-output').inputValue();
    assert.match(result.output,/144/);
    await snapshot('finished');
    await page.screenshot({path:'output/playwright/lab03-finished.png',fullPage:true});
    const answers = fs.readFileSync('lab03/ex2_answers.txt','utf8').trim().split('\n').map(s=>s.split('. ')[1].trim());
    const machine = pc => initial.rows.find(r=>Number(r.text.split('\t')[1])===pc).text.split('\t')[2];
    const computed = [machine(0), machine(0x34), initial.sp, result.states.find(s=>s.name==='t1-changed').t1,
      machine(8),result.states.find(s=>s.name==='la-completed').t3,'0x0c',result.breakpoints[0].t0,
      result.breakpoints[6].t0,result.decimal,result.output.trim()];
    assert.deepEqual(answers.map(Number),computed.map(Number));
    result.answers=computed;
    result.status='passed';
  } finally {
    fs.writeFileSync('test-results/browser.json',JSON.stringify(result,null,2));
    fs.writeFileSync('output/playwright/venus-dom.html',await page.content());
    await browser.close();
  }
})().catch(e=>{console.error(e);process.exit(1)});
