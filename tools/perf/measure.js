// Misst eine Flutter-Web-Seite im Headless-Chromium (Software-WebGL!). Relativer Vergleich, kein iPhone-Ersatz.
// Aufruf: node tools/perf/measure.js <URL> <Label> [cpuDrosselung=1] [dpr=2] [Sekunden=12] [URL-Anhang]
// Voraussetzung: `npm i playwright` (Chromium). Die App muss am Ende des Onboardings auf den Start-
// Bildschirm laufen (Koordinaten für iPhone-Viewport 393x852). Ausgabe: eine JSON-Zeile.
const { chromium } = require('playwright');
const [,, url, label, cpu = '1', dpr = '2', secs = '12', extra = ''] = process.argv;
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--enable-precise-memory-info'] });
  const ctx = await browser.newContext({ viewport: { width: 393, height: 852 }, deviceScaleFactor: Number(dpr), isMobile: true, hasTouch: true, locale: 'de-DE' });
  const page = await ctx.newPage();
  const cdp = await ctx.newCDPSession(page);
  await cdp.send('Performance.enable');
  if (Number(cpu) > 1) await cdp.send('Emulation.setCPUThrottlingRate', { rate: Number(cpu) });
  await page.addInitScript(() => { window.addEventListener('flutter-first-frame', () => { window.__ffMs = performance.now(); }); });
  const t0 = Date.now();
  await page.goto(url + extra, { waitUntil: 'load', timeout: 120000 });
  const loadMs = Date.now() - t0;
  await page.waitForFunction(() => window.__ffMs, null, { timeout: 120000 });
  const ff = await page.evaluate(() => window.__ffMs);
  await page.waitForTimeout(9000);
  for (let i = 0; i < 4; i++) { await page.mouse.click(196, 806); await page.waitForTimeout(1200); }
  await page.waitForTimeout(5000);
  await page.mouse.click(242, 687); // Start (5 min Standard)
  await page.waitForTimeout(3500);
  const m0 = await cdp.send('Performance.getMetrics');
  const res = await page.evaluate((ms) => new Promise(r => { const ts = []; const t0 = performance.now(); function f(t) { ts.push(t); if (t - t0 < ms) requestAnimationFrame(f); else r(ts); } requestAnimationFrame(f); }), Number(secs) * 1000);
  const iv = []; for (let i = 1; i < res.length; i++) iv.push(res[i] - res[i - 1]);
  const s = [...iv].sort((a, b) => a - b); const q = p => s[Math.min(s.length - 1, Math.floor(p * s.length))];
  const m = await cdp.send('Performance.getMetrics'); const g = n => (m.metrics.find(x => x.name === n) || {}).value; const d = n => ((m.metrics.find(x => x.name === n) || {}).value - (m0.metrics.find(x => x.name === n) || {}).value);
  const winSec = (res[res.length - 1] - res[0]) / 1000;
  const nav = await page.evaluate(() => { const n = performance.getEntriesByType('navigation')[0]; const rs = performance.getEntriesByType('resource').filter(r => /webp|main\.dart\.js|\.wasm/.test(r.name)).map(r => ({ n: r.name.split('/').pop(), kb: Math.round((r.encodedBodySize || 0) / 1024), ms: Math.round(r.responseEnd - r.startTime) })); return { dcl: Math.round(n.domContentLoadedEventEnd), load: Math.round(n.loadEventEnd), rs }; });
  const out = { label, cpu: Number(cpu), dpr: Number(dpr), frames: iv.length, fps: +(1000 * iv.length / (res[res.length - 1] - res[0])).toFixed(1), p50: +q(.5).toFixed(1), p95: +q(.95).toFixed(1), p99: +q(.99).toFixed(1), max: +s[s.length - 1].toFixed(0), over33: iv.filter(x => x > 33.4).length, over50: iv.filter(x => x > 50).length, jsHeapMB: +(g('JSHeapUsedSize') / 1048576).toFixed(1), mainTaskMsPerSec: +(1000 * d('TaskDuration') / winSec).toFixed(0), scriptMsPerSec: +(1000 * d('ScriptDuration') / winSec).toFixed(0), scriptMsPerFrame: +(1000 * d('ScriptDuration') / iv.length).toFixed(2), mainTaskMsPerFrame: +(1000 * d('TaskDuration') / iv.length).toFixed(2), firstFrameMs: Math.round(ff), loadEventMs: nav.load, assets: nav.rs };
  console.log(JSON.stringify(out));
  await browser.close();
})();
