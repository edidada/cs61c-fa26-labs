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
    await page.locator('#simulator-run').click();
    await page.waitForFunction(() => document.querySelector('#console-output').value.includes('144'));
    result.output=await page.locator('#console-output').inputValue();
    assert.match(result.output,/144/);
    await snapshot('finished');
    await page.screenshot({path:'output/playwright/lab03-finished.png',fullPage:true});
    result.status='passed';
  } finally {
    fs.writeFileSync('test-results/browser.json',JSON.stringify(result,null,2));
    fs.writeFileSync('output/playwright/venus-dom.html',await page.content());
    await browser.close();
  }
})().catch(e=>{console.error(e);process.exit(1)});
