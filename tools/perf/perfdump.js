const { chromium } = require('playwright');
const [,, url, dpr='2', extra='?perf=1'] = process.argv;
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ viewport: { width: 393, height: 852 }, deviceScaleFactor: Number(dpr), isMobile: true, hasTouch: true, locale: 'de-DE' });
  const page = await ctx.newPage();
  await page.addInitScript(() => { window.addEventListener('flutter-first-frame', () => { window.__ffMs = performance.now(); }); });
  await page.goto(url + extra, { waitUntil: 'load', timeout: 120000 });
  await page.waitForTimeout(9000);
  for (let i = 0; i < 4; i++) { await page.mouse.click(196, 806); await page.waitForTimeout(1200); }
  await page.waitForTimeout(6000);
  const p1 = await page.evaluate(() => ({ ff: window.__ffMs, perf: window.__ttPerf && JSON.parse(window.__ttPerf) }));
  await page.mouse.click(242, 687); await page.waitForTimeout(8000);
  const p2 = await page.evaluate(() => window.__ttPerf && JSON.parse(window.__ttPerf));
  await page.screenshot({ path: process.argv[5] || '/tmp/pw/hud.png' });
  console.log(JSON.stringify({ firstFrame: Math.round(p1.ff), bereit: p1.perf, laeuft: p2 }, null, 1));
  await browser.close();
})();
